% sensitivity_k0.m
% Task 6 sensitivity analysis around the calibrated value of k0.

clear; clc; close all;

thisFolder = fileparts(mfilename('fullpath'));
cd(thisFolder);

filename = 'data_calibration_validation.xlsx';
sheetName = 'Data for validation';
S = read_assignment_data(filename, sheetName);

k0_calibrated = 6.3e10;
if isfile('task6_calibration_results.mat')
    R = load('task6_calibration_results.mat', 'k0_calibrated');
    if isfield(R, 'k0_calibrated')
        k0_calibrated = R.k0_calibrated;
    end
end

k0_low = 0.9 * k0_calibrated;
k0_high = 1.1 * k0_calibrated;

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

[~, y_low] = ode45(@(t, y) Task_6_Calibrate_Model(t, y, k0_low, const), S.t, y0, optsODE);
[~, y_base] = ode45(@(t, y) Task_6_Calibrate_Model(t, y, k0_calibrated, const), S.t, y0, optsODE);
[~, y_high] = ode45(@(t, y) Task_6_Calibrate_Model(t, y, k0_high, const), S.t, y0, optsODE);

fig = figure('Color', 'w', 'Name', 'Task 6 Sensitivity to k0');
tiledlayout(2, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
plot(S.t, y_low(:, 1), 'b--', 'LineWidth', 1.5, 'DisplayName', 'k_0 - 10%'); hold on;
plot(S.t, y_base(:, 1), 'k-', 'LineWidth', 1.8, 'DisplayName', 'Calibrated k_0');
plot(S.t, y_high(:, 1), 'r--', 'LineWidth', 1.5, 'DisplayName', 'k_0 + 10%');
xlabel('Time (s)');
ylabel('Temperature, T (K)');
title('Sensitivity of temperature to k_0');
legend('Location', 'best');
grid on;

nexttile;
plot(S.t, y_low(:, 2), 'b--', 'LineWidth', 1.5, 'DisplayName', 'k_0 - 10%'); hold on;
plot(S.t, y_base(:, 2), 'k-', 'LineWidth', 1.8, 'DisplayName', 'Calibrated k_0');
plot(S.t, y_high(:, 2), 'r--', 'LineWidth', 1.5, 'DisplayName', 'k_0 + 10%');
xlabel('Time (s)');
ylabel('Concentration, C_A (mol/m^3)');
title('Sensitivity of concentration to k_0');
legend('Location', 'best');
grid on;

sgtitle('Task 6 sensitivity analysis around the calibrated k_0');
saveas(fig, 'task6_sensitivity_k0.png');
savefig(fig, 'task6_sensitivity_k0.fig');
