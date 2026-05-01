%% Task 9 IMC vs PID comparison figure for report
% Required models:
%   A5_IMC_control.slx - IMC closed-loop model
%   A6_PID_control.slx - PID closed-loop model
% Main plotted variables:
%   T   - reactor temperature, K
%   C_A - reactor concentration, mol/m^3
%   T_c - coolant/jacket temperature manipulated variable, K
clc; close all;

% ==== Work from this script folder ====
thisFolder = fileparts(mfilename('fullpath'));
oldFolder = pwd;
cleanupObj = onCleanup(@() cd(oldFolder));
cd(thisFolder);

% ==== Run both Task 9 controllers under the same conditions ====
% Do not reuse old base-workspace outputs here. Task 9 needs a fair IMC vs
% PID comparison using the same setpoint profile and disturbances.
if exist('A1_Task9_param_consts.m', 'file') == 2
    run('A1_Task9_param_consts.m');
end
out_IMC = sim('A5_IMC_control.slx');
assignin('base', 'out_IMC', out_IMC);

out_PID = sim('A6_PID_control.slx');
assignin('base', 'out_PID', out_PID);

% ==== Read IMC and PID data ====
% Each signal is logged as a MATLAB timeseries. The helper functions below
% also support older Simulink structure-with-time output, which makes the
% plotting script less sensitive to the marker's MATLAB logging settings.
[tIMC, TIMC]   = local_get_signal_from('out_IMC', {'IMC_T'}, {'IMC_T', 'IMC_T_out'});
[~, CAIMC]     = local_get_signal_from('out_IMC', {'IMC_CA'}, {'IMC_CA', 'IMC_CA_out'});
[tIMC_Tc, TcIMC] = local_get_signal_from('out_IMC', {'IMC_Tc'}, {'IMC_Tc', 'IMC_Tc_out'});

[tPID, TPID]   = local_get_signal_from('out_PID', {'PID_T'}, {'PID_T', 'PID_T_out'});
[~, CAPID]     = local_get_signal_from('out_PID', {'PID_CA'}, {'PID_CA', 'PID_CA_out'});

% ==== Plot comparison ====
figure('Color','w','Position',[100 100 900 900]);

subplot(3,1,1)
plot(tIMC, TIMC, 'LineWidth', 2.0, 'Color', [0 0.447 0.741]); hold on;
plot(tPID, TPID, '--', 'LineWidth', 1.8, 'Color', [0.850 0.325 0.098]);
xlabel('Time (s)');
ylabel('Temperature (K)');
title('Closed-Loop Reactor Temperature Response');
legend('IMC', 'PID', 'Location', 'best');
grid on;
xlim([0 max([tIMC; tPID])]);

subplot(3,1,2)
plot(tIMC, CAIMC, 'LineWidth', 2.0, 'Color', [0 0.447 0.741]); hold on;
plot(tPID, CAPID, '--', 'LineWidth', 1.8, 'Color', [0.850 0.325 0.098]);
xlabel('Time (s)');
ylabel('C_A (mol/m^3)');
title('Closed-Loop Concentration Response');
legend('IMC', 'PID', 'Location', 'best');
grid on;
xlim([0 max([tIMC; tPID])]);

subplot(3,1,3)
plot(tIMC_Tc, TcIMC, 'LineWidth', 2.0, 'Color', [0 0.447 0.741]);
xlabel('Time (s)');
ylabel('T_c (K)');
title('Closed-Loop Jacket Temperature Response');
legend('IMC', 'Location', 'best');
grid on;
xlim([0 max(tIMC_Tc)]);

saveas(gcf, 'task9_IMC_PID_comparison.png');
savefig(gcf, 'task9_IMC_PID_comparison.fig');

%% local functions
function local_ensure_to_workspace(modelName, sourceBlock, variableName)
    load_system(modelName);

    existing = find_system(modelName, 'SearchDepth', 1, ...
        'BlockType', 'ToWorkspace', 'VariableName', variableName);
    if ~isempty(existing)
        return;
    end

    sinkName = [modelName '/To Workspace ' variableName];
    add_block('simulink/Sinks/To Workspace', sinkName, ...
        'VariableName', variableName, ...
        'SaveFormat', 'Timeseries', ...
        'MaxDataPoints', 'inf', ...
        'Position', [400 655 510 685]);

    try
        add_line(modelName, [sourceBlock '/1'], ['To Workspace ' variableName '/1'], ...
            'autorouting', 'on');
    catch ME
        delete_block(sinkName);
        error('Could not add %s logging to %s: %s', variableName, modelName, ME.message);
    end
end

function tf = local_signal_exists(outVarName, fieldNames)
    tf = false;
    if ~evalin('base', sprintf('exist(''%s'', ''var'')', outVarName))
        return;
    end

    outObj = evalin('base', outVarName);
    for i = 1:numel(fieldNames)
        if local_has_output_signal(outObj, fieldNames{i})
            tf = true;
            return;
        end
    end
end

function [t, y] = local_get_signal_from(outVarName, fieldNames, varNames)
    if evalin('base', sprintf('exist(''%s'', ''var'')', outVarName))
        outObj = evalin('base', outVarName);
        for i = 1:numel(fieldNames)
            fieldName = fieldNames{i};
            if local_has_output_signal(outObj, fieldName)
                sig = local_get_output_signal(outObj, fieldName);
                [t, y] = unpack_signal(sig, [outVarName '.' fieldName]);
                return;
            end
        end
    end

    for i = 1:numel(varNames)
        varName = varNames{i};
        if evalin('base', sprintf('exist(''%s'', ''var'')', varName))
            sig = evalin('base', varName);
            [t, y] = unpack_signal(sig, varName);
            return;
        end
    end

    error('Could not find any of these signals in %s or base workspace: %s', ...
        outVarName, strjoin([fieldNames, varNames], ', '));
end

function tf = local_has_output_signal(outObj, fieldName)
    if isstruct(outObj)
        tf = isfield(outObj, fieldName);
        return;
    end

    tf = isprop(outObj, fieldName);
    if tf
        return;
    end

    try
        names = outObj.who;
        tf = any(strcmp(names, fieldName));
    catch
        tf = false;
    end
end

function sig = local_get_output_signal(outObj, fieldName)
    if isstruct(outObj) || isprop(outObj, fieldName)
        sig = outObj.(fieldName);
        return;
    end

    try
        sig = outObj.get(fieldName);
    catch
        sig = outObj.(fieldName);
    end
end

function [t, y] = unpack_signal(sig, sigName)
    if isa(sig, 'timeseries')
        t = sig.Time(:);
        y = sig.Data(:);
    elseif isstruct(sig)
        t = sig.time(:);
        y = sig.signals.values(:);
    else
        error('Unsupported format for %s.', sigName);
    end
end
