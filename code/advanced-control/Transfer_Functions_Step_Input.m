clc; clear; close all;

%% ---------------- System Parameters ----------------
M1 = 300;
M2 = 45;
b1 = 2000;
b2 = 300;
K1 = 22500;
K2 = 200000;

%% ---------------- Transfer Functions ----------------
s = tf('s');
G1 = ((M1+M2)*s^2+b2*s+K2)/((M2*s^2+(b1+b2)*s+(K1+K2))*(M1*s^2+b1*s+K1)-(b1*s+K1)^2);
G2 = (-(M1*s^2)*(b2*s+K2))/((M2*s^2+(b1+b2)*s+(K1+K2))*(M1*s^2+b1*s+K1)-(b1*s+K1)^2);

%% ---------------- Step Responses ----------------
figure
step(G1)
grid on
title('Step Response of G_1 = (X_1 - X_2)/U')
ylabel('Suspension Deflection (m)')

figure
step(0.1*G2)
grid on
title('Step Response of G_2 = (X_1 - X_2)/W ,  W = 0.1 m')
ylabel('Suspension Deflection (m)')

%% ---------------- Performance Metrics ----------------
info_G1 = stepinfo(G1);
info_G2 = stepinfo(0.1*G2);

fprintf('\n===== G1 = (X1 - X2)/U =====\n');
fprintf('Settling Time     = %.3f s\n', info_G1.SettlingTime);
fprintf('Max Overshoot     = %.2f %%\n', info_G1.Overshoot);

fprintf('\n===== G2 = (X1 - X2)/W =====\n');
fprintf('Settling Time     = %.3f s\n', info_G2.SettlingTime);
fprintf('Max Overshoot     = %.2f %%\n', info_G2.Overshoot);

%% ---------------- Damped Frequencies ----------------
[wn1, zeta1] = damp(G1);
[wn2, zeta2] = damp(G2);

wd1 = wn1 .* sqrt(1 - zeta1.^2);
wd2 = wn2 .* sqrt(1 - zeta2.^2);

fprintf('\nDamped Frequencies (rad/s):\n');
fprintf('G1: %.2f  %.2f\n', wd1);
fprintf('G2: %.2f  %.2f\n', wd2);


