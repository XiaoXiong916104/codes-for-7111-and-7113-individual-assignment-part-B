%% Task 9 all-in-one script
% This script:
% 1) extracts T and Tc data from SimulationOutput "out"
% 2) plots the data
% 3) saves raw data
% 4) calculates 3 sets of FOPDT parameters
% 5) calculates final averaged FOPDT parameters
% 6) calculates fit quality for each step using the identified FOPDT model
% 7) writes everything into one Excel file
%
% Before running this script, run the Simulink model:
%   FOPDT_model_set.slx
% and make sure it exports SimulationOutput variable "out".

clearvars -except out
clc; close all;

%% 1) Extract data from SimulationOutput
T_data  = out.T_data;
Tc_data = out.Tc_data;

t  = T_data.time(:);                  % time [s]
T  = T_data.signals.values(:);        % reactor temperature [K]
Tc = Tc_data.signals.values(:);       % jacket temperature [K]

%% 2) Plot raw data
figure;
plot(t, T, 'LineWidth', 1.5); hold on;
plot(t, Tc, '--', 'LineWidth', 1.2);
xlabel('Time (s)');
ylabel('Temperature (K)');
legend('Reactor Temperature (T)', 'Jacket Temperature (Tc)', 'Location', 'best');
title('Task 9 Step Test Data');
grid on;

%% 3) Save raw data table
RawDataTable = table(t, T, Tc, ...
    'VariableNames', {'Time_s','Reactor_T_K','Jacket_Tc_K'});

%% 4) Detect step times automatically from Tc
dTc = diff(Tc);
step_idx = find(abs(dTc) > 1e-6) + 1;

% remove duplicate detections that are too close together
if ~isempty(step_idx)
    keep = [true; diff(step_idx) > 5];
    step_idx = step_idx(keep);
end

if length(step_idx) < 3
    error('Less than 3 step changes detected in Tc. Please check the exported data.');
end

% keep first 3 detected steps
step_idx = step_idx(1:3);
step_times = t(step_idx);

fprintf('Detected step times:\n');
disp(step_times.');

%% 5) Calculate FOPDT parameters for each of the 3 steps
Km_all = zeros(3,1);
tau_all = zeros(3,1);
theta_all = zeros(3,1);
t1_all = zeros(3,1);
t2_all = zeros(3,1);
y0_all = zeros(3,1);
yF_all = zeros(3,1);
u0_all = zeros(3,1);
uF_all = zeros(3,1);
fitPct_all = zeros(3,1);
rmse_all = zeros(3,1);

for k = 1:3
    i_step = step_idx(k);
    ts = t(i_step);

    % define end index of current step response
    if k < 3
        i_end = step_idx(k+1) - 1;
    else
        i_end = length(t);
    end

    % steady-state averaging windows
    i_pre1 = max(1, i_step - 20);
    i_pre2 = i_step - 1;

    i_post1 = max(i_step + 5, i_end - 20);
    i_post2 = i_end;

    if i_pre2 <= i_pre1 || i_post2 <= i_post1
        error('Step %d: not enough points for steady-state averaging.', k);
    end

    % initial and final steady-state values
    y0 = mean(T(i_pre1:i_pre2));
    yF = mean(T(i_post1:i_post2));
    u0 = mean(Tc(i_pre1:i_pre2));
    uF = mean(Tc(i_post1:i_post2));

    dy = yF - y0;
    du = uF - u0;

    if abs(du) < 1e-10
        error('Step %d: input change too small.', k);
    end

    % process gain
    Km = dy / du;

    % 28.3% and 63.2% target values
    y283 = y0 + 0.283 * dy;
    y632 = y0 + 0.632 * dy;

    % segment after current step
    t_seg = t(i_step:i_end) - ts;   % relative time
    y_seg = T(i_step:i_end);

    % find t1 and t2
    t1 = first_crossing_time(t_seg, y_seg, y283);
    t2 = first_crossing_time(t_seg, y_seg, y632);

    if isnan(t1) || isnan(t2) || t2 <= t1
        error('Step %d: failed to find valid t1 and t2.', k);
    end

    % FOPDT parameters
    tau_m = 1.5 * (t2 - t1);
    theta_m = t2 - tau_m;

    % hand-coded FOPDT fit quality on the same step segment
    y_hat = y0 + fopdt_response(t_seg, Km, du, tau_m, theta_m);
    fitPct = 100 * (1 - norm(y_seg - y_hat) / norm(y_seg - mean(y_seg)));
    rmse = sqrt(mean((y_seg - y_hat).^2));

    % store
    Km_all(k) = Km;
    tau_all(k) = tau_m;
    theta_all(k) = theta_m;
    t1_all(k) = t1;
    t2_all(k) = t2;
    y0_all(k) = y0;
    yF_all(k) = yF;
    u0_all(k) = u0;
    uF_all(k) = uF;
    fitPct_all(k) = fitPct;
    rmse_all(k) = rmse;

    fprintf('\nStep %d\n', k);
    fprintf('  Step time = %.4f s\n', ts);
    fprintf('  Km        = %.6f\n', Km);
    fprintf('  t1        = %.6f s\n', t1);
    fprintf('  t2        = %.6f s\n', t2);
    fprintf('  tau_m     = %.6f s\n', tau_m);
    fprintf('  theta_m   = %.6f s\n', theta_m);
    fprintf('  Fit       = %.2f %%\n', fitPct);
    fprintf('  RMSE      = %.6f K\n', rmse);

    % Diagnostic plot for 28.3% / 63.2% identification
    fig = figure('Visible','off','Color','w','Position',[100 100 850 500]);
    plot(t_seg, y_seg, 'LineWidth', 1.8, 'Color', [0 0.447 0.741]); hold on;
    yline(y0, '--', 'y_0', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.1);
    yline(yF, '--', 'y_F', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.1);
    yline(y283, ':', '28.3%', 'Color', [0.85 0.325 0.098], 'LineWidth', 1.4);
    yline(y632, ':', '63.2%', 'Color', [0.494 0.184 0.556], 'LineWidth', 1.4);
    xline(t1, '--', sprintf('t_1 = %.3f s', t1), 'Color', [0.85 0.325 0.098], 'LineWidth', 1.2);
    xline(t2, '--', sprintf('t_2 = %.3f s', t2), 'Color', [0.494 0.184 0.556], 'LineWidth', 1.2);
    xlabel('Time since step (s)');
    ylabel('Reactor temperature (K)');
    title(sprintf('Task 9 Step %d Identification by 28.3%% / 63.2%% Method', k));
    legend('T response', 'Location', 'best');
    grid on;
    saveas(fig, sprintf('task9_step%d_283_632.png', k));
    savefig(fig, sprintf('task9_step%d_283_632.fig', k));
    close(fig);
