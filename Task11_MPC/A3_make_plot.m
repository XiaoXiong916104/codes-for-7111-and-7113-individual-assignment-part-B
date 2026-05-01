%% Task 11 final response plot
% Plot the latest Task 11 Simulink output from the MATLAB base workspace.
%
% Preferred latest signals:
%   Tc_out - coolant-temperature timeseries, K versus s
%   CA_out - reactor-concentration timeseries, kmol/m^3 versus s
%
% Fallbacks are included for older runs that stored signals in CA, out, or
% out_task11. This avoids accidentally plotting an old CA variable when the
% latest Simulink run saved the concentration as CA_out.

clc; close all;

[tTc, yTc] = local_get_latest_signal({'Tc_out'}, {'out', 'out_task11'});
[tCA, yCA] = local_get_latest_signal({'CA_out', 'CA'}, {'out', 'out_task11'});

mainColor = [0 0.447 0.741];   % deep blue
spColor   = [0.3 0.3 0.3];     % dark gray
eventColor = [0.85 0.1 0.1];   % red event markers

figure('Color','w','Position',[100 100 850 650])

subplot(2,1,1)
plot(tTc, yTc, 'LineWidth', 2, 'Color', mainColor)
local_add_event_lines(eventColor);
xlabel('Time (s)')
ylabel('T_c (K)')
title('Coolant Temperature')
grid on
xlim([0 max(tTc)])

subplot(2,1,2)
plot(tCA, yCA, 'LineWidth', 2, 'Color', mainColor); hold on
yline(0.5, '--', 'Setpoint', 'LineWidth', 1.2, 'Color', spColor)
local_add_event_lines(eventColor);
xlabel('Time (s)')
ylabel('C_A (kmol/m^3)')
title('Reactor Concentration')
grid on
xlim([0 max(tCA)])

saveas(gcf,'Task11_Tc_CA.png')
savefig(gcf,'Task11_Tc_CA.fig')

fprintf('Task 11 plot saved from the latest available Tc_out and CA_out signals.\n');

%% local functions
function [t, y] = local_get_latest_signal(signalNames, simOutNames)
    % First use direct To Workspace variables, which are normally updated
    % when the user presses Run in Simulink.
    for i = 1:numel(signalNames)
        signalName = signalNames{i};
        if evalin('base', sprintf('exist(''%s'', ''var'')', signalName))
            sig = evalin('base', signalName);
            [t, y] = local_unpack_signal(sig, signalName);
            return;
        end
    end

    % Then check SimulationOutput variables produced by sim(...).
    for j = 1:numel(simOutNames)
        simOutName = simOutNames{j};
        if ~evalin('base', sprintf('exist(''%s'', ''var'')', simOutName))
            continue;
        end

        simOut = evalin('base', simOutName);
        for i = 1:numel(signalNames)
            signalName = signalNames{i};
            if local_has_output_signal(simOut, signalName)
                sig = local_get_output_signal(simOut, signalName);
                [t, y] = local_unpack_signal(sig, [simOutName '.' signalName]);
                return;
            end
        end
    end

    error('Could not find any of these Task 11 signals: %s.', strjoin(signalNames, ', '));
end

function tf = local_has_output_signal(simOut, signalName)
    if isstruct(simOut)
        tf = isfield(simOut, signalName);
        return;
    end

    tf = isprop(simOut, signalName);
    if tf
        return;
    end

    try
        names = simOut.who;
        tf = any(strcmp(names, signalName));
    catch
        tf = false;
    end
end

function sig = local_get_output_signal(simOut, signalName)
    if isstruct(simOut) || isprop(simOut, signalName)
        sig = simOut.(signalName);
        return;
    end

    sig = simOut.get(signalName);
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

function local_add_event_lines(eventColor)
    xline(4,  ':', 'T_f + 10 K', ...
        'Color', eventColor, 'LineWidth', 1.1, ...
        'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
    xline(8,  ':', 'C_{A,sp} + 0.1', ...
        'Color', eventColor, 'LineWidth', 1.1, ...
        'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
    xline(12, ':', 'C_{Af} + 0.1', ...
        'Color', eventColor, 'LineWidth', 1.1, ...
        'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
end
