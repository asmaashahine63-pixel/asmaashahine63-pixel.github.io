%% ==================Full Project============================
clc; clear; close all;

gamma = 1.4;
R = 287;
cp = gamma*R/(gamma-1);

%% ==================================
M1 = 2.75;
P1 = 12.11e3;    
T1 = 216.5;       

%% ======================================
side_duct = 0.25;
A_duct = side_duct^2;   

%% ==================================================
theta1_range = 0.5:0.1:25;
theta2_range = 0.5:0.1:25;
opts = optimset('Display','off');
best.rec = -Inf;
for th1 = theta1_range
    [ok1,beta1,M2,P02_P01] = obliqueStage(M1,th1,gamma,opts);
    if ~ok1, continue; end
    for th2 = theta2_range
        [ok2,beta2,M3,P03_P02] = obliqueStage(M2,th2,gamma,opts);
        if ~ok2 || M3<=1, continue; end
        P04_P03 = totalPressureRatioNormalShock(M3,gamma);
        M4 = downstreamMachNormalShock(M3,gamma);
        rec = P02_P01 * P03_P02 * P04_P03;
        if rec > best.rec
            best = struct('theta1',th1,'theta2',th2,...
                          'beta1',beta1,'beta2',beta2,...
                          'M2',M2,'M3',M3,'M4',M4,'rec',rec);
        end
    end
end

%% --------
T01 = T1*(1+(gamma-1)/2*M1^2);
P01 = P1*(1+(gamma-1)/2*M1^2)^(gamma/(gamma-1));
T04 = T01;
P04 = best.rec * P01;
M4  = best.M4;
T4 = T04/(1+(gamma-1)/2*M4^2);
P4 = P04/(1+(gamma-1)/2*M4^2)^(gamma/(gamma-1));

%% ==================================================
M5 = 0.20;
T5 = T04/(1+(gamma-1)/2*M5^2);
P5 = P04/(1+(gamma-1)/2*M5^2)^(gamma/(gamma-1));
A5_A4 = (M4/M5)*((1+(gamma-1)/2*M5^2)/(1+(gamma-1)/2*M4^2))^((gamma+1)/(2*(gamma-1)));
A5 = A_duct;       
A6 = A5;            
A4 = A5 / A5_A4;    
A_capture = A5;
T05 = T04; 
P05 = P04;

%% ==================================================
T0_max = 2200;
P0_extra_loss = 0.95;
T0_T0star_5 = rayleigh_T0_T0star(M5,gamma);
T0star = T05/T0_T0star_5;
T06 = min(T0_max,T0star);
f = @(M) rayleigh_T0_T0star(M,gamma) - (T06/T0star);
M6 = fzero(f,[M5 0.999]);
p_pstar_5   = rayleigh_p_pstar(M5,gamma);
T_Tstar_5   = rayleigh_T_Tstar(M5,gamma);
p0_p0star_5 = rayleigh_p0_p0star(M5,gamma);
p_pstar_6   = rayleigh_p_pstar(M6,gamma);
T_Tstar_6   = rayleigh_T_Tstar(M6,gamma);
p0_p0star_6 = rayleigh_p0_p0star(M6,gamma);
pstar = P5/p_pstar_5;
Tstar = T5/T_Tstar_5;
P6 = p_pstar_6*pstar;
T6 = T_Tstar_6*Tstar;
P06_rayleigh = P05*(p0_p0star_6/p0_p0star_5);
P06 = P0_extra_loss * P06_rayleigh;
q_add = cp*(T06-T05);   % J/kg

%% ==================================================
Pa = P1;  
f = @(M) P06/(1+(gamma-1)/2*M.^2).^(gamma/(gamma-1)) - Pa;
Me = fzero(f,[1.01 8]);
Te = T06/(1+(gamma-1)/2*Me^2);
ae = sqrt(gamma*R*Te);
Ve = Me*ae;
A_ratio = @(M) (1./M).* ...
 ((2/(gamma+1))*(1+(gamma-1)/2*M.^2)).^((gamma+1)/(2*(gamma-1)));
