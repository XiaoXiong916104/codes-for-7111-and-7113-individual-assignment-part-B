%% TASK 10 - Linearisation of the CSTR for MPC Design
% This script:
% 1) solves the nominal steady state
% 2) derives the linearised state-space model
% 3) computes A, B, C, D
% 4) calculates eigenvalues
% 5) simulates a small-signal linear response
% 6) scans Tc to identify the approximate instability region
% 7) saves the results for the MPC setup script

clear; clc; close all;

%% =========================================================
% 1. MODEL PARAMETERS
% =========================================================
q   = 100;        % volumetric flow rate, m^3/s
V   = 100;        % reactor volume, m^3
rho = 1000;       % density, kg/m^3
Cp  = 0.239;      % heat capacity, J/(kg K)
dHr = -5e4;       % heat of reaction, J/mol
UA  = 5e4;        % overall heat transfer coefficient, W/K
ER  = 8750;       % E/R, K
k0  =  6.379829e+10;       % pre-exponential factor, 1/s

% nominal input conditions
Tc_nom  = 270;    % jacket temperature, K
CAf_nom = 1.0;    % feed concentration, mol/m^3
Tf_nom  = 350;    % feed temperature, K

fprintf('============================================================\n');
fprintf('TASK 10 - LINEARISED STATE-SPACE MODEL FOR THE CSTR\n');
fprintf('============================================================\n\n');

%% =========================================================
% 2. DEFINE HELPER FUNCTIONS
% =========================================================
% Arrhenius rate constant
k_fun = @(T) k0 .* exp(-ER ./ T);

% Steady-state concentration from the steady-state mass balance
CAss_from_T = @(T, CAf) ((q/V) * CAf) ./ ((q/V) + k_fun(T));

% Steady-state energy balance residual
energy_ss_residual = @(T, Tc, CAf, Tf) ...
    (q/V) * (Tf - T) ...
    + ((-dHr) / (rho * Cp)) * k_fun(T) .* CAss_from_T(T, CAf) ...
    - (UA / (V * rho * Cp)) * (T - Tc);

%% =========================================================
% 3. SOLVE THE NOMINAL STEADY STATE
% =========================================================
T_grid = linspace(250, 450, 4000);
F_grid = energy_ss_residual(T_grid, Tc_nom, CAf_nom, Tf_nom);

sign_change_idx = find(F_grid(1:end-1) .* F_grid(2:end) <= 0);

if isempty(sign_change_idx)
    error('No steady-state root was found in the selected search interval.');
end

idx0 = sign_change_idx(1);
T_lo = T_grid(idx0);
T_hi = T_grid(idx0 + 1);

Tss = fzero(@(T) energy_ss_residual(T, Tc_nom, CAf_nom, Tf_nom), [T_lo, T_hi]);
CAss = CAss_from_T(Tss, CAf_nom);

fprintf('Nominal steady-state operating point:\n');
fprintf('Tss  = %.6f K\n', Tss);
fprintf('CAss = %.6f mol/m^3\n\n', CAss);

%% =========================================================
% 4. KINETIC QUANTITIES AT THE NOMINAL STEADY STATE
% =========================================================
kss  = k_fun(Tss);
dkdT = kss * ER / Tss^2;

fprintf('Steady-state kinetic quantities:\n');
fprintf('kss         = %.8f 1/s\n', kss);
fprintf('(dk/dT)_ss  = %.8e 1/(s.K)\n\n', dkdT);

%% =========================================================
% 5. JACOBIAN MATRICES A, B, C, D
% =========================================================
A11 = -(q / V) - UA / (V * rho * Cp) + ((-dHr) / (rho * Cp)) * CAss * dkdT;
A12 = ((-dHr) / (rho * Cp)) * kss;
A21 = -CAss * dkdT;
A22 = -(q / V) - kss;

A = [A11, A12;
     A21, A22];

B = [UA / (V * rho * Cp),   0,     q / V;
     0,                     q / V, 0];

C = eye(2);
D = zeros(2,3);

fprintf('A = \n'); disp(A);
fprintf('B = \n'); disp(B);
fprintf('C = \n'); disp(C);
fprintf('D = \n'); disp(D);

%% =========================================================
% 6. EIGENVALUES AND LOCAL STABILITY
% =========================================================
eigA = eig(A);

fprintf('Nominal eigenvalues:\n');
disp(eigA);

if all(real(eigA) < 0)
    fprintf('Conclusion: the nominal operating point is locally asymptotically stable.\n\n');
elseif any(real(eigA) > 0)
    fprintf('Conclusion: the nominal operating point is unstable.\n\n');
else
    fprintf('Conclusion: the nominal operating point is marginally stable.\n\n');
end

%% =========================================================
% 7. BUILD THE STATE-SPACE MODEL
% =========================================================
sys = ss(A, B, C, D);
fprintf('State-space object created successfully.\n\n');

%% =========================================================
% 8. SMALL-SIGNAL LINEAR STEP RESPONSE
% =========================================================
t = linspace(0, 10, 500)';
du = zeros(length(t), 3);
du(:,1) = 1.0;    % +1 K step in Delta Tc

[y_lin, t_lin, x_lin] = lsim(sys, du, t);

fprintf('Final linearised outputs for a +1 K step in Delta Tc:\n');
fprintf('Delta T(end)  = %.6f K\n', y_lin(end,1));
fprintf('Delta CA(end) = %.6e mol/m^3\n\n', y_lin(end,2));

