%% task9_fopdt_toolbox_check.m
% Toolbox-based FOPDT identification for Task 9
%
% Use this as a cross-check against task9_fopdt.m.
% Before running this script, run the Simulink model:
%   FOPDT_model_set.slx
% Expected workspace variable:
%   out  -> SimulationOutput containing T_data and Tc_data

clearvars -except out
clc; close all;

if ~exist('out', 'var')
    error('Please run the Task 9 Simulink model first so that variable "out" exists.');
end

if ~isprop(out, 'T_data') || ~isprop(out, 'Tc_data')
    error('SimulationOutput "out" must contain T_data and Tc_data.');
end

if exist('iddata', 'file') ~= 2 || exist('procest', 'file') ~= 2
    error('System Identification Toolbox functions iddata/procest are not available.');
end

%% Extract data
T_data  = out.T_data;
Tc_data = out.Tc_data;

t  = T_data.time(:);
T  = T_data.signals.values(:);
Tc = Tc_data.signals.values(:);

dt = mean(diff(t));

%% Detect step times
dTc = diff(Tc);
step_idx = find(abs(dTc) > 1e-6) + 1;

if ~isempty(step_idx)
    keep = [true; diff(step_idx) > 5];
    step_idx = step_idx(keep);
end

if numel(step_idx) < 3
    error('Less than 3 step changes detected in Tc.');
end

step_idx = step_idx(1:3);
step_times = t(step_idx);

fprintf('Detected step times:\n');
disp(step_times.')

%% Fit FOPDT model for each step using procest
Km_all = zeros(3,1);
tau_all = zeros(3,1);
theta_all = zeros(3,1);
fit_all = zeros(3,1);

for k = 1:3
    i_step = step_idx(k);

    if k < 3
        i_end = step_idx(k+1) - 1;
    else
        i_end = numel(t);
    end

    % include a pre-step window so the estimation data starts at equilibrium
    i_pre1 = max(1, i_step - 20);
    i_pre2 = i_step - 1;

    if i_pre2 <= i_pre1
        error('Step %d: not enough pre-step points for toolbox fitting.', k);
    end

    t_seg = t(i_pre1:i_end);
    y_seg = T(i_pre1:i_end);
    u_seg = Tc(i_pre1:i_end);

    % local steady-state values before the step
    y0 = mean(T(i_pre1:i_pre2));
    u0 = mean(Tc(i_pre1:i_pre2));

    % convert to deviation variables
    y_dev = y_seg - y0;
    u_dev = u_seg - u0;

    % shift time to zero
    t_rel = t_seg - t_seg(1);

    z = iddata(y_dev, u_dev, dt);
    z.Tstart = t_rel(1);

    % FOPDT process model: K / (1 + tau*s) with dead time
    sys = procest(z, 'P1D');

    Km_all(k) = sys.Kp;
    tau_all(k) = sys.Tp1;
    theta_all(k) = sys.Td;

    try
        [~, fitValue] = compare(z, sys);
        if isnumeric(fitValue)
            fit_all(k) = fitValue(1);
        else
            fit_all(k) = NaN;
        end
    catch
        fit_all(k) = NaN;
    end

    fprintf('\nStep %d\n', k);
    fprintf('  Step time = %.4f s\n', t(i_step));
    fprintf('  Km        = %.6f\n', Km_all(k));
    fprintf('  tau_m     = %.6f s\n', tau_all(k));
    fprintf('  theta_m   = %.6f s\n', theta_all(k));
    fprintf('  Fit       = %.2f %%\n', fit_all(k));

    figure('Color','w');
    compare(z, sys);
    title(sprintf('Task 9 Toolbox FOPDT Fit - Step %d', k));
end

%% Final average
Km_final = mean(Km_all, 'omitnan');
tau_final = mean(tau_all, 'omitnan');
theta_final = mean(theta_all, 'omitnan');

fprintf('\n=====================================\n');
fprintf('Toolbox-based averaged FOPDT parameters:\n');
fprintf('Km      = %.6f\n', Km_final);
fprintf('tau_m   = %.6f s\n', tau_final);
fprintf('theta_m = %.6f s\n', theta_final);
fprintf('=====================================\n');

EachStepToolboxTable = table((1:3)', step_times, Km_all, tau_all, theta_all, fit_all, ...
    'VariableNames', {'StepNo','StepTime_s','Km','tau_m_s','theta_m_s','FitPercent'});

FinalToolboxTable = table(Km_final, tau_final, theta_final, ...
    'VariableNames', {'Km_final','tau_final_s','theta_final_s'});

disp(EachStepToolboxTable);
disp(FinalToolboxTable);

writetable(EachStepToolboxTable, 'task9_fopdt_toolbox_results.xlsx', 'Sheet', 'EachStepToolbox');
writetable(FinalToolboxTable, 'task9_fopdt_toolbox_results.xlsx', 'Sheet', 'FinalAverageToolbox');

save('task9_fopdt_toolbox_results.mat', ...
    't', 'T', 'Tc', 'EachStepToolboxTable', 'FinalToolboxTable', ...
    'Km_final', 'tau_final', 'theta_final');
