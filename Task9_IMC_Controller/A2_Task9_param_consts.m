% Task 9 parameter and IMC-constant script
% CHEE7111/7113 Individual Assignment 2
% Run this script before the Task 9 MATLAB or Simulink simulation.

% Clear any same-name local variables before declaring globals. This avoids
% MATLAB warnings when the script is re-run after a previous simulation.
clear Tc q V rho Cp dHr UA CAf Tf ER k0 T0 CA0 y0 tspan
global Tc q V rho Cp dHr UA CAf Tf ER k0 T0 CA0 y0 tspan

% Inputs / disturbances
Tc_ss = 280;       % nominal jacket/coolant temperature, K
CAf   = 1.0;       % feed concentration of A, mol/m^3
Tf    = 350;       % feed temperature, K

% Physical properties / reactor data
q   = 100;      % volumetric flow rate, m^3/s
V   = 100;      % reactor volume, m^3
rho = 1000;     % density, kg/m^3
Cp  = 0.239;    % heat capacity, J/(kg K)
dHr = -5e4;     % heat of reaction, J/mol
UA  = 5e4;      % overall heat-transfer coefficient times area, W/K

% Kinetic parameters
ER  = 8750;     % E/R, K
k0  = 6.379829e+10;     % pre-exponential factor, 1/s

% Initial conditions
T0  = 303.49;      % initial reactor temperature, K
CA0 = 0.9803;      % initial reactor concentration, mol/m^3
y0  = [T0; CA0];
CA_sp = 1;         % concentration setpoint used in the model, mol/m^3
T_sp  = 300;       % reactor-temperature setpoint, K
tspan = [0 40];    % simulation time span, s

%% FOPDT parameters used for IMC design
Km     = 0.858176; % process gain, K/K
taum   = 0.41534;  % process time constant, s
thetam = 0.064283; % effective time delay, s

%% IMC tuning parameter
tau_f = 0.41534;   % IMC filter time constant, s