end

%% 6) Final averaged parameters
Km_final = mean(Km_all);
tau_final = mean(tau_all);
theta_final = mean(theta_all);

fprintf('\n=====================================\n');
fprintf('Final averaged FOPDT parameters:\n');
fprintf('Km      = %.6f\n', Km_final);
fprintf('tau_m   = %.6f s\n', tau_final);
fprintf('theta_m = %.6f s\n', theta_final);
fprintf('=====================================\n');

%% 7) Build result tables
EachStepTable = table((1:3)', step_times, y0_all, yF_all, u0_all, uF_all, ...
    Km_all, t1_all, t2_all, tau_all, theta_all, fitPct_all, rmse_all, ...
    'VariableNames', {'StepNo','StepTime_s','y0_K','yF_K','u0_K','uF_K', ...
    'Km','t1_s','t2_s','tau_m_s','theta_m_s','FitPercent','RMSE_K'});

FinalTable = table(Km_final, tau_final, theta_final, ...
    'VariableNames', {'Km_final','tau_final_s','theta_final_s'});

disp(EachStepTable);
disp(FinalTable);

%% 8) Write everything into ONE Excel file
excelFile = 'fopdt_temperature_data.xlsx';

writetable(RawDataTable, excelFile, 'Sheet', 'RawData');
writetable(EachStepTable, excelFile, 'Sheet', 'EachStepFOPDT');
writetable(FinalTable, excelFile, 'Sheet', 'FinalAverage');

%% 9) Optional MAT file
save('fopdt_temperature_data.mat', ...
    't', 'T', 'Tc', ...
    'RawDataTable', 'EachStepTable', 'FinalTable', ...
    'Km_final', 'tau_final', 'theta_final');

%% local functions
function tc = first_crossing_time(t, y, ytarget)
    tc = NaN;
    for i = 1:length(y)-1
        if (y(i) <= ytarget && y(i+1) >= ytarget) || ...
           (y(i) >= ytarget && y(i+1) <= ytarget)

            if abs(y(i+1) - y(i)) < 1e-12
                tc = t(i);
            else
                tc = t(i) + (ytarget - y(i)) * (t(i+1) - t(i)) / (y(i+1) - y(i));
            end
            return;
        end
    end
end

function ydev = fopdt_response(t, K, du, tau, theta)
    ydev = zeros(size(t));
    tau = max(tau, eps);
    for i = 1:numel(t)
        if t(i) > theta
            ydev(i) = K * du * (1 - exp(-(t(i) - theta)/tau));
        else
            ydev(i) = 0;
        end
    end
end
