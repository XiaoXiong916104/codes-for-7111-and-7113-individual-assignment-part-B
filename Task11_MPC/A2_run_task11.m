%% Task 11 one-click setup and simulation runner
% Run this script before pressing Run in task11_simulink.slx.
% The MPC Controller block expects an MPC object named "mpc1" in the
% MATLAB base workspace. If "mpc1" is missing, Simulink reports:
% "Cannot resolve: mpc1".

clc;

thisFile = mfilename('fullpath');
if isempty(thisFile)
    thisFile = which('A2_run_task11');
end
if isempty(thisFile)
    thisFolder = pwd;
else
    thisFolder = fileparts(thisFile);
end
oldFolder = pwd;
cleanupObj = onCleanup(@() cd(oldFolder));
cd(thisFolder);

codeRoot = fileparts(thisFolder);
codePackRoot = fileparts(codeRoot);
assignmentRoot = fileparts(codePackRoot);
addpath(thisFolder);
addpath(codeRoot);
addpath(assignmentRoot);

plantModel = 'plant_ToBeCompletedForTask7';
plantCandidates = {
    fullfile(thisFolder, [plantModel '.slx'])
    fullfile(assignmentRoot, [plantModel '.slx'])
    fullfile(pwd, [plantModel '.slx'])
    };

plantFile = '';
for i = 1:numel(plantCandidates)
    existCode = exist(plantCandidates{i}, 'file');
    if existCode == 2 || existCode == 4
        plantFile = plantCandidates{i};
        break;
    end
end

if isempty(plantFile)
    warning('Cannot find %s.slx. The Task 11 Simulink model may fail if it references this plant model.', plantModel);
else
    addpath(fileparts(plantFile));
    load_system(plantFile);
end

%% Use the current MPC controller if available
% MPC Designer may leave the latest controller object in the MATLAB base
% workspace. Do not overwrite it. Only load the saved backup when mpc1 is
% missing, so this runner can reproduce either the live Designer tuning or
% the submitted backup.
if evalin('base', 'exist(''mpc1'', ''var'')') && evalin('base', 'isa(mpc1, ''mpc'')')
    mpc1 = evalin('base', 'mpc1');
    fprintf('Using existing MPC object "mpc1" from the base workspace.\n');
else
    if exist('mpc1_backup.mat', 'file') ~= 2
        error('mpc1 was not found in the base workspace and mpc1_backup.mat was not found in %s.', thisFolder);
    end

    S_mpc = load('mpc1_backup.mat');

    if isfield(S_mpc, 'mpc1')
        mpc1 = S_mpc.mpc1;
    else
        mpc1 = [];
        names = fieldnames(S_mpc);
        for i = 1:numel(names)
            candidate = S_mpc.(names{i});
            if isa(candidate, 'mpc')
                mpc1 = candidate;
                break;
            end
        end

        if isempty(mpc1)
            error('No MPC object was found in mpc1_backup.mat.');
        end
    end

    assignin('base', 'mpc1', mpc1);
    fprintf('Loaded MPC object "mpc1" from mpc1_backup.mat.\n');
end

%% Load supporting workspace variables if available
% Do not overwrite variables already present in the base workspace. This is
% important after running MPC Designer, because the live workspace may hold
% newer tuning/scenario values than the backup file.
if exist('task11_workspace_backup.mat', 'file') == 2
    S_ws = load('task11_workspace_backup.mat');
    wsNames = fieldnames(S_ws);
    for i = 1:numel(wsNames)
        if ~evalin('base', sprintf('exist(''%s'', ''var'')', wsNames{i}))
            assignin('base', wsNames{i}, S_ws.(wsNames{i}));
        end
    end
end

%% Open and run the Simulink model
mdl = 'task11_simulink';
mdlFile = fullfile(thisFolder, [mdl '.slx']);
if exist(mdlFile, 'file') ~= 2 && exist(mdlFile, 'file') ~= 4
    error('Cannot find %s.', mdlFile);
end
open_system(mdlFile);

% The saved model may contain an old operating-point snapshot
% (for example getstatestruct(op_snapshot1)). That snapshot can become
% invalid if the model is moved or blocks are renamed. It is not required
% for reproducing the closed-loop run, so disable initial-state loading.
set_param(mdl, 'LoadInitialState', 'off');
set_param(mdl, 'InitialState', '');

set_param(mdl, 'SimulationCommand', 'update');
out = sim(mdl);
assignin('base', 'out_task11', out);

% Copy logged To Workspace signals back to the base workspace for plotting.
% Depending on MATLAB settings, sim(mdl) may return them inside out_task11
% rather than leaving them directly in the base workspace.
local_assign_signal_from_simout(out, 'T_out', 'T_out');
local_assign_signal_from_simout(out, 'Tc_out', 'Tc_out');
local_assign_signal_from_simout(out, 'CA_out', 'CA_out');

if evalin('base', 'exist(''CA_out'', ''var'')')
    assignin('base', 'CA', evalin('base', 'CA_out'));
end

fprintf('Task 11 simulation complete. MPC object "mpc1" is loaded in the base workspace.\n');
fprintf('The Simulink model is open. Run A3_make_plot.m to regenerate the figure.\n');

%% local functions
function local_assign_signal_from_simout(simOut, signalName, baseName)
    if isprop(simOut, signalName)
        assignin('base', baseName, simOut.(signalName));
        return;
    end

    try
        assignin('base', baseName, simOut.get(signalName));
    catch
        % Leave existing base variable untouched if the signal is not found.
    end
end
