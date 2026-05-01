%% TASK 10 - Closed-loop MATLAB MPC simulation and comparison figure
% This script plots the Task 10 LTI MPC response and compares it with the
% Task 9 IMC/PID results generated under the same Task 9 conditions.
% It assumes the LTI MPC simulation has already
% saved task10_results_clean.mat in this folder.
%
% Main variables:
%   T_abs   - reactor temperature, K
%   CA_abs  - reactor concentration, mol/m^3
%   Tc_abs  - coolant/jacket temperature manipulated variable, K
%   r_abs   - reactor-temperature setpoint, K

clc; close all;

thisFolder = fileparts(mfilename('fullpath'));
oldFolder = pwd;
cleanupObj = onCleanup(@() cd(oldFolder));
cd(thisFolder);
codeRoot = fileparts(thisFolder);
if exist(fullfile(codeRoot, 'project_paths.m'), 'file') == 2
    addpath(codeRoot);
    paths = project_paths();
else
    paths = struct();
    paths.task9 = fullfile(codeRoot, 'Task9_IMC_Controller');
end

%% =========================================================
% 1. LOAD TASK 10 LTI MPC RESULT
% =========================================================
if exist('task10_results_clean.mat', 'file') ~= 2
    error('task10_results_clean.mat was not found in %s. Run the LTI MPC simulation and clean/save its results first.', thisFolder);
end

load('task10_results_clean.mat', ...
    'T_time', 'T_data', ...
    'CA_time', 'CA_data', ...
    'Tc_time', 'Tc_data');

[t_sim, T_abs] = local_make_xy(T_time, T_data, 'T_data');    % s, K
[t_CA, CA_abs] = local_make_xy(CA_time, CA_data, 'CA_data'); % s, mol/m^3
[t_Tc, Tc_abs] = local_make_xy(Tc_time, Tc_data, 'Tc_data'); % s, K

% Task 10 starts from 296.5 K and only displays the setpoint after 4 s in
% the comparison figure, matching the final report convention.
r_abs = 296.5 * ones(size(t_sim));
r_abs(t_sim >= 4)  = 300;
r_abs(t_sim >= 8)  = 320;
r_abs(t_sim >= 12) = 280;
r_plot = r_abs;
r_plot(t_sim < 4) = NaN;

save('task10_mpc_results.mat', 't_sim', 'T_abs', 't_CA', 'CA_abs', 't_Tc', 'Tc_abs', 'r_abs');

