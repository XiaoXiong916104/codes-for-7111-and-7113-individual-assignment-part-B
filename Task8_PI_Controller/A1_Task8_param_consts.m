% Task 8 parameter and controller-constant script
% CHEE7111/7113 Individual Assignment 2
% Run this script before the Task 8 MATLAB or Simulink simulation.

% Clear any same-name local variables before declaring globals. This avoids
% MATLAB warnings when the script is re-run after a previous simulation.
clear Tc q V rho Cp dHr UA CAf Tf ER k0 T0 CA0 y0 tspan
global Tc q V rho Cp dHr UA CAf Tf ER k0 T0 CA0 y0 tspan

% Inputs / disturbances
Tc  = 270;      % jacket/coolant temperature, K
CAf = 1.0;      % feed concentration of A, mol/m^3
Tf  = 350;      % feed temperature, K

% Physical properties / reactor data
q   = 100;      % volumetric flow rate, m^3/s
V   = 100;      % reactor volume, m^3
rho = 1000;     % density, kg/m^3
Cp  = 0.239;    % heat capacity, J/(kg K)
dHr = -5e4;     % heat of reaction, J/mol
UA  = 5e4;      % overall heat-transfer coefficient times area, W/K

% Kinetic parameters
ER  = 8750;     % E/R, K
k0  = 6.379829e+10;     % .379829pre-exponential factor, 1/s

% Nominal steady state used as the initial condition
Tss  = 296.527;      % reactor temperature, K
CAss = 0.9903;       % reactor concentration, mol/m^3
yss  = [Tss; CAss];

T_sp = 300;          % reactor-temperature setpoint, K
tspan = [0 40];      % simulation time span, s

% PI settings for the Simulink Parallel PID block used in Task 8

Ku = 120;  %
Tu = 0.02 ; %
Kp= Ku/2.2;
Ti=Tu/1.2;
Ki=Kp/Ti;