figure;
subplot(2,1,1)
plot(t_lin, y_lin(:,1), 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('\Delta T (K)');
title('Linearised temperature response to a +1 K step in \Delta T_c');

subplot(2,1,2)
plot(t_lin, y_lin(:,2), 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('\Delta C_A (mol/m^3)');
title('Linearised concentration response to a +1 K step in \Delta T_c');

%% =========================================================
% 9. STABILITY SCAN VERSUS JACKET TEMPERATURE
% =========================================================
Tc_vec = 240:2:360;

maxRealEig = nan(size(Tc_vec));
Tss_vec    = nan(size(Tc_vec));
CAss_vec   = nan(size(Tc_vec));

for i = 1:length(Tc_vec)
    Tc_i = Tc_vec(i);

    T_grid_i = linspace(250, 500, 5000);
    F_grid_i = energy_ss_residual(T_grid_i, Tc_i, CAf_nom, Tf_nom);

    sign_idx_i = find(F_grid_i(1:end-1) .* F_grid_i(2:end) <= 0);

    if isempty(sign_idx_i)
        continue;
    end

    candidate_roots = nan(size(sign_idx_i));

    for j = 1:length(sign_idx_i)
        a = T_grid_i(sign_idx_i(j));
        b = T_grid_i(sign_idx_i(j) + 1);

        try
            candidate_roots(j) = fzero(@(T) energy_ss_residual(T, Tc_i, CAf_nom, Tf_nom), [a, b]);
        catch
            candidate_roots(j) = NaN;
        end
    end

    candidate_roots = candidate_roots(isfinite(candidate_roots));

    if isempty(candidate_roots)
        continue;
    end

    % choose the smallest physically meaningful root
    Tss_i  = min(candidate_roots);
    CAss_i = CAss_from_T(Tss_i, CAf_nom);

    if ~isreal(Tss_i) || ~isreal(CAss_i) || Tss_i <= 0 || CAss_i <= 0
        continue;
    end

    Tss_vec(i)  = Tss_i;
    CAss_vec(i) = CAss_i;

    kss_i  = k_fun(Tss_i);
    dkdT_i = kss_i * ER / Tss_i^2;

    A11_i = -(q / V) - UA / (V * rho * Cp) + ((-dHr) / (rho * Cp)) * CAss_i * dkdT_i;
    A12_i = ((-dHr) / (rho * Cp)) * kss_i;
    A21_i = -CAss_i * dkdT_i;
    A22_i = -(q / V) - kss_i;

    A_i = [A11_i, A12_i;
           A21_i, A22_i];

    eig_i = eig(A_i);
    maxRealEig(i) = max(real(eig_i));
end

valid_idx = isfinite(maxRealEig) & isfinite(Tss_vec) & isfinite(CAss_vec);

fprintf('Valid scan points = %d / %d\n', sum(valid_idx), length(Tc_vec));

%% =========================================================
% 10. PLOT THE STABILITY BOUNDARY
% =========================================================
figure;
plot(Tc_vec(valid_idx), maxRealEig(valid_idx), 'o-', 'LineWidth', 1.5, 'MarkerSize', 5);
hold on;
yline(0, '--', 'LineWidth', 1.2);
grid on;
xlabel('Nominal jacket temperature T_c (K)');
ylabel('Maximum real part of eigenvalues');
title('Local stability of the linearised state-space model versus T_c');

idx_unstable = find(valid_idx & (maxRealEig > 0), 1, 'first');

if ~isempty(idx_unstable)
    Tc_crit = Tc_vec(idx_unstable);
    xline(Tc_crit, '--', sprintf('Approx. instability near T_c = %.1f K', Tc_crit), ...
        'LabelVerticalAlignment', 'bottom');
    fprintf('Approximate instability begins near Tc = %.2f K\n\n', Tc_crit);
else
    Tc_crit = NaN;
    fprintf('No instability was detected in the scanned Tc range.\n\n');
end

%% =========================================================
% 11. PLOT THE STEADY-STATE OPERATING POINT
% =========================================================
figure;

subplot(2,1,1)
plot(Tc_vec(valid_idx), Tss_vec(valid_idx), 'LineWidth', 1.5);
grid on;
xlabel('Nominal jacket temperature T_c (K)');
ylabel('T_{ss} (K)');
title('Steady-state reactor temperature versus T_c');

subplot(2,1,2)
plot(Tc_vec(valid_idx), CAss_vec(valid_idx), 'LineWidth', 1.5);
grid on;
xlabel('Nominal jacket temperature T_c (K)');
ylabel('C_{A,ss} (mol/m^3)');
title('Steady-state concentration versus T_c');

%% =========================================================
% 12. SAVE RESULTS FOR TASK 10 MPC SETUP
% =========================================================
save('task10_linearisation_results.mat', ...
    'A', 'B', 'C', 'D', ...
    'sys', ...
    'Tss', 'CAss', 'eigA', ...
    'Tc_nom', 'CAf_nom', 'Tf_nom', ...
    'Tc_vec', 'maxRealEig', 'Tss_vec', 'CAss_vec', ...
    'Tc_crit');

fprintf('Results saved to task10_linearisation_results.mat\n\n');

%% =========================================================
% 13. SUMMARY
% =========================================================
fprintf('============================================================\n');
fprintf('SUMMARY\n');
fprintf('============================================================\n');
fprintf('Nominal Tss  = %.6f K\n', Tss);
fprintf('Nominal CAss = %.6f mol/m^3\n', CAss);
fprintf('Nominal eigenvalues:\n');
disp(eigA);

if ~isnan(Tc_crit)
    fprintf('Approximate instability near Tc = %.2f K\n', Tc_crit);
else
    fprintf('No instability detected in the scanned Tc range.\n');
end