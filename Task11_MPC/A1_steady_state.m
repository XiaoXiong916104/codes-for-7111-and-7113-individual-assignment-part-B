clear; clc;

% Teacher-model parameters. These scaled constants are used by the
% nonlinear plant supplied for Task 11.
qV  = 1.0;          % flow-to-volume ratio q/V, 1/s
UAc = 2.029;        % heat-transfer coefficient UA/(V*rho*Cp), 1/s
ER  = 8750;         % activation-energy ratio E/R, K
k0  = 6.203599e10;  % pre-exponential factor, 1/s
DHc = -209.205;     % scaled heat of reaction DeltaH/(rho*Cp), K*m^3/kmol

% Given conditions
CAf = 1.0;          % feed concentration, kmol/m^3
Tf  = 350.0;        % feed temperature, K
CAs = 0.5;          % target reactor concentration, kmol/m^3

% Steady-state calculation from dCA/dt = 0 and dT/dt = 0
kss = qV * (CAf - CAs) / CAs;  % reaction-rate constant at steady state, 1/s
Tss = ER / log(k0 / kss);      % reactor temperature at steady state, K
Tcss = ((qV + UAc) * Tss + DHc * kss * CAs - qV * Tf) / UAc; % coolant temperature, K

fprintf('Steady-state results for CA = %.4f\n', CAs);
fprintf('kss  = %.6f\n', kss);
fprintf('Tss  = %.6f K\n', Tss);
fprintf('Tcss = %.6f K\n', Tcss);

% Optional stability check:
% The following local linearization is not required to run the Task 11 MPC
% simulation. It is included to justify the report discussion that the
% calculated nominal operating point is open-loop unstable. The eigenvalues
% indicate whether the nonlinear plant would naturally remain near this
% steady state without feedback control.
dkdT = kss * ER / Tss^2;

A11 = -(qV + UAc) - DHc * CAs * dkdT;
A12 = -DHc * kss;
A21 = -CAs * dkdT;
A22 = -(qV + kss);

A = [A11 A12; A21 A22];
eigA = eig(A);

fprintf('\nLinearized state matrix at the steady state:\n');
disp(A)
fprintf('Eigenvalues:\n');
disp(eigA)

if det(A) < 0
    fprintf('This steady state is an open-loop saddle point (unstable).\n');
end
