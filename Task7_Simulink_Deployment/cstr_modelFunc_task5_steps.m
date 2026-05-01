function dydt = cstr_modelFunc_task5_steps(t, y)
% cstr_modelFunc_task5_steps
% MATLAB reference model for Task 7 step tests:
%   CAf increases by 0.1 mol/m^3 at t = 2 s
%   Tf  increases by 10 K       at t = 4 s

    global Tc q V rho Cp dHr UA CAf Tf ER k0

    T  = y(1);
    CA = y(2);

    % Piecewise inputs for step-test reference
    CAf_eff = CAf;
    Tf_eff  = Tf;

    if t >= 2
        CAf_eff = CAf + 0.1;
    end
    if t >= 4
        Tf_eff = Tf + 10;
    end

    k  = k0 * exp(-ER / T);
    rA = -k * CA;

    dTdt  = (q / V) * (Tf_eff - T) ...
          + (-dHr / (rho * Cp)) * k * CA ...
          + (UA / (rho * Cp * V)) * (Tc - T);

    dCAdt = (q / V) * (CAf_eff - CA) + rA;

    dydt = [dTdt; dCAdt];
end
