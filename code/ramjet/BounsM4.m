%% ==================Bonus M=4============================
clc; clear; close all;

gamma = 1.4;
R = 287;
cp = gamma*R/(gamma-1);

%% ==================================
M1 = 4.0;                
P1 = 12.11e3;             
T1 = 216.5;              

%% ==================================
theta1 = 14.30;          
theta2 = 17.40;           
A4 = 0.022720;            
A5 = 0.062500;           
A6 = 0.062500;            
At = 0.054469;            
Ae = 0.145106;            
A_capture = A5;

%% ==================================
T01 = T1*(1 + (gamma-1)/2*M1^2);
P01 = P1*(1 + (gamma-1)/2*M1^2)^(gamma/(gamma-1));

%% ============================================================
opts = optimset('Display','off');
[ok1, beta1, M2, P02_P01] = obliqueStage(M1, theta1, gamma, opts);
if ~ok1
    error('Shock 1 detached at M1=%.2f, theta1=%.2f deg.', M1, theta1);
end

[ok2, beta2, M3, P03_P02] = obliqueStage(M2, theta2, gamma, opts);
if ~ok2
    error('Shock 2 detached at M2=%.3f, theta2=%.2f deg.', M2, theta2);
end

if M3 <= 1
    error('M3 <= 1 after oblique shocks (M3=%.3f). Terminal normal shock cannot form.', M3);
end

P04_P03 = totalPressureRatioNormalShock(M3, gamma);
M4 = downstreamMachNormalShock(M3, gamma);
P04_P01 = P02_P01 * P03_P02 * P04_P03;
T04 = T01;               
P04 = P04_P01 * P01;
T4 = T04/(1 + (gamma-1)/2*M4^2);
P4 = P04/(1 + (gamma-1)/2*M4^2)^(gamma/(gamma-1));

%% ============================================================
A5_A4 = A5 / A4;
A_Astar = @(M) (1./M).* ...
    ((2/(gamma+1))*(1 + (gamma-1)/2*M.^2)).^((gamma+1)/(2*(gamma-1)));
A4_Astar = A_Astar(M4);
A5_Astar_target = A5_A4 * A4_Astar;
g = @(M) A_Astar(M) - A5_Astar_target;
M5 = fzero(g, [1e-4, 0.999]);
T05 = T04;
P05 = P04;
T5 = T05/(1 + (gamma-1)/2*M5^2);
P5 = P05/(1 + (gamma-1)/2*M5^2)^(gamma/(gamma-1));

%% ============================================================
T0_max = 2200;
P0_extra_loss = 0.95;
T0_T0star_5 = rayleigh_T0_T0star(M5, gamma);
T0star = T05 / T0_T0star_5;
T06 = min(T0_max, T0star);
target = T06 / T0star;
fM = @(M) rayleigh_T0_T0star(M, gamma) - target;

if abs(T06 - T0star) < 1e-8
    M6 = 0.999; % choked
else
    M6 = fzero(fM, [M5, 0.999]);
end

p_pstar_5   = rayleigh_p_pstar(M5, gamma);
T_Tstar_5   = rayleigh_T_Tstar(M5, gamma);
p0_p0star_5 = rayleigh_p0_p0star(M5, gamma);
p_pstar_6   = rayleigh_p_pstar(M6, gamma);
T_Tstar_6   = rayleigh_T_Tstar(M6, gamma);
p0_p0star_6 = rayleigh_p0_p0star(M6, gamma);
pstar = P5 / p_pstar_5;
Tstar = T5 / T_Tstar_5;
P6 = p_pstar_6 * pstar;
T6 = T_Tstar_6 * Tstar;
P06_rayleigh = P05 * (p0_p0star_6 / p0_p0star_5);
P06 = P0_extra_loss * P06_rayleigh;
q_add = cp*(T06 - T05); 

%% ===========================================================
Ae_At = Ae / At;
h = @(M) A_Astar(M) - Ae_At;
Me = fzero(h, [1.01, 10]);   % supersonic branch
Te = T06/(1 + (gamma-1)/2*Me^2);
ae = sqrt(gamma*R*Te);
Ve = Me*ae;
Pe = P06/(1 + (gamma-1)/2*Me^2)^(gamma/(gamma-1));  % isentropic to exit area

if Pe > P1
    nozzle_regime = "Underexpanded (Pe > Pambient)";
    Pe_for_thrust = Pe;        % keep pressure thrust
elseif Pe < P1
    nozzle_regime = "Overexpanded (Pe < Pambient) -> assume separated";
    Pe_for_thrust = P1;        % separation guard: pressure thrust ~ 0
else
    nozzle_regime = "Perfectly expanded (Pe = Pambient)";
    Pe_for_thrust = Pe;
end

%% ============================================================
rho1 = P1/(R*T1);
a1 = sqrt(gamma*R*T1);
V1 = M1*a1;
mdot = rho1 * V1 * A_capture;
Thrust = mdot*(Ve - V1) + (Pe_for_thrust - P1)*Ae;

