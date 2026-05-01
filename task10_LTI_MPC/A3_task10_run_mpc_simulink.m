%% Task 10 - Load final MPC workspace and update Simulink model
% Purpose:
%   Prepare the Simulink model mpcobj_1.slx using the final Task 10 MPC
%   variables saved by A4_save_mpcsetup_and_make_plot.m.
%
% Required file:
%   task10_final.mat - contains the final linear MPC object and supporting
%   workspace variables used by the Simulink MPC block.
%
% Note:
%   This script updates the block diagram only. Press Run in Simulink, or
%   run the simulation from MATLAB, after the model has been updated.

clc;

% Load final controller/object variables into the MATLAB workspace.
load('task10_final.mat')

% Open and update the Simulink model so the MPC block resolves workspace data.
open_system('mpcobj_1.slx')
set_param('mpcobj_1', 'SimulationCommand', 'update')