figure('Name','Task 10 MPC Response','Color','w');
subplot(2,1,1)
plot(t_sim, r_plot, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Setpoint'); hold on;
plot(t_sim, T_abs, 'b-', 'LineWidth', 1.5, 'DisplayName', 'MPC T');
grid on;
xlabel('Time (s)');
ylabel('Temperature (K)');
title('MPC: Reactor Temperature Response');
legend('Location','best');

subplot(2,1,2)
plot(t_Tc, Tc_abs, 'r-', 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('T_c (K)');
title('MPC: Manipulated Variable');

saveas(gcf, 'Task10_MPC_Response.png');

%% =========================================================
% 2. LOAD TASK 9 PID AND IMC DATA
% =========================================================
task9Folder = paths.task9;

[t_PID, T_PID, CA_PID] = local_task9_controller_data(task9Folder, 'PID');
[t_IMC, T_IMC, CA_IMC, t_IMC_Tc, Tc_IMC] = local_task9_controller_data(task9Folder, 'IMC');

Tsp_plot = NaN(size(t_sim));
Tsp_plot(t_sim >= 4)  = 300;
Tsp_plot(t_sim >= 8)  = 320;
Tsp_plot(t_sim >= 12) = 280;

%% =========================================================
% 3. PID / IMC / MPC COMPARISON FIGURE
% =========================================================
figure('Name', 'Task 10 Controller Comparison', 'Color', 'w');

subplot(3,1,1)
plot(t_sim, Tsp_plot, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Setpoint'); hold on;
plot(t_PID, T_PID, 'r-',  'LineWidth', 1.5, 'DisplayName', 'PID (Task 9)');
plot(t_IMC, T_IMC, 'g-',  'LineWidth', 1.5, 'DisplayName', 'IMC (Task 9)');
plot(t_sim, T_abs, 'b-',  'LineWidth', 1.5, 'DisplayName', 'MPC (Task 10)');
grid on;
xlabel('Time (s)');
ylabel('Temperature (K)');
title('Reactor Temperature: PID vs IMC vs MPC');
legend('Location', 'northeastoutside');
ylim([265 335]);

subplot(3,1,2)
plot(t_PID, CA_PID, 'r-', 'LineWidth', 1.5, 'DisplayName', 'PID (Task 9)'); hold on;
plot(t_IMC, CA_IMC, 'g-', 'LineWidth', 1.5, 'DisplayName', 'IMC (Task 9)');
plot(t_CA, CA_abs, 'b-', 'LineWidth', 1.5, 'DisplayName', 'MPC (Task 10)');
grid on;
xlabel('Time (s)');
ylabel('C_A (mol/m^3)');
title('Reactor Concentration: PID vs IMC vs MPC');
legend('Location', 'northeastoutside');

subplot(3,1,3)
plot(t_IMC_Tc, Tc_IMC, 'g-', 'LineWidth', 1.5, 'DisplayName', 'IMC (Task 9)'); hold on;
plot(t_Tc, Tc_abs, 'b-', 'LineWidth', 1.5, 'DisplayName', 'MPC (Task 10)');
grid on;
xlabel('Time (s)');
ylabel('T_c (K)');
title('Jacket Temperature: IMC vs MPC');
legend('Location', 'northeastoutside');

saveas(gcf, 'Task10_Controller_Comparison.png');

fprintf('Task 10 comparison plot saved.\n');

%% local functions
function [t, y] = local_make_xy(tRaw, yRaw, yName)
    t = tRaw(:);

    if isvector(yRaw)
        y = yRaw(:);
    elseif size(yRaw, 1) == numel(t)
        y = yRaw(:, 1);
    elseif size(yRaw, 2) == numel(t)
        y = yRaw(1, :).';
    else
        error('%s size [%s] does not match time length %d.', ...
            yName, num2str(size(yRaw)), numel(t));
    end

    if numel(t) ~= numel(y)
        error('%s length %d does not match time length %d.', ...
            yName, numel(y), numel(t));
    end
end

function [t, T, CA, tTc, Tc] = local_task9_controller_data(task9Folder, controllerName)
    if ~isfolder(task9Folder)
        error('Task 9 folder was not found: %s', task9Folder);
    end

    oldFolder = pwd;
    cleanupObj = onCleanup(@() cd(oldFolder));
    cd(task9Folder);

    switch upper(controllerName)
        case 'IMC'
            outVar = 'out_IMC';
            modelName = 'A5_IMC_control.slx';
            tFields = {'IMC_T'};
            caFields = {'IMC_CA'};
            tcFields = {'IMC_Tc'};
        case 'PID'
            outVar = 'out_PID';
            modelName = 'A6_PID_control.slx';
            tFields = {'PID_T'};
            caFields = {'PID_CA'};
            tcFields = {};
        otherwise
            error('Unsupported Task 9 controller: %s', controllerName);
    end

    % Always regenerate the Task 9 controller response here. This prevents
    % stale Task 8/Task 10 workspace data from being reused and keeps PID and
    % IMC on the same Task 9 setpoint/disturbance conditions.
    if exist('A2_Task9_param_consts.m', 'file') == 2
        % Simulink plant parameters such as dHr, rho, Cp, and UA are
        % evaluated in the MATLAB base workspace. This code is inside a
        % local function, so evalin('base', ...) is required here.
        evalin('base', 'run(''A2_Task9_param_consts.m'')');
    end
    simOut = sim(modelName);
    assignin('base', outVar, simOut);

    [t, T] = local_get_signal(outVar, tFields);
    [~, CA] = local_get_signal(outVar, caFields);
    if isempty(tcFields)
        tTc = [];
        Tc = [];
    else
        [tTc, Tc] = local_get_signal(outVar, tcFields);
    end
end

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
    add_line(modelName, [sourceBlock '/1'], ['To Workspace ' variableName '/1'], ...
        'autorouting', 'on');
end

function tf = local_base_has_signals(outVar, fieldNames)
    tf = false;
    if ~evalin('base', sprintf('exist(''%s'', ''var'')', outVar))
        return;
    end

    outObj = evalin('base', outVar);
    tf = true;
    for i = 1:numel(fieldNames)
        tf = tf && local_has_output_signal(outObj, fieldNames{i});
        if ~tf
            return;
        end
    end
end

function [t, y] = local_get_signal(outVar, fieldNames)
    outObj = evalin('base', outVar);

    for i = 1:numel(fieldNames)
        fieldName = fieldNames{i};
        if local_has_output_signal(outObj, fieldName)
            sig = local_get_output_signal(outObj, fieldName);
            [t, y] = local_unpack_signal(sig, [outVar '.' fieldName]);
            return;
        end

        % Some Simulink versions/settings write To Workspace variables
        % directly to the MATLAB base workspace instead of packing them
        % inside the SimulationOutput object returned by sim(modelName).
        if evalin('base', sprintf('exist(''%s'', ''var'')', fieldName))
            sig = evalin('base', fieldName);
            [t, y] = local_unpack_signal(sig, fieldName);
            return;
        end
    end

    error('Could not find any of these signals in %s: %s', ...
        outVar, strjoin(fieldNames, ', '));
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
