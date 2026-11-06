%% ==================Diffuser============================

clc; clear; close all;

gamma = 1.4;

%% ------------------
M4  = 0.7250;                
P04_P01 = 0.808695;          
P1 = 12.11e3;                
T1 = 216.5;                  
M1 = 2.75;

%% -------------------
T01 = T1*(1 + (gamma-1)/2*M1^2);
P01 = P1*(1 + (gamma-1)/2*M1^2)^(gamma/(gamma-1));

%% -------------------
P04 = P04_P01 * P01;
T04 = T01;   

%% ============================================================
M5 = 0.20;    % Typical subsonic diffuser exit Mach

%% -------------------
T4 = T04 / (1 + (gamma-1)/2*M4^2);
P4 = P04 / (1 + (gamma-1)/2*M4^2)^(gamma/(gamma-1));

%% ------------------
T5 = T04 / (1 + (gamma-1)/2*M5^2);
P5 = P04 / (1 + (gamma-1)/2*M5^2)^(gamma/(gamma-1));

%% -------------------
A5_A4 = (M4/M5)* ...
    ((1 + (gamma-1)/2*M5^2)/(1 + (gamma-1)/2*M4^2))^((gamma+1)/(2*(gamma-1)));

%% ============================================================
fprintf('================ DIFFUSER RESULTS ================\n');
fprintf('Inlet Mach (after intake)      M4 = %.4f\n',M4);
fprintf('Exit Mach (combustor entry)    M5 = %.4f\n\n',M5);
fprintf('Total Pressure (constant)      P04 = %.2f Pa\n',P04);
fprintf('Total Temperature (constant)   T04 = %.2f K\n\n',T04);
fprintf('Static Pressure at diffuser inlet  P4 = %.2f Pa\n',P4);
fprintf('Static Pressure at diffuser exit   P5 = %.2f Pa\n\n',P5);
fprintf('Static Temperature at inlet  T4 = %.2f K\n',T4);
fprintf('Static Temperature at exit   T5 = %.2f K\n\n',T5);
fprintf('Required Area Ratio A5/A4 = %.4f\n',A5_A4);
fprintf('==================================================\n');
