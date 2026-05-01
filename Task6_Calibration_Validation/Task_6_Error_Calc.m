function f = Task_6_Error_Calc(p, tdata, ydata, const)
% Task_6_Error_Calc
% Residual function for Task 6 calibration in log10(k0)-space.
%
% Inputs:
%   p     - optimisation variable, p = log10(k0)
%   tdata - experimental time vector [s]
%   ydata - experimental data matrix [T, CA]
%   const - structure containing model constants and operating conditions
%
% Output:
%   f     - stacked residual vector

k0 = 10.^p;
y0 = [const.T0; const.CA0];

[~, y] = ode45(@(t, y) Task_6_Calibrate_Model(t, y, k0, const), tdata, y0);

T_model = y(:, 1);
CA_model = y(:, 2);
T_data = ydata(:, 1);
CA_data = ydata(:, 2);

% Scale residuals so both outputs contribute at similar order of magnitude.
T_res = (T_model - T_data) / max(abs(const.T0), eps);
CA_res = (CA_model - CA_data) / max(abs(const.CA0), eps);

f = [T_res; CA_res];
end
