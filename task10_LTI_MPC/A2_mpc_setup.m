clc; clear; close all;

%% Task 10: Linearised CSTR MPC setup

% Continuous-time deviation-variable model around the nominal operating
% point. State units: Delta T [K], Delta CA [mol/m^3].
A = [-2.8908   2.0422;
     -0.0010  -1.0098];

% Input units: Delta Tc [K], Delta CAf [mol/m^3], Delta Tf [K].
B = [2.0921   0       1.0000;
     0        1.0000  0];

% Output units match the state vector: Delta T [K], Delta CA [mol/m^3].
C = eye(2);
D = zeros(2,3);

Ts = 0.1;   % MPC sample time, s

%% Build discrete plant
plant = ss(A,B,C,D);
plant = c2d(plant,Ts);

%% Signal definitions
% Input 1: Delta Tc  = MV
% Input 2: Delta CAf = unmeasured disturbance
% Input 3: Delta Tf  = measured disturbance
% Output 1: Delta T  = measured output
% Output 2: Delta CA = unmeasured output

plant = setmpcsignals(plant, ...
    'MV',1, ...
    'UD',2, ...
    'MD',3, ...
    'MO',1, ...
    'UO',2);

%% Create MPC object
mpcobj = mpc(plant,Ts);

%% Save clean starting point
save('task10_mpc.mat','mpcobj','plant','Ts','A','B','C','D');

%% Open MPC Designer
mpcDesigner(mpcobj);

disp('Task 10 setup complete. MPC Designer is open.');
