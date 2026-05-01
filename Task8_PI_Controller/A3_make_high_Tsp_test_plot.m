%% Task 8 high-temperature setpoint test
% This script tests the PI controller when the reactor-temperature setpoint
% is pushed into the 400-500 K range required by the assignment question.
%
% High-setpoint test markers used in the report:
%   0 s:  T_sp = 360 K
%   2 s:  T_sp = 380 K
%   4 s:  T_sp = 390 K
%   8 s:  T_sp = 400 K
%   12 s: T_sp = 450 K
%   16 s: T_sp = 500 K
%
% Plotted variables:
%   T   - reactor temperature, K
%   C_A - reactor concentration, mol/m^3
%   T_c - coolant/jacket temperature manipulated variable, K

clc; close all;

thisFolder = fileparts(mfilename('fullpath'));
oldFolder = pwd;
cleanupFolder = onCleanup(@() cd(oldFolder));
cd(thisFolder);

run('A1_Task8_param_consts.m');

mdl = 'closed_loop_PID';
load_system(mdl);

% Do not modify any block parameters here. The high-setpoint schedule should
% be set in the Simulink model before running this plotting script. This
% avoids hidden changes to the final submitted model.
out_high_Tsp = sim([mdl '.slx']);
assignin('base', 'out_high_Tsp', out_high_Tsp);

[t, T]   = local_get_signal(out_high_Tsp, 'PI_T');   % s, K
[~, CA]  = local_get_signal(out_high_Tsp, 'PI_CA');  % s, mol/m^3
[tTc,Tc] = local_get_signal(out_high_Tsp, 'PI_Tc');  % s, K

eventTimes = [0 2 4 8 12 16];              % setpoint-change times, s
eventTsp   = [360 380 390 400 450 500];    % corresponding T_sp values, K
eventColor = [0.85 0.1 0.1];               % red event markers

Tsp = eventTsp(1) * ones(size(t));
for i = 2:numel(eventTimes)
    Tsp(t >= eventTimes(i)) = eventTsp(i);
end

fig = figure('Color', 'w', 'Position', [100 100 900 900]);

subplot(3,1,1)
plot(t, T, 'b-', 'LineWidth', 1.8);
local_add_tsp_event_lines(eventTimes, eventTsp, eventColor);
xlabel('Time (s)');
ylabel('Temperature (K)');
title('Task 8 High Setpoint Test: Reactor Temperature');
grid on;

subplot(3,1,2)
plot(t, CA, 'LineWidth', 1.8);
local_add_tsp_event_lines(eventTimes, eventTsp, eventColor);
xlabel('Time (s)');
ylabel('C_A (mol/m^3)');
title('Task 8 High Setpoint Test: Reactor Concentration');
grid on;

subplot(3,1,3)
plot(tTc, Tc, 'LineWidth', 1.8);
local_add_tsp_event_lines(eventTimes, eventTsp, eventColor);
xlabel('Time (s)');
ylabel('T_c (K)');
title('Task 8 High Setpoint Test: Coolant Temperature');
grid on;

save('task8_high_Tsp_test_results.mat', 't', 'T', 'CA', 'tTc', 'Tc', 'Tsp', 'eventTimes', 'eventTsp');
saveas(fig, 'task8_high_Tsp_test.png');
savefig(fig, 'task8_high_Tsp_test.fig');

fprintf('Task 8 high-temperature setpoint test saved to task8_high_Tsp_test.png.\n');

%% local functions
function [t, y] = local_get_signal(simOut, signalName)
    sig = [];
    if isprop(simOut, signalName)
        sig = simOut.(signalName);
    else
        try
            sig = simOut.get(signalName);
        catch
        end
    end

    if isempty(sig) && evalin('base', sprintf('exist(''%s'', ''var'')', signalName))
        sig = evalin('base', signalName);
    end

    if isempty(sig)
        error('Could not find signal %s after simulation.', signalName);
    end

    if isa(sig, 'timeseries')
        t = sig.Time(:);
        y = sig.Data(:);
    elseif isstruct(sig)
        t = sig.time(:);
        y = sig.signals.values(:);
    else
        error('Unsupported signal format for %s.', signalName);
    end
end

function local_add_tsp_event_lines(eventTimes, eventTsp, eventColor)
    for i = 1:numel(eventTimes)
        xline(eventTimes(i), '--', sprintf('T_{sp} = %g K', eventTsp(i)), ...
            'Color', eventColor, ...
            'LineWidth', 1.0, ...
            'LabelOrientation', 'horizontal', ...
            'LabelVerticalAlignment', 'bottom');
    end
end