Ae_At = A_ratio(Me);
rho1 = P1/(R*T1);
a1 = sqrt(gamma*R*T1);
V1 = M1*a1;
mdot = rho1 * V1 * A_capture;
mdot_per_At = (P06/sqrt(T06))*sqrt(gamma/R)* ...
              ((gamma+1)/2)^(-(gamma+1)/(2*(gamma-1)));
At = mdot / mdot_per_At;
Ae = Ae_At * At;
Thrust = mdot*(Ve - V1);

%% ==================================================
h = sqrt(A_capture); 
beta1 = deg2rad(best.beta1);
beta2 = deg2rad(best.beta2);
L1 = h / tan(beta1);
L2 = h / tan(beta2);

%% ==================================================
fprintf('\n================= INTAKE RESULTS =================\n');
fprintf('Theta1 = %.2f deg   Theta2 = %.2f deg\n',best.theta1,best.theta2);
fprintf('Beta1  = %.2f deg   Beta2  = %.2f deg\n',best.beta1,best.beta2);
fprintf('Wedge Length L1 = %.4f m\n',L1);
fprintf('Wedge Length L2 = %.4f m\n',L2);
fprintf('Total Pressure Recovery P04/P01 = %.6f\n',best.rec);

fprintf('\n================= AREAS =================\n');
fprintf('A4 (Intake exit / Diffuser inlet)   = %.6f m^2\n',A4);
fprintf('A5 (Diffuser exit / Combustor inlet)= %.6f m^2\n',A5);
fprintf('A6 (Combustor exit)                 = %.6f m^2\n',A6);
fprintf('At (Nozzle throat)                  = %.6f m^2\n',At);
fprintf('Ae (Nozzle exit)                    = %.6f m^2\n',Ae);
fprintf('Nozzle Area Ratio Ae/At             = %.4f\n',Ae_At);

fprintf('\n================= COMBUSTOR =================\n');
fprintf('Heat Added q = %.2f kJ/kg\n',q_add/1000);
fprintf('T06 = %.2f K\n',T06);
fprintf('P06 = %.2f Pa\n',P06);
fprintf('M6  = %.4f\n',M6);

fprintf('\n================= STATION TABLE =================\n');
fprintf('Station |   Mach   |    P (Pa)    |    T (K)\n');
fprintf('-------------------------------------------------\n');
fprintf('1  (Freestream)      %.3f   %.2f   %.2f\n',M1,P1,T1);
fprintf('4  (Intake Exit)     %.3f   %.2f   %.2f\n',M4,P4,T4);
fprintf('5  (Diffuser Exit)   %.3f   %.2f   %.2f\n',M5,P5,T5);
fprintf('6  (Combustor Exit)  %.3f   %.2f   %.2f\n',M6,P6,T6);
fprintf('e  (Nozzle Exit)     %.3f   %.2f   %.2f\n',Me,Pa,Te);

fprintf('\n================= FINAL PERFORMANCE =================\n');
fprintf('Mass Flow Rate = %.3f kg/s\n',mdot);
fprintf('Exit Velocity  = %.2f m/s\n',Ve);
fprintf('Net Thrust     = %.2f N\n',Thrust);
fprintf('=====================================================\n');

%% ====================FUNCTIONS==============================
function [ok,beta_deg,M2,P0out_P0in] = obliqueStage(M1,theta_deg,gamma,opts)
ok=false; beta_deg=NaN; M2=NaN; P0out_P0in=NaN;
theta = deg2rad(theta_deg);
theta_max = thetaMaxAttached(M1,gamma);
if theta>=theta_max, return; end
beta_min=asin(1/M1)+1e-6; beta_max=pi/2-1e-6;
f=@(b) tan(theta)-2*cot(b).*((M1^2*sin(b).^2-1)./(M1^2*(gamma+cos(2*b))+2));
try beta=fzero(f,(beta_min+beta_max)/2,opts); catch; return; end
Mn1=M1*sin(beta);
P0out_P0in=totalPressureRatioNormalShock(Mn1,gamma);
Mn2=sqrt((1+0.5*(gamma-1)*Mn1^2)/(gamma*Mn1^2-0.5*(gamma-1)));
M2=Mn2/sin(beta-theta);
beta_deg=rad2deg(beta);
ok=true;
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
