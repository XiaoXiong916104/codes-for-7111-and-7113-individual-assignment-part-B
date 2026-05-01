function P = project_paths()
%PROJECT_PATHS Central folder configuration for the assignment code pack.
%
% If the whole repository folder is kept together, no edit is required.
% If MATLAB cannot find the task folders on another computer, change only
% the CODE_ROOT value below to the marker's local repository folder.

% ===== Only edit this line if needed =====
CODE_ROOT = fileparts(mfilename('fullpath'));
% Example:
% CODE_ROOT = 'C:\Users\YourName\Desktop\codes for individual assignment part B';

P.codeRoot = CODE_ROOT;
P.task5 = fullfile(CODE_ROOT, 'Task5_Model_Solution');
P.task6 = fullfile(CODE_ROOT, 'Task6_Calibration_Validation');
P.task7 = fullfile(CODE_ROOT, 'Task7_Simulink_Deployment');
P.task8 = fullfile(CODE_ROOT, 'Task8_PI_Controller');
P.task9 = fullfile(CODE_ROOT, 'Task9_IMC_Controller');
P.task10_LTI = fullfile(CODE_ROOT, 'task10_LTI_MPC');
P.task11 = fullfile(CODE_ROOT, 'Task11_MPC');
end
