% make_plot_for_simulink.m

tT  = T_out.Time;
yT  = T_out.Data;

tCA = CA_out.Time;
yCA = CA_out.Data;

figure('Color','w');

subplot(2,1,1)
plot(tT, yT, 'b-', 'LineWidth', 1.8)
xlabel('Time (s)')
ylabel('Temperature, T (K)')
title('Task 7: open-loop temperature response')
legend('Simulink', 'Location', 'best')
grid on

subplot(2,1,2)
plot(tCA, yCA, 'r-', 'LineWidth', 1.8)
xlabel('Time (s)')
ylabel('Concentration, C_A (mol/m^3)')
title('Task 7: open-loop concentration response')
legend('Simulink', 'Location', 'best')
grid on
