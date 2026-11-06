%% ==================Nozzle============================
clc; clear; close all;

gamma = 1.4;
R = 287;                 

%% --------------------------------
T06 = 2200.00;            
P06 = 210491.78;          

%% ---------------------------------
Pa = 12.11e3;             
Ta = 216.5;               

%% -------------------------------------
side_inlet = 0.25;         
A_inlet = side_inlet^2;    

%% ============================================================
f = @(M) P06 ./ (1 + (gamma-1)/2 .* M.^2).^(gamma/(gamma-1)) - Pa;
Me = fzero(f,[1.01 8]);

%% ============================================================
Te = T06 / (1 + (gamma-1)/2 * Me^2);
ae = sqrt(gamma*R*Te);
Ve = Me * ae;

%% ============================================================
A_ratio = @(M) (1./M).* ...
   ((2/(gamma+1))*(1+(gamma-1)/2*M.^2)).^((gamma+1)/(2*(gamma-1)));
Ae_At = A_ratio(Me);

%% ============================================================
M1 = 2.75;
T1 = Ta;
P1 = Pa;
rho1 = P1/(R*T1);
a1 = sqrt(gamma*R*T1);
V1 = M1*a1;
mdot = rho1 * V1 * A_inlet;

%% ============================================================
Thrust = mdot*(Ve - V1);

%% ============================================================
fprintf('================ NOZZLE RESULTS ================\n');
fprintf('Exit Mach number Me      = %.4f\n',Me);
fprintf('Exit static pressure Pe  = %.2f Pa\n',Pa);
fprintf('Exit static temperature  = %.2f K\n',Te);
fprintf('Exit velocity Ve         = %.2f m/s\n\n',Ve);

fprintf('Nozzle area ratio Ae/At  = %.4f\n',Ae_At);

fprintf('Mass flow rate m_dot     = %.3f kg/s\n',mdot);
fprintf('Net Thrust               = %.2f N\n',Thrust);
fprintf('================================================\n');
