clc;
clear;
close all;


Ac = 5;                  
fc = 10e3;               

fs = 200e3;              
T  = 0.02;              
t  = 0:1/fs:T-1/fs;      

m = 2*cos(400*pi*t) + cos(800*pi*t);

Bm = 400;               

s = Ac * m .* cos(2*pi*fc*t);

figure;
plot(t*1000, s, 'LineWidth', 1.2);
grid on;
xlabel('Time (ms)');
ylabel('s(t)');
title('DSB-SC Signal in Time Domain');
xlim([0 5]);

N = length(s);
S = fftshift(fft(s));
f = (-N/2:N/2-1)*(fs/N);

figure;
plot(f, abs(S)/N, 'LineWidth', 1.2);
grid on;
xlabel('Frequency (Hz)');
ylabel('|S(f)|');
title('Magnitude Spectrum of DSB-SC Signal');
xlim([-12000 12000]);


f_cut = 600;                  
[b, a] = butter(6, f_cut/(fs/2));


r_ideal = s .* cos(2*pi*fc*t);
m_rec_ideal = (2/Ac) * filtfilt(b, a, r_ideal);

figure;
plot(t*1000, m, 'k', 'LineWidth', 1.5);
hold on;
plot(t*1000, m_rec_ideal, '--', 'LineWidth', 1.5);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title('Ideal Coherent Demodulation');
legend('Original m(t)', 'Recovered m(t)', 'Location', 'best');
xlim([0 20]);

theta_deg = 30;
theta = deg2rad(theta_deg);

r_phase = s .* cos(2*pi*fc*t + theta);
m_rec_phase = (2/Ac) * filtfilt(b, a, r_phase);

figure;
plot(t*1000, m, 'k', 'LineWidth', 1.5);
hold on;
plot(t*1000, m_rec_phase, '--', 'LineWidth', 1.5);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title(['Recovered Signal with Phase Error \theta = ', num2str(theta_deg), '^\circ']);
legend('Original m(t)', 'Recovered m(t)', 'Location', 'best');
xlim([0 20]);

df = 200;    
r_freq = s .* cos(2*pi*(fc + df)*t);
m_rec_freq = (2/Ac) * filtfilt(b, a, r_freq);

figure;
plot(t*1000, m, 'k', 'LineWidth', 1.5);
hold on;
plot(t*1000, m_rec_freq, '--', 'LineWidth', 1.5);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title(['Recovered Signal with Frequency Error f_c + ', num2str(df), ' Hz']);
legend('Original m(t)', 'Recovered m(t)', 'Location', 'best');
xlim([0 20]);


amp_loss_theoretical = cos(theta);
loss_percent = (1 - amp_loss_theoretical) * 100;

amp_ratio_num = rms(m_rec_phase) / rms(m_rec_ideal);

fprintf('===== DSB-SC Coherent Detection Results =====\n');
fprintf('Message bandwidth Bm = %.1f Hz\n', Bm);
fprintf('Transmission bandwidth for DSB-SC = %.1f Hz\n', 2*Bm);

fprintf('\nPhase error case:\n');
fprintf('Theta = %d degrees\n', theta_deg);
fprintf('Theoretical amplitude scaling = cos(theta) = %.6f\n', amp_loss_theoretical);
fprintf('Theoretical amplitude loss = %.2f %%\n', loss_percent);
fprintf('Numerical amplitude ratio (RMS) = %.6f\n', amp_ratio_num);

mse_ideal = mean((m - m_rec_ideal).^2);
mse_phase = mean((m - m_rec_phase).^2);
mse_freq  = mean((m - m_rec_freq).^2);

fprintf('\nMean Square Error (MSE):\n');
fprintf('Ideal demodulation      = %.6e\n', mse_ideal);
fprintf('With phase error        = %.6e\n', mse_phase);
fprintf('With frequency error    = %.6e\n', mse_freq);

figure;
plot(t*1000, m, 'k', 'LineWidth', 1.5); hold on;
plot(t*1000, m_rec_ideal, 'b--', 'LineWidth', 1.2);
plot(t*1000, m_rec_phase, 'r--', 'LineWidth', 1.2);
plot(t*1000, m_rec_freq, 'g--', 'LineWidth', 1.2);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title('Comparison of Coherent Demodulation Cases');
legend('Original m(t)', 'Ideal', 'Phase Error', 'Frequency Error', 'Location', 'best');
xlim([0 20]);