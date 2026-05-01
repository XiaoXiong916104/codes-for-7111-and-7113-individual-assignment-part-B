%% Task 8 - Export PI_T oscillation plot
% This script exports a focused plot of the reactor temperature response
% PI_T. It is useful for showing oscillatory behaviour in the PI-controlled
% closed-loop response.
%
% Preferred data source:
%   PI_T - reactor temperature timeseries, K versus s
%
% Fallback data sources:
%   out.PI_T
%   out_high_Tsp.PI_T
%   task8_high_Tsp_test_results.mat

clc; close all;

thisFolder = fileparts(mfilename('fullpath'));
oldFolder = pwd;
cleanupObj = onCleanup(@() cd(oldFolder));
cd(thisFolder);

[t, T] = local_get_PI_T();

% Detect local turning points without requiring extra toolboxes.
turnIdx = local_turning_points(T);

fig = figure('Color', 'w', 'Position', [100 100 900 420]);
plot(t, T, 'b-', 'LineWidth', 1.8); hold on;
if ~isempty(turnIdx)
    plot(t(turnIdx), T(turnIdx), 'ro', 'MarkerSize', 4, ...
        'LineWidth', 1.0, 'DisplayName', 'Turning points');
end

grid on;
xlabel('Time (s)');
ylabel('Reactor Temperature, T (K)');
title('Task 8 PI Temperature Oscillation');
legend('PI_T', 'Turning points', 'Location', 'best');
xlim([min(t) max(t)]);

saveas(fig, 'task8_PI_T_oscillation.png');
savefig(fig, 'task8_PI_T_oscillation.fig');
save('task8_PI_T_oscillation_data.mat', 't', 'T', 'turnIdx');

fprintf('PI_T oscillation plot saved to task8_PI_T_oscillation.png.\n');

%% local functions
function [t, T] = local_get_PI_T()
    if evalin('base', 'exist(''PI_T'', ''var'')')
        sig = evalin('base', 'PI_T');
        [t, T] = local_unpack_signal(sig, 'PI_T');
        return;
    end

    if evalin('base', 'exist(''out'', ''var'')')
        outObj = evalin('base', 'out');
        if local_has_signal(outObj, 'PI_T')
            sig = local_get_signal(outObj, 'PI_T');
            [t, T] = local_unpack_signal(sig, 'out.PI_T');
            return;
        end
    end

    if evalin('base', 'exist(''out_high_Tsp'', ''var'')')
        outObj = evalin('base', 'out_high_Tsp');
        if local_has_signal(outObj, 'PI_T')
            sig = local_get_signal(outObj, 'PI_T');
            [t, T] = local_unpack_signal(sig, 'out_high_Tsp.PI_T');
            return;
        end
    end

    if exist('task8_high_Tsp_test_results.mat', 'file') == 2
        S = load('task8_high_Tsp_test_results.mat', 't', 'T');
        t = S.t(:);
        T = S.T(:);
        return;
    end

    error('Could not find PI_T. Run the Task 8 Simulink model or A3_make_high_Tsp_test_plot first.');
end

function tf = local_has_signal(outObj, signalName)
    if isstruct(outObj)
        tf = isfield(outObj, signalName);
        return;
    end

    tf = isprop(outObj, signalName);
    if tf
        return;
    end

    try
        names = outObj.who;
        tf = any(strcmp(names, signalName));
    catch
        tf = false;
    end
end

function sig = local_get_signal(outObj, signalName)
    if isstruct(outObj) || isprop(outObj, signalName)
        sig = outObj.(signalName);
        return;
    end

    sig = outObj.get(signalName);
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

function idx = local_turning_points(y)
    y = y(:);
    dy = diff(y);
    if isempty(dy)
        idx = [];
        return;
    end

    % Remove tiny numerical jitter before checking sign changes.
    tol = max(1e-8, 1e-6 * range(y));
    dy(abs(dy) < tol) = 0;

    signs = sign(dy);
    for i = 2:numel(signs)
        if signs(i) == 0
            signs(i) = signs(i-1);
        end
    end

    idx = find(signs(1:end-1) .* signs(2:end) < 0) + 1;
end
