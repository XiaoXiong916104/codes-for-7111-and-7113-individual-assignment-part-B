%% Task 8 PI controller figure for report
% Required workspace data:
%   out.PI_T   - reactor temperature T, timeseries, K
%   out.PI_CA  - reactor concentration C_A, timeseries, mol/m^3
%   out.PI_Tc  - coolant/jacket temperature T_c, timeseries, K
% The script only plots existing simulation results. It does not change any
% controller parameters.
clc; close all;

% ==== Read simulation data ====
T_data  = out.PI_T;
CA_data = out.PI_CA;
Tc_data = out.PI_Tc;

t  = T_data.Time(:);    % time, s
T  = T_data.Data(:);    % reactor temperature, K
CA = CA_data.Data(:);   % reactor concentration, mol/m^3
Tc = Tc_data.Data(:);   % coolant/jacket temperature, K

% ==== Temperature setpoint profile ====
% T_sp is the controlled reactor-temperature target, K.
Tsp = 300 * ones(size(t));
Tsp(t >= 8)  = 320;
Tsp(t >= 12) = 280;

% ==== Combined report figure ====
figure('Color','w','Position',[100 100 900 900]);

subplot(3,1,1)
plot(t, T, 'LineWidth', 1.8); hold on;
plot(t, Tsp, '--', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Temperature (K)');
title('PI Closed-Loop Temperature Response');
legend('T', 'T_{sp}', 'Location', 'best');
grid on;
ylim([270 330])

subplot(3,1,2)
plot(t, CA, 'LineWidth', 1.8);
xlabel('Time (s)');
ylabel('C_A (mol/m^3)');
title('Concentration Response');
grid on;

subplot(3,1,3)
plot(Tc_data.Time(:), Tc, 'LineWidth', 1.8);
xlabel('Time (s)');
ylabel('T_c (K)');
title('Jacket Temperature Response');
grid on;

saveas(gcf, 'task8_PI_response.png');
savefig(gcf, 'task8_PI_response.fig');
