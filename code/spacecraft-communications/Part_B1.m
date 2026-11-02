clc; clear; close all;

Fs = 500000;
T = 0.02;
t = 0:1/Fs:T;

m = 2*cos(400*pi*t) + cos(800*pi*t);

Ac = 1;
fc = 20000;

kp_vals = [0.1 1 5];

fm = 400;
Am = max(abs(m));

for i = 1:length(kp_vals)
    kp = kp_vals(i);
    
    s = Ac*cos(2*pi*fc*t + kp*m);
    
    figure;
    plot(t, s, 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('s_{PM}(t)');
    title(['PM Signal, k_p = ' num2str(kp)]);
    grid on;
    
    N = length(s);
    S_f = fftshift(fft(s));
    f = (-N/2:N/2-1)*(Fs/N);
    
    figure;
    plot(f, abs(S_f)/N, 'LineWidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('|S(f)|');
    title(['Spectrum, k_p = ' num2str(kp)]);
    grid on;
    xlim([fc-5000 fc+5000]);
    
    beta = kp * Am;
    
    BW_carson = 2*(beta + 1)*fm;
    
    idx = find(abs(S_f)/N > 0.01*max(abs(S_f)/N));
    BW_est = f(max(idx)) - f(min(idx));
    
    fprintf('k_p = %.1f\n', kp);
    fprintf('Modulation index beta = %.3f\n', beta);
    fprintf('Estimated BW = %.2f Hz\n', BW_est);
    fprintf('Carson BW = %.2f Hz\n\n', BW_carson);
end