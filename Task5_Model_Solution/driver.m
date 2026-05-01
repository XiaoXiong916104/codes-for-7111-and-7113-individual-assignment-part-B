% driver_task5_nominal.m
% Task 5: solve the nonlinear CSTR model using nominal inputs and k0 = 5e10 1/s.
%
% Workflow:
%   1. Load constants and initial conditions from param_consts.m.
%   2. Integrate the nonlinear CSTR ODE model with ODE45.
%   3. Plot reactor temperature and concentration for the report.
%   4. Print final values as a quick numerical check.

clear; clc; close all;

% Load global parameters used by cstr_modelFunc.
run('param_consts.m');

% Tight tolerances are used so the Task 5 response can act as a benchmark
% for the later calibration and Simulink validation tasks.
opts = odeset('RelTol',1e-8,'AbsTol',1e-10);
[t, y] = ode45(@cstr_modelFunc, tspan, y0, opts);

% State vector unpacking: y(:,1) is T and y(:,2) is C_A.
T  = y(:,1);
CA = y(:,2);

% Export-quality MATLAB figure, not a scope screenshot.
figure('Color','w');
subplot(2,1,1);
plot(t, T, 'b-', 'LineWidth', 1.8);
xlabel('Time (s)');
ylabel('Temperature, T (K)');
title('Task 5: reactor temperature response');
grid on;

subplot(2,1,2);
plot(t, CA, 'r-', 'LineWidth', 1.8);
xlabel('Time (s)');
ylabel('Concentration, C_A (mol/m^3)');
title('Task 5: reactant concentration response');
grid on;

fprintf('Final temperature at t = %.2f s: %.6f K\n', t(end), T(end));
fprintf('Final concentration at t = %.2f s: %.6f mol/m^3\n', t(end), CA(end));
