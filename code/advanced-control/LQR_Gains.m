clc; clear; close all;

%% ================= System Parameters =================
m1 = 300;
m2 = 45;
b1 = 2000;
b2 = 300;
k1 = 22500;
k2 = 200000;

%% ================= State-Space Matrices =================
A = [ 0                 1   0                                              0
     -(b1*b2)/(m1*m2)   0   ((b1/m1)*((b1/m1)+(b1/m2)+(b2/m2)))-(k1/m1)   -(b1/m1)
       b2/m2            0  -((b1/m1)+(b1/m2)+(b2/m2))                      1
       k2/m2            0  -((k1/m1)+(k1/m2)+(k2/m2))                      0 ];

B = [ 0                 
      1/m1              
      0                
      (1/m1)+(1/m2)   ];

%% ================= LQR Weighting =================
Q = diag([1e4, 1e2, 1e4, 1e2]);   % State weighting
R = 1;                            % Control weighting

%% ================= LQR Gain =================
K = lqr(A, B, Q, R);

%% ================= Display Result =================
disp('LQR Gain Matrix K = ');
disp(K);