%% ===========================================================
hcap = sqrt(A_capture);
Lw1 = hcap / tan(deg2rad(beta1));
Lw2 = hcap / tan(deg2rad(beta2));

%% ============================================================
fprintf('\n================ BONUS OFF-DESIGN (M1 = %.2f) ================\n', M1);
fprintf('\n--- Fixed Geometry ---\n');
fprintf('theta1=%.2f deg, theta2=%.2f deg\n', theta1, theta2);
fprintf('A4=%.6f, A5=%.6f, A6=%.6f, At=%.6f, Ae=%.6f (m^2)\n', A4,A5,A6,At,Ae);
fprintf('\n--- Intake (recomputed) ---\n');
fprintf('beta1=%.3f deg, beta2=%.3f deg\n', beta1, beta2);
fprintf('M2=%.4f, M3=%.4f, M4=%.4f\n', M2, M3, M4);
fprintf('P04/P01 = %.6f\n', P04_P01);
fprintf('Wedge lengths: L1=%.4f m, L2=%.4f m\n', Lw1, Lw2);
fprintf('\n--- Diffuser (fixed A5/A4) ---\n');
fprintf('A5/A4 = %.4f -> solved M5 = %.4f\n', A5_A4, M5);
fprintf('\n--- Combustor ---\n');
fprintf('T06 = %.2f K, P06 = %.2f Pa, M6 = %.4f\n', T06, P06, M6);
fprintf('q_add = %.2f kJ/kg\n', q_add/1000);
fprintf('\n--- Nozzle ---\n');
fprintf('Ae/At = %.4f -> Me = %.4f\n', Ae_At, Me);
fprintf('Pe (isentropic) = %.2f Pa, ambient = %.2f Pa\n', Pe, P1);
fprintf('Nozzle regime: %s\n', nozzle_regime);
fprintf('Te = %.2f K, Ve = %.2f m/s\n', Te, Ve);
fprintf('\n--- Performance ---\n');
fprintf('mdot = %.3f kg/s\n', mdot);
fprintf('Thrust = %.2f N\n', Thrust);
fprintf('=============================================================\n');

%% ==========================Functions==================================
function [ok,beta_deg,M2,P0out_P0in] = obliqueStage(M1,theta_deg,gamma,opts)
ok=false; beta_deg=NaN; M2=NaN; P0out_P0in=NaN;
theta = deg2rad(theta_deg);
theta_max = thetaMaxAttached(M1,gamma);
if theta >= theta_max, return; end
beta_min = asin(1/M1) + 1e-6;
beta_max = pi/2 - 1e-6;
f = @(beta) tan(theta) - 2*cot(beta).* ...
    ((M1^2*sin(beta).^2 - 1)./(M1^2*(gamma + cos(2*beta)) + 2));

try
    beta = fzero(f, (beta_min+beta_max)/2, opts);
catch
    return;
end

Mn1 = M1*sin(beta);
P0out_P0in = totalPressureRatioNormalShock(Mn1,gamma);
Mn2 = sqrt((1 + 0.5*(gamma-1)*Mn1^2)/(gamma*Mn1^2 - 0.5*(gamma-1)));
M2  = Mn2 / sin(beta - theta);
beta_deg = rad2deg(beta);
ok = true;
end

function theta_max=thetaMaxAttached(M,gamma)
bmin=asin(1/M)+1e-6; bmax=pi/2-1e-6;
b=linspace(bmin,bmax,5000);
theta=atan(2*cot(b).*((M^2*sin(b).^2-1)./(M^2*(gamma+cos(2*b))+2)));
theta_max=max(theta);
end

function P02_P01=totalPressureRatioNormalShock(M1,gamma)
p2_p1=1+2*gamma/(gamma+1)*(M1^2-1);
M2=downstreamMachNormalShock(M1,gamma);
P01=(1+0.5*(gamma-1)*M1^2)^(gamma/(gamma-1));
P02=p2_p1*(1+0.5*(gamma-1)*M2^2)^(gamma/(gamma-1));
P02_P01=P02/P01;
end

function M2=downstreamMachNormalShock(M1,gamma)
M2=sqrt((1+0.5*(gamma-1)*M1^2)/(gamma*M1^2-0.5*(gamma-1)));
end

function val=rayleigh_p_pstar(M,g)
val=(g+1)./(1+g*M.^2);
end

function val=rayleigh_T_Tstar(M,g)
val=((g+1).^2.*M.^2)./(1+g*M.^2).^2;
end

function val=rayleigh_T0_T0star(M,g)
T_Ts=rayleigh_T_Tstar(M,g);
val=T_Ts.*(1+(g-1)/2.*M.^2)./(1+(g-1)/2);
end

function val=rayleigh_p0_p0star(M,g)
p_ps=rayleigh_p_pstar(M,g);
val=p_ps.*((1+(g-1)/2.*M.^2).^(g/(g-1)))./((1+(g-1)/2).^(g/(g-1)));
end
