function dydt = cstr_modelFunc(t, y)
% cstr_modelFunc
% Nonlinear dynamic model for the exothermic CSTR.
%
% State order required by the assignment:
%   y(1) = T   (reactor temperature, K)
%   y(2) = CA  (reactant A concentration, mol/m^3)
%
% Governing equations:
%   dT/dt  = (q/V)(Tf - T) + [(-dHr)/(rho*Cp)] * k * CA + [UA/(rho*Cp*V)](Tc - T)
%   dCA/dt = (q/V)(CAf - CA) - k * CA
%
% with:
%   k = k0 * exp(-ER/T)

    global Tc q V rho Cp dHr UA CAf Tf ER k0

    % States
    T  = y(1);
    CA = y(2);

    % Constitutive equations
    k  = k0 * exp(-ER / T);  % 1/s
    rA = -k * CA;            % mol/(m^3 s), consumption rate of A

    % ODEs
    dTdt  = (q / V) * (Tf - T) ...
          + (-dHr / (rho * Cp)) * k * CA ...
          + (UA / (rho * Cp * V)) * (Tc - T);

    dCAdt = (q / V) * (CAf - CA) + rA;

    dydt = [dTdt; dCAdt];
end
