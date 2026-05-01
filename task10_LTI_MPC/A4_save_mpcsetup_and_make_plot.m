%% Task 10: Combined MPC response figure with setpoint
% Required workspace variables:
%   T_time, T_data   - reactor temperature time vector [s] and data [K]
%   Tc_time, Tc_data - jacket temperature time vector [s] and data [K]
%   CA_time, CA_data - concentration time vector [s] and data [mol/m^3]

% Build the reactor-temperature setpoint profile, unit: K.
% Time unit throughout this script: s.
t = T_time;

Tsp = zeros(size(t));
Tsp(t < 4) = 296.5;
Tsp(t >= 4  & t < 8)  = 300;
Tsp(t >= 8  & t < 12) = 320;
Tsp(t >= 12) = 280;

figure;

%% Temperature plot: reactor temperature, jacket temperature, and setpoint
subplot(2,1,1)
plot(T_time, T_data, 'LineWidth', 1.5)
hold on
plot(Tc_time, Tc_data, 'LineWidth', 1.5)
plot(t, Tsp, 'k--', 'LineWidth', 1.5)

xlabel('Time (s)')
ylabel('Temperature (K)')
title('MPC Response: Reactor Temperature and Jacket Temperature')

legend('Reactor temperature T', ...
       'Jacket temperature T_c', ...
       'Setpoint T_{sp}', ...
       'Location', 'best')

grid on

%% Concentration plot
subplot(2,1,2)
plot(CA_time, CA_data, 'LineWidth', 1.5)

xlabel('Time (s)')
ylabel('C_A (mol/m^3)')
title('MPC Response: Reactant Concentration')

grid on

%% Save figure
saveas(gcf, 'task10_MPC_response.png')

disp('Plot saved:')
disp('  task10_MPC_response.png')
