clc; clear; close all;

Fs = 500000;          
T = 0.02;            
t = 0:1/Fs:T-1/Fs;    

m = 2*cos(400*pi*t) + cos(800*pi*t);
Am = max(abs(m));     
fm = 400;             

Ac = 1;
fc = 20000;

kf_vals = [500 2000];

dt = 1/Fs;
m_int = cumsum(m)*dt;

for i = 1:length(kf_vals)
    kf = kf_vals(i);
    
    s_fm = Ac*cos(2*pi*fc*t + kf*m_int);
    
    figure;
    plot(t, s_fm, 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('s_{FM}(t)');
    title(['FM Signal, k_f = ' num2str(kf)]);
    grid on;
    
    N = length(s_fm);
    S_f = fftshift(fft(s_fm));
    f = (-N/2:N/2-1)*(Fs/N);
    
    figure;
    plot(f, abs(S_f)/N, 'LineWidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('|S(f)|');
    title(['Spectrum, k_f = ' num2str(kf)]);
    grid on;
    xlim([fc-15000 fc+15000]);
    
    delta_f = kf * Am / (2*pi);
    beta = delta_f / fm;
    BW_carson = 2*(delta_f + fm);
    
    threshold = 0.01*max(abs(S_f)/N);
    idx = find(abs(S_f)/N > threshold);
    BW_exp = f(max(idx)) - f(min(idx));
    
    fprintf('k_f = %d\n', kf);
    fprintf('Frequency deviation Δf = %.2f Hz\n', delta_f);
    fprintf('Modulation index β = %.2f\n', beta);
    fprintf('Experimental BW = %.2f Hz\n', BW_exp);
    fprintf('Carson BW = %.2f Hz\n\n', BW_carson);
end

kf_compare = 2000;                          
Delta_f_cmp = (kf_compare * Am)/(2*pi);
beta_cmp = Delta_f_cmp / fm;
kp_equal = beta_cmp / Am;                   

s_fm = Ac*cos(2*pi*fc*t + kf_compare*m_int);
s_pm = Ac*cos(2*pi*fc*t + kp_equal*m);

N = length(t);
f = (-N/2:N/2-1)*(Fs/N);
S_fm = fftshift(fft(s_fm));
S_pm = fftshift(fft(s_pm));

figure;
plot(f, abs(S_fm)/N, 'LineWidth', 1.5); hold on;
plot(f, abs(S_pm)/N, '--', 'LineWidth', 1.5);
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FM vs PM for Equal Peak Phase Deviation');
legend(['FM, k_f = ', num2str(kf_compare)], ...
       ['PM, k_p = ', num2str(kp_equal, '%.4f')], ...
       'Location', 'best');
xlim([-30000 30000]);

fprintf('FM vs PM Comparison:\n');
fprintf('FM: k_f = %d, beta = %.4f\n', kf_compare, beta_cmp);
fprintf('PM: k_p = %.4f (equal peak phase deviation)\n', kp_equal);