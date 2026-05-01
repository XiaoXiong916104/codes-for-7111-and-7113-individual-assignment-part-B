% validate.m
% Task 6 validation workflow.
% Compare the default model with the calibrated model using the independent
% validation dataset.

clear; clc; close all;

% Use local paths so the script can be run from any MATLAB current folder.
thisFolder = fileparts(mfilename('fullpath'));
cd(thisFolder);
addpath(fullfile(thisFolder, '..', 'Common'));

% Read the independent validation dataset.
filename = 'data_calibration_validation.xlsx';
sheetName = 'Data for validation';
S = read_assignment_data(filename, sheetName);

% Compare the default kinetic parameter with the calibrated value. If the
% calibration result file exists, use that saved fitted value.
k0_default = 5.0e10;
k0_calibrated = 6.3e10;
if isfile('task6_calibration_results.mat')
    R = load('task6_calibration_results.mat', 'k0_calibrated');
    if isfield(R, 'k0_calibrated')
        k0_calibrated = R.k0_calibrated;
    end
end

% Constants are kept identical between the default and calibrated cases.
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

y0 = [S.T0; S.CA0];
optsODE = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);

% Run both model variants on the same validation time vector.
[~, y_default] = ode45(@(t, y) Task_6_Calibrate_Model(t, y, k0_default, const), ...
    S.t, y0, optsODE);
[~, y_calib] = ode45(@(t, y) Task_6_Calibrate_Model(t, y, k0_calibrated, const), ...
    S.t, y0, optsODE);

T_default = y_default(:, 1);
CA_default = y_default(:, 2);
T_calib = y_calib(:, 1);
CA_calib = y_calib(:, 2);

metrics_T_default = calc_error_metrics(S.T, T_default);
metrics_CA_default = calc_error_metrics(S.CA, CA_default);
metrics_T_calib = calc_error_metrics(S.T, T_calib);
metrics_CA_calib = calc_error_metrics(S.CA, CA_calib);

% Print validation statistics used in the report table.
fprintf('\n===== Task 6 validation metrics =====\n');
fprintf('Default k0     = %.6e 1/s\n', k0_default);
fprintf('Calibrated k0  = %.6e 1/s\n\n', k0_calibrated);
fprintf('Default model:\n');
fprintf('  T  RMSE = %.6f, MAE = %.6f, R^2 = %.6f\n', ...
    metrics_T_default.RMSE, metrics_T_default.MAE, metrics_T_default.R2);
fprintf('  CA RMSE = %.6f, MAE = %.6f, R^2 = %.6f\n\n', ...
    metrics_CA_default.RMSE, metrics_CA_default.MAE, metrics_CA_default.R2);
fprintf('Calibrated model:\n');
fprintf('  T  RMSE = %.6f, MAE = %.6f, R^2 = %.6f\n', ...
    metrics_T_calib.RMSE, metrics_T_calib.MAE, metrics_T_calib.R2);
fprintf('  CA RMSE = %.6f, MAE = %.6f, R^2 = %.6f\n', ...
    metrics_CA_calib.RMSE, metrics_CA_calib.MAE, metrics_CA_calib.R2);

summaryTable = table( ...
    ["Default"; "Calibrated"], ...
    [metrics_T_default.RMSE; metrics_T_calib.RMSE], ...
    [metrics_T_default.R2; metrics_T_calib.R2], ...
    [metrics_CA_default.RMSE; metrics_CA_calib.RMSE], ...
    [metrics_CA_default.R2; metrics_CA_calib.R2], ...
    'VariableNames', {'Model', 'RMSE_T', 'R2_T', 'RMSE_CA', 'R2_CA'});
writetable(summaryTable, 'task6_validation_results.xlsx');

% Plot data and both model predictions on the same axes for direct comparison.
fig = figure('Color', 'w', 'Name', 'Task 6 Validation');
tiledlayout(2, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
plot(S.t, S.T, 'ko', 'MarkerSize', 4, 'DisplayName', 'Experimental'); hold on;
plot(S.t, T_default, '--', 'Color', [0 0.447 0.741], 'LineWidth', 1.5, ...
    'DisplayName', 'Default k_0');
plot(S.t, T_calib, '-', 'Color', [0.85 0.325 0.098], 'LineWidth', 1.7, ...
    'DisplayName', 'Calibrated k_0');
xlabel('Time (s)');
ylabel('Temperature, T (K)');
title('Validation dataset: temperature');
legend('Location', 'best');
grid on;

nexttile;
plot(S.t, S.CA, 'ko', 'MarkerSize', 4, 'DisplayName', 'Experimental'); hold on;
plot(S.t, CA_default, '--', 'Color', [0 0.447 0.741], 'LineWidth', 1.5, ...
    'DisplayName', 'Default k_0');
plot(S.t, CA_calib, '-', 'Color', [0.85 0.325 0.098], 'LineWidth', 1.7, ...
    'DisplayName', 'Calibrated k_0');
xlabel('Time (s)');
ylabel('Concentration, C_A (mol/m^3)');
title('Validation dataset: concentration');
legend('Location', 'best');
grid on;

saveas(fig, 'validation_comparison.png');
savefig(fig, 'validation_comparison.fig');
