%% make_plot_for_simulink.m
% Task 7 plotting script for exported Simulink signals.
%
% Required workspace variables:
%   T_out  - reactor-temperature timeseries from Simulink, K versus s
%   CA_out - reactant-concentration timeseries from Simulink, mol/m^3 versus s
%
% Purpose:
%   Convert the Simulink output signals into labelled MATLAB plots. The
%   report requires exported plots with units, legends and suitable axis
%   labels, rather than screenshots of Simulink scopes.

% Extract time and data vectors from Simulink timeseries outputs.
tT  = T_out.Time;
yT  = T_out.Data;

tCA = CA_out.Time;
yCA = CA_out.Data;

% Create a two-panel figure: temperature response first, concentration second.
figure('Color','w');

subplot(2,1,1)
plot(tT, yT, 'b-', 'LineWidth', 1.8)
xlabel('Time (s)')
ylabel('Temperature, T (K)')
title('Task 7: open-loop temperature response')
legend('Simulink', 'Location', 'best')
grid on

% The concentration plot is used to check the material-balance response.
subplot(2,1,2)
plot(tCA, yCA, 'r-', 'LineWidth', 1.8)
xlabel('Time (s)')
ylabel('Concentration, C_A (mol/m^3)')
title('Task 7: open-loop concentration response')
legend('Simulink', 'Location', 'best')
grid on
