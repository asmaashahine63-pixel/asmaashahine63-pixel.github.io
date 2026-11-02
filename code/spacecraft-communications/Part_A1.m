clc;
clear;
close all;

fs = 10000;             
T  = 0.02;               
t  = 0:1/fs:T-1/fs;      

m = 2*cos(400*pi*t) + cos(800*pi*t);

figure;
plot(t, m, 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('m(t)');
title('Message Signal in Time Domain');


N = length(m);                  
M = fft(m);                    
M_shifted = fftshift(M);        


f = (-N/2:N/2-1)*(fs/N);

figure;
plot(f, abs(M_shifted)/N, 'LineWidth', 1.5);
grid on;
xlabel('Frequency (Hz)');
ylabel('|M(f)|');
title('Magnitude Spectrum of m(t)');
xlim([-1000 1000]);


f1 = 200;   
f2 = 400;   

Bm = max(f1, f2);

fprintf('Message Bandwidth = %d Hz\n', Bm);