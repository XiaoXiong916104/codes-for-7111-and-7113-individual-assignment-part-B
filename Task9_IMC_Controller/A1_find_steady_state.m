%% CSTR Steady-State Finder
% Find the steady-state reactor temperature and concentration for a chosen
% jacket temperature Tc. The resulting values can be used as the initial
% conditions of the Integrator blocks in Simulink.

clear; clc;

%% Model parameters
q   = 100;          % m^3/s
V   = 100;          % m^3
rho = 1000;         % kg/m^3
Cp  = 0.239;        % J/(kg K)
dHr = -5e4;         % J/mol
UA  = 5e4;          % W/K
ER  = 8750;         % K
k0  = 6.379829e10;  % 1/s
CAf = 1.0;          % mol/m^3
Tf  = 350;          % K

%% Query point
Tc_query = 280;     % Change this value if needed

%% Solve steady state
k_fun       = @(T) k0 .* exp(-ER ./ T);
CAss_from_T = @(T) (q / V * CAf) ./ (q / V + k_fun(T));
residual    = @(T) (q / V) * (Tf - T) ...
                   + (-dHr) / (rho * Cp) * k_fun(T) .* CAss_from_T(T) ...
                   - UA / (V * rho * Cp) * (T - Tc_query);

T_scan = linspace(250, 500, 5000);
F_scan = residual(T_scan);
idx = find(F_scan(1:end-1) .* F_scan(2:end) <= 0, 1);

if isempty(idx)
    error('No steady-state root was found for Tc = %.1f K. Check the parameters.', Tc_query);
end

Tss  = fzero(residual, [T_scan(idx), T_scan(idx + 1)]);
CAss = CAss_from_T(Tss);

%% Report
fprintf('============================================================\n');
fprintf('Steady state for Tc = %.2f K\n', Tc_query);
fprintf('------------------------------------------------------------\n');
fprintf('  Tss  = %.6f K\n', Tss);
fprintf('  CAss = %.8f mol/m^3\n', CAss);
fprintf('============================================================\n\n');
fprintf('Use these Simulink Integrator initial conditions:\n');
fprintf('  T  Integrator IC  = %.4f\n', Tss);
fprintf('  CA Integrator IC  = %.6f\n', CAss);

%% Diagnostic plot
figure('Color', 'w');
plot(T_scan, F_scan, 'b-', 'LineWidth', 1.5); hold on;
yline(0, 'k--', 'LineWidth', 1.0);
plot(Tss, 0, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
xlabel('T (K)');
ylabel('Energy-balance residual');
title(sprintf('Steady-state root for Tc = %.1f K', Tc_query));
legend('f(T)', 'Zero line', sprintf('Tss = %.2f K', Tss), 'Location', 'best');
grid on;
