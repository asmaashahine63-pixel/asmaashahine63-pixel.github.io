clc; clear; close all;

% --- 1. Parameters and System Matrices ---
m1 = 300;
m2 = 45;
b1 = 2000;
b2 = 300;
k1 = 22500;
k2 = 200000;

% Your Derived A Matrix
A=[0                 1   0                                              0
  -(b1*b2)/(m1*m2)   0   ((b1/m1)*((b1/m1)+(b1/m2)+(b2/m2)))-(k1/m1)   -(b1/m1)
   b2/m2             0  -((b1/m1)+(b1/m2)+(b2/m2))                      1
   k2/m2             0  -((k1/m1)+(k1/m2)+(k2/m2))                      0];

% Your Derived B Matrix (2 columns: [Control_U, Road_Disturbance_W])
B=[0                 0
   1/m1              (b1*b2)/(m1*m2)
   0                -(b2/m2)
   (1/m1)+(1/m2)    -(k2/m2)];

C=[0 0 1 0];
D=[0 0];

% --- 2. Define Desired Poles ---
% Using the poles extracted from your handwritten characteristic equation
P = [-0.94574 + 0.71983i, -0.94574 - 0.71983i, -4.37424, -6.3338];

% --- 3. Calculate Gain K ---
% FIX: Use B(:,1) because the controller only acts through the first input
% Also added a controllability check to prevent errors
if rank(ctrb(A, B(:,1))) == size(A,1)
    K = acker(A, B(:,1), P);
    fprintf('Calculated Feedback Gain K:\n');
    disp(K);
else
    error('The system is not controllable with the provided A and B matrices.');
end