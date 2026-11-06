%% ==================Combustor============================
clc; clear; close all;

%% ---------------------------------------
gamma = 1.4;
R     = 287;                          
cp    = gamma*R/(gamma-1);        
M5  = 0.2;                        
P05 = 246206.86;                     
T05 = 543.96;                         
P5  = 239435.36;                      
T5  = 539.64;                         
T0_max = 2200;                       
P0_extra_loss = 0.95;                 

%% ----------------------------------------
T0_T0star_5 = rayleigh_T0_T0star(M5, gamma);
T0star = T05 / T0_T0star_5;   
T06_desired = min(T0_max, T0star);    
if T0_max > T0star
    choked = true;
else
    choked = false;
end
target_T0_T0star = T06_desired / T0star;

%% ----------------------------------------
if choked
    M6 = 0.999;  
else
    f = @(M) rayleigh_T0_T0star(M, gamma) - target_T0_T0star;
    M_low  = max(1e-4, M5);
    M_high = 0.999;
    if f(M_low)*f(M_high) < 0
        M6 = fzero(f, [M_low, M_high]);
    else
        M6 = fminbnd(@(M) abs(f(M)), M_low, M_high);
    end
end

%% ----------------------------------------
p_pstar_5  = rayleigh_p_pstar(M5, gamma);
T_Tstar_5  = rayleigh_T_Tstar(M5, gamma);
p0_p0star_5 = rayleigh_p0_p0star(M5, gamma);
p_pstar_6  = rayleigh_p_pstar(M6, gamma);
T_Tstar_6  = rayleigh_T_Tstar(M6, gamma);
p0_p0star_6 = rayleigh_p0_p0star(M6, gamma);
pstar = P5 / p_pstar_5;
Tstar = T5 / T_Tstar_5;
P6 = p_pstar_6 * pstar;
T6 = T_Tstar_6 * Tstar;
T06 = T06_desired;
P06_rayleigh = P05 * (p0_p0star_6 / p0_p0star_5);
P06 = P0_extra_loss * P06_rayleigh;

%% ---------------------------------------
q_add = cp * (T06 - T05);    % J/kg

%% ----------------------------------------
fprintf('================ COMBUSTOR RESULTS (RAYLEIGH) ================\n');
fprintf('Combustor entry (station 5):\n');
fprintf('  M5  = %.4f\n  T05 = %.2f K (total)\n  P05 = %.2f Pa (total)\n', M5, T05, P05);
fprintf('  T5  = %.2f K (static)\n  P5  = %.2f Pa (static)\n\n', T5, P5);
fprintf('Combustor exit (station 6):\n');
fprintf('  M6  = %.4f\n', M6);
fprintf('  T06 = %.2f K (total)  [limit = %.2f K]\n', T06, T0_max);
fprintf('  P06 (Rayleigh only) = %.2f Pa (total)\n', P06_rayleigh);
fprintf('  P06 (with extra 5%% loss) = %.2f Pa (total)\n', P06);
fprintf('  T6  = %.2f K (static)\n  P6  = %.2f Pa (static)\n\n', T6, P6);
fprintf('Heat added per unit mass:\n');
fprintf('  q = cp*(T06 - T05) = %.2f kJ/kg\n', q_add/1000);
if choked
    fprintf('\n*** NOTE: Desired T0_max exceeds Rayleigh choking limit for this inlet.\n');
    fprintf('*** Flow is CHOKED in combustor (M -> 1). T06 capped at T0* = %.2f K.\n', T0star);
end
fprintf('==============================================================\n');

%% ======================FUNCTIONS=========================

function val = rayleigh_p_pstar(M, g)
    val = (g + 1) ./ (1 + g*M.^2);
end

function val = rayleigh_T_Tstar(M, g)
    val = ((g + 1).^2 .* M.^2) ./ (1 + g*M.^2).^2;
end

function val = rayleigh_T0_T0star(M, g)
    T_Ts = rayleigh_T_Tstar(M, g);
    val  = T_Ts .* (1 + (g-1)/2 .* M.^2) ./ (1 + (g-1)/2);
end

function val = rayleigh_p0_p0star(M, g)
    p_ps = rayleigh_p_pstar(M, g);
    val  = p_ps .* ((1 + (g-1)/2 .* M.^2).^(g/(g-1))) ./ ((1 + (g-1)/2).^(g/(g-1)));
end
