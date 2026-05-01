%% Task 7 - Simulink versus Task 5 MATLAB model comparison
% This script compares the Task 7 Simulink open-loop response with the
% Task 5 MATLAB ODE model under the same step-test inputs:
%   C_Af + 0.1 mol/m^3 at t = 2 s
%   T_f  + 10 K       at t = 4 s
%
% Plotted variables:
%   T   - reactor temperature, K
%   C_A - reactor concentration, mol/m^3

clear; clc; close all;

thisFolder = fileparts(mfilename('fullpath'));
oldFolder = pwd;
cleanupObj = onCleanup(@() cd(oldFolder));
cd(thisFolder);

%% MATLAB ODE reference using the Task 5 model equations
run('param_consts.m');

opts = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);
[t_ref, y_ref] = ode45(@cstr_modelFunc_task5_steps, [0 10], y0, opts);

T_ref  = y_ref(:, 1);   % K
CA_ref = y_ref(:, 2);   % mol/m^3

%% Simulink response
% If the user has already run open_loop.slx, use the latest T_out/CA_out in
% the base workspace. Otherwise run the model here and read the outputs.
if evalin('base', 'exist(''T_out'', ''var'')') && evalin('base', 'exist(''CA_out'', ''var'')')
    T_sig  = evalin('base', 'T_out');
    CA_sig = evalin('base', 'CA_out');
else
    out_sim = sim('open_loop.slx');
    assignin('base', 'out_task7_open_loop', out_sim);

    T_sig  = local_get_signal(out_sim, 'T_out');
    CA_sig = local_get_signal(out_sim, 'CA_out');

    assignin('base', 'T_out', T_sig);
    assignin('base', 'CA_out', CA_sig);
end

[t_sim_T, T_sim]   = local_unpack_signal(T_sig, 'T_out');
[t_sim_CA, CA_sim] = local_unpack_signal(CA_sig, 'CA_out');

%% Comparison figure
fig = figure('Color', 'w', 'Position', [100 100 900 650]);

subplot(2,1,1)
plot(t_ref, T_ref, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Task 5 MATLAB ODE'); hold on;
plot(t_sim_T, T_sim, 'b-', 'LineWidth', 1.8, 'DisplayName', 'Task 7 Simulink');
xline(2, ':', 'C_{Af} + 0.1', 'Color', [0.5 0.5 0.5], ...
    'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
xline(4, ':', 'T_f + 10 K', 'Color', [0.5 0.5 0.5], ...
    'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
xlabel('Time (s)');
ylabel('Temperature, T (K)');
title('Task 7 Validation: Temperature');
legend('Location', 'best');
grid on;

subplot(2,1,2)
plot(t_ref, CA_ref, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Task 5 MATLAB ODE'); hold on;
plot(t_sim_CA, CA_sim, 'r-', 'LineWidth', 1.8, 'DisplayName', 'Task 7 Simulink');
xline(2, ':', 'C_{Af} + 0.1', 'Color', [0.5 0.5 0.5], ...
    'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
xline(4, ':', 'T_f + 10 K', 'Color', [0.5 0.5 0.5], ...
    'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
xlabel('Time (s)');
ylabel('Concentration, C_A (mol/m^3)');
title('Task 7 Validation: Concentration');
legend('Location', 'best');
grid on;

saveas(fig, 'task7_simulink_vs_task5.png');
savefig(fig, 'task7_simulink_vs_task5.fig');

fprintf('Task 7 comparison figure saved to task7_simulink_vs_task5.png.\n');

%% local functions
function sig = local_get_signal(simOut, signalName)
    if isprop(simOut, signalName)
        sig = simOut.(signalName);
        return;
    end

    try
        sig = simOut.get(signalName);
        return;
    catch
    end

    if evalin('base', sprintf('exist(''%s'', ''var'')', signalName))
        sig = evalin('base', signalName);
        return;
    end

    error('Could not find Simulink output signal %s.', signalName);
end

function [t, y] = local_unpack_signal(sig, sigName)
    if isa(sig, 'timeseries')
        t = sig.Time(:);
        y = sig.Data(:);
    elseif isstruct(sig)
        t = sig.time(:);
        y = sig.signals.values(:);
    else
        error('Unsupported signal format for %s.', sigName);
    end
end
