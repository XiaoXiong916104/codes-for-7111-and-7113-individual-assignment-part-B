%% Task 10 - Sweep coolant temperature and calculate eigenvalues
% This script supports the report statement that increasing coolant
% temperature T_c can move the CSTR operating point into an open-loop
% unstable region.
%
% For each T_c value:
%   1. Solve the nonlinear steady-state equations.
%   2. Build the local continuous-time Jacobian matrix A.
%   3. Calculate the eigenvalues of A.
%   4. Plot the dominant real eigenvalue versus T_c.
%
% Units:
%   T, T_c, T_f  - K
%   C_A, C_Af    - mol/m^3
%   eigenvalues  - 1/s

clear; clc; close all;

%% Model parameters
q   = 100;          % volumetric flow rate, m^3/s
V   = 100;          % reactor volume, m^3
rho = 1000;         % density, kg/m^3
Cp  = 0.239;        % heat capacity, J/(kg K)
dHr = -5e4;         % heat of reaction, J/mol
UA  = 5e4;          % overall heat-transfer coefficient times area, W/K
ER  = 8750;         % activation-energy ratio E/R, K
k0  = 6.379829e10;  % pre-exponential factor, 1/s

CAf = 1.0;          % feed concentration, mol/m^3
Tf  = 350.0;        % feed temperature, K

%% Sweep settings
Tc_vec = 240:2:380;             % coolant temperature scan, K
T_search_grid = linspace(240, 550, 8000);

n = numel(Tc_vec);
Tss_vec = nan(n, 1);
CAss_vec = nan(n, 1);
eig1_vec = nan(n, 1);
eig2_vec = nan(n, 1);
dominantEig_vec = nan(n, 1);

%% Helper functions for the nonlinear model
k_fun = @(T) k0 .* exp(-ER ./ T);
CAss_from_T = @(T) ((q/V) * CAf) ./ ((q/V) + k_fun(T));
energy_residual = @(T, Tc) ...
    (q/V) * (Tf - T) ...
    + ((-dHr) / (rho * Cp)) * k_fun(T) .* CAss_from_T(T) ...
    - (UA / (V * rho * Cp)) * (T - Tc);

%% Sweep T_c and calculate local eigenvalues
previousTss = NaN;

for i = 1:n
    Tc = Tc_vec(i);
    F = energy_residual(T_search_grid, Tc);
    rootIdx = find(F(1:end-1) .* F(2:end) <= 0);

    roots_i = [];
    for j = 1:numel(rootIdx)
        a = T_search_grid(rootIdx(j));
        b = T_search_grid(rootIdx(j) + 1);

        try
            roots_i(end+1, 1) = fzero(@(T) energy_residual(T, Tc), [a, b]); %#ok<SAGROW>
        catch
            % Skip failed root bracket.
        end
    end

    roots_i = unique(round(roots_i, 8));
    roots_i = roots_i(isfinite(roots_i) & roots_i > 0);
    if isempty(roots_i)
        continue;
    end

    % Continue along the same branch when possible. At the first scan point,
    % use the lowest-temperature physically meaningful steady state.
    if isnan(previousTss)
        Tss = min(roots_i);
    else
        [~, nearestIdx] = min(abs(roots_i - previousTss));
        Tss = roots_i(nearestIdx);
    end
    previousTss = Tss;

    CAss = CAss_from_T(Tss);
    kss = k_fun(Tss);
    dkdT = kss * ER / Tss^2;

    A11 = -(q / V) - UA / (V * rho * Cp) + ((-dHr) / (rho * Cp)) * CAss * dkdT;
    A12 = ((-dHr) / (rho * Cp)) * kss;
    A21 = -CAss * dkdT;
    A22 = -(q / V) - kss;
    A = [A11 A12; A21 A22];

    eigA = eig(A);

    Tss_vec(i) = Tss;
    CAss_vec(i) = CAss;
    eig1_vec(i) = eigA(1);
    eig2_vec(i) = eigA(2);
    dominantEig_vec(i) = max(real(eigA));
end

valid = isfinite(dominantEig_vec);
unstable = dominantEig_vec > 0;

if any(valid & unstable)
    firstUnstableIdx = find(valid & unstable, 1, 'first');
    Tc_crit = Tc_vec(firstUnstableIdx);
else
    Tc_crit = NaN;
end

%% Save numeric results
results = table( ...
    Tc_vec(:), Tss_vec, CAss_vec, eig1_vec, eig2_vec, dominantEig_vec, unstable, ...
    'VariableNames', {'Tc_K', 'Tss_K', 'CAss_mol_m3', ...
    'eig1_1_s', 'eig2_1_s', 'dominantEig_1_s', 'isUnstable'});

save('task10_Tc_eigenvalue_sweep.mat', ...
    'results', 'Tc_vec', 'Tss_vec', 'CAss_vec', ...
    'eig1_vec', 'eig2_vec', 'dominantEig_vec', 'Tc_crit');
writetable(results, 'task10_Tc_eigenvalue_sweep.xlsx');

%% Plot dominant eigenvalue and steady state
fig = figure('Color', 'w', 'Position', [100 100 900 700]);

subplot(2,1,1)
plot(Tc_vec(valid), dominantEig_vec(valid), 'o-', 'LineWidth', 1.5);
hold on;
yline(0, 'k--', 'LineWidth', 1.1);
if ~isnan(Tc_crit)
    xline(Tc_crit, 'r--', sprintf('unstable near T_c = %.0f K', Tc_crit), ...
        'LabelVerticalAlignment', 'bottom');
end
grid on;
xlabel('Coolant temperature, T_c (K)');
ylabel('Dominant eigenvalue real part (1/s)');
title('Task 10: Local Stability Versus Coolant Temperature');

subplot(2,1,2)
plot(Tc_vec(valid), Tss_vec(valid), 'LineWidth', 1.5);
grid on;
xlabel('Coolant temperature, T_c (K)');
ylabel('Steady-state reactor temperature, T_{ss} (K)');
title('Steady-State Reactor Temperature Along the Scanned Branch');

saveas(fig, 'task10_Tc_eigenvalue_sweep.png');
savefig(fig, 'task10_Tc_eigenvalue_sweep.fig');

fprintf('Task 10 T_c eigenvalue sweep complete.\n');
fprintf('Valid scan points: %d / %d\n', sum(valid), n);
if ~isnan(Tc_crit)
    fprintf('Dominant eigenvalue first becomes positive near T_c = %.2f K.\n', Tc_crit);
else
    fprintf('No positive dominant eigenvalue found in the scanned T_c range.\n');
end
fprintf('Results saved to task10_Tc_eigenvalue_sweep.xlsx and task10_Tc_eigenvalue_sweep.png.\n');
