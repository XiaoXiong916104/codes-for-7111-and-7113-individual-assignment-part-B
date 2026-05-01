function dydt = Task_6_Calibrate_Model(t, y, k0, const)
% Task_6_Calibrate_Model
%
% Dynamic CSTR model for calibration.
%
% Inputs:
%   t     - time [s]
%   y     - state vector [T; CA]
%   k0    - pre-exponential factor [1/s]
%   const - structure containing model constants
%
% Output:
%   dydt  - state derivatives [dT/dt; dCA/dt]

%% State variables
T  = y(1);   % [K]
CA = y(2);   % [mol/m^3]

%% Constants
q           = const.q;
V           = const.V;
rho         = const.rho;
Cp          = const.Cp;
DeltaHr     = const.DeltaHr;
UA          = const.UA;
E_over_R    = const.E_over_R;
Tf          = const.Tf;
CAf         = const.CAf;
Tc          = const.Tc;

%% Kinetics
k = k0 * exp(-E_over_R / T);

%% Mass balance
dCA_dt = (q / V) * (CAf - CA) - k * CA;

%% Energy balance
dT_dt = (q / V) * (Tf - T) ...
      + (-DeltaHr / (rho * Cp)) * k * CA ...
      + (UA / (rho * Cp * V)) * (Tc - T);

%% Return derivatives
dydt = [dT_dt; dCA_dt];
end