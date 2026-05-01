% calibrate.m
% Task 6 calibration workflow.
% Estimate k0 from the calibration dataset, save the fitted result, and
% export calibration plots for the report.

clear; clc; close all;

% Use the script folder as the working directory so all data, plots and
% saved results are written beside the Task 6 files.
thisFolder = fileparts(mfilename('fullpath'));
cd(thisFolder);

% Read the calibration sheet and its associated operating conditions.
filename = 'data_calibration_validation.xlsx';
sheetName = 'Data for Calibration';
S = read_assignment_data(filename, sheetName);

% Store constants in a structure so the optimisation function is explicit
% about which plant parameters it uses.
const = struct( ...
    'q', 100, ...
    'V', 100, ...
    'rho', 1000, ...
    'Cp', 0.239, ...
    'DeltaHr', -5e4, ...
    'UA', 5e4, ...
    'E_over_R', 8750, ...
    'Tf', S.Tf, ...
    'CAf', S.CAf, ...
    'Tc', S.Tc, ...
    'T0', S.T0, ...
    'CA0', S.CA0);

tdata = S.t;
ydata = [S.T, S.CA];
y0 = [S.T0; S.CA0];
optsODE = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);

% Fit in log10-space to keep k0 positive and improve numerical conditioning.
p0 = log10(6.3e10);
lb = 7;
ub = 13;
options = optimoptions('lsqnonlin', ...
    'Display', 'iter', ...
    'FunctionTolerance', 1e-10, ...
    'StepTolerance', 1e-10);

% Minimise normalised residuals between measured and simulated T and C_A.
[p_fit, resnorm, residual, exitflag, output, ~, jacobian] = lsqnonlin( ...
    @(p) Task_6_Error_Calc(p, tdata, ydata, const), ...
    p0, lb, ub, options);

k0_calibrated = 10.^p_fit;
ci_p = nlparci(p_fit, residual, 'jacobian', jacobian);
ci_k0 = 10.^ci_p;

% Re-simulate with the fitted value so calibration metrics and plots use the
% final model, not the optimiser residual vector directly.
[~, y_fit] = ode45(@(t, y) Task_6_Calibrate_Model(t, y, k0_calibrated, const), ...
    tdata, y0, optsODE);

T_fit = y_fit(:, 1);
CA_fit = y_fit(:, 2);

metrics_T = calc_error_metrics(S.T, T_fit);
metrics_CA = calc_error_metrics(S.CA, CA_fit);

% Print enough information to reproduce the calibration table in the report.
fprintf('\n===== Task 6 calibration result =====\n');
fprintf('Estimated k0        = %.6e 1/s\n', k0_calibrated);
fprintf('95%% CI for k0       = [%.6e, %.6e]\n', ci_k0(1, 1), ci_k0(1, 2));
fprintf('Residual norm       = %.6e\n', resnorm);
fprintf('Iterations          = %d\n', output.iterations);
fprintf('Function evaluations= %d\n', output.funcCount);
fprintf('Exit flag           = %d\n', exitflag);
fprintf('\nCalibration metrics:\n');
fprintf('  Temperature   RMSE = %.6f K,   MAE = %.6f, R^2 = %.6f\n', ...
    metrics_T.RMSE, metrics_T.MAE, metrics_T.R2);
fprintf('  Concentration RMSE = %.6f mol/m^3, MAE = %.6f, R^2 = %.6f\n', ...
    metrics_CA.RMSE, metrics_CA.MAE, metrics_CA.R2);

resultTable = table(k0_calibrated, ci_k0(1, 1), ci_k0(1, 2), ...
    metrics_T.RMSE, metrics_T.MAE, metrics_T.R2, ...
    metrics_CA.RMSE, metrics_CA.MAE, metrics_CA.R2, ...
    'VariableNames', {'k0_calibrated', 'k0_CI_low', 'k0_CI_high', ...
    'RMSE_T', 'MAE_T', 'R2_T', 'RMSE_CA', 'MAE_CA', 'R2_CA'});

% Save numerical results for validate.m and sensitivity_k0.m.
save('task6_calibration_results.mat', 'k0_calibrated', 'ci_k0', 'const', ...
    'resultTable', 'T_fit', 'CA_fit');
writetable(resultTable, 'task6_calibration_results.xlsx');

fig1 = figure('Color', 'w', 'Name', 'Task 6 Calibration');
tiledlayout(2, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
plot(S.t, S.T, 'ko', 'MarkerSize', 4, 'DisplayName', 'Experimental'); hold on;
plot(S.t, T_fit, '-', 'Color', [0 0.447 0.741], 'LineWidth', 1.8, ...
    'DisplayName', 'Calibrated model');
xlabel('Time (s)');
ylabel('Temperature, T (K)');
title('Calibration dataset: temperature');
legend('Location', 'best');
grid on;

nexttile;
plot(S.t, S.CA, 'ko', 'MarkerSize', 4, 'DisplayName', 'Experimental'); hold on;
plot(S.t, CA_fit, '-', 'Color', [0.85 0.325 0.098], 'LineWidth', 1.8, ...
    'DisplayName', 'Calibrated model');
xlabel('Time (s)');
ylabel('Concentration, C_A (mol/m^3)');
title('Calibration dataset: concentration');
legend('Location', 'best');
grid on;

saveas(fig1, 'task6_calibration_fit.png');
savefig(fig1, 'task6_calibration_fit.fig');

% Residual plots are saved as a diagnostic check on systematic model error.
fig2 = figure('Color', 'w', 'Name', 'Task 6 Calibration Residuals');
tiledlayout(2, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
plot(S.t, S.T - T_fit, 'o-', 'Color', [0.49 0.18 0.56], ...
    'LineWidth', 1.3, 'MarkerSize', 4);
yline(0, 'k--', 'LineWidth', 1.0);
xlabel('Time (s)');
ylabel('Residual in T (K)');
title('Calibration residuals: temperature');
grid on;

nexttile;
plot(S.t, S.CA - CA_fit, 'o-', 'Color', [0.85 0.33 0.10], ...
    'LineWidth', 1.3, 'MarkerSize', 4);
yline(0, 'k--', 'LineWidth', 1.0);
xlabel('Time (s)');
ylabel('Residual in C_A (mol/m^3)');
title('Calibration residuals: concentration');
grid on;

saveas(fig2, 'task6_calibration_residuals.png');
savefig(fig2, 'task6_calibration_residuals.fig');
