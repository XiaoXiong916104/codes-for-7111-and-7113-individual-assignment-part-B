% param_consts.m
% CHEE7111/7113 Individual Assignment 2
% Parameter, constant, input, and initial-condition script
%
% Run this script before any MATLAB or Simulink simulation.

global Tc q V rho Cp dHr UA CAf Tf ER k0 T0 CA0 y0 tspan

% Inputs / disturbances
Tc  = 270;      % jacket temperature, K
CAf = 1.0;      % feed concentration of A, mol/m^3
Tf  = 350;      % feed temperature, K

% Physical properties / reactor data
q   = 100;      % volumetric flow rate, m^3/s
V   = 100;      % reactor volume, m^3
rho = 1000;     % density, kg/m^3
Cp  = 0.239;    % heat capacity, J/(kg K) - use the value provided in the assignment
dHr = -5e4;     % heat of reaction, J/mol
UA  = 5e4;      % overall heat-transfer coefficient times area, W/K

% Kinetic parameters
ER  = 8750;     % E/R, K
k0  = 5e10;     % nominal default value for Task 5, 1/s

% Initial conditions
T0  = 305;      % initial temperature, K
CA0 = 0.5;      % initial concentration of A, mol/m^3
y0  = [T0; CA0];

% Default simulation time span
tspan = [0 10];
