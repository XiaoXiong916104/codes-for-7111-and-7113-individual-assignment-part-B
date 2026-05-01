%% Save the current MPC object as the final Task 11 controller
% Run this script after the latest MPC tuning is available in the MATLAB
% base workspace. It saves the selected controller as mpc1_backup.mat, which
% is the file used by A2_run_task11 when mpc1 is not already in workspace.

clc;

thisFolder = fileparts(mfilename('fullpath'));
oldFolder = pwd;
cleanupObj = onCleanup(@() cd(oldFolder));
cd(thisFolder);

vars = evalin('base', 'whos');
isMpc = strcmp({vars.class}, 'mpc');
mpcVars = vars(isMpc);

if isempty(mpcVars)
    error(['No MPC object was found in the MATLAB base workspace. ', ...
        'Export or create the latest controller first, then run this script again.']);
end

fprintf('\nMPC objects currently in the base workspace:\n');
for i = 1:numel(mpcVars)
    fprintf('  [%d] %s\n', i, mpcVars(i).name);
end

if numel(mpcVars) == 1
    selectedName = mpcVars(1).name;
    fprintf('\nOnly one MPC object was found. Using "%s" as the final controller.\n', selectedName);
else
    selectedName = input('\nEnter the variable name to save as final mpc1: ', 's');
    if ~any(strcmp({mpcVars.name}, selectedName))
        error('"%s" is not an MPC object in the base workspace.', selectedName);
    end
end

mpc1 = evalin('base', selectedName);
assignin('base', 'mpc1', mpc1);

save('mpc1_backup.mat', 'mpc1');

fprintf('\nFinal Task 11 MPC controller saved to:\n  %s\n', fullfile(thisFolder, 'mpc1_backup.mat'));
fprintf('The base workspace variable "mpc1" has also been updated to this final controller.\n');
