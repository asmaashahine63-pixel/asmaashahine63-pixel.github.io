clc;
clear;
close all;


Ac = 5;                  
fc = 10e3;              


f1 = 200;               
f2 = 400;                

fs = 200e3;             
T  = 0.02;              
t  = 0:1/fs:T-1/fs;      

m = 2*cos(400*pi*t) + cos(800*pi*t);

m_max = max(m);
mn = m / m_max;

fprintf('Maximum of m(t) = %.4f\n', m_max);

Bm = max([f1 f2]);
fprintf('Message bandwidth Bm = %.1f Hz\n', Bm);


mu_values = [0.5 1 1.5];

for k = 1:length(mu_values)
    mu = mu_values(k);

    s = Ac * (1 + mu*mn) .* cos(2*pi*fc*t);

    figure;
    plot(t*1000, s, 'LineWidth', 1.2);
    grid on;
    xlabel('Time (ms)');
    ylabel('s(t) (V)');
    title(['AM Signal in Time Domain, \mu = ', num2str(mu)]);

    xlim([0 5]);
end

for k = 1:length(mu_values)
    mu = mu_values(k);

    s = Ac * (1 + mu*mn) .* cos(2*pi*fc*t);

    N = length(s);
    S = fftshift(fft(s));
    f = (-N/2:N/2-1)*(fs/N);

    figure;
    plot(f, abs(S)/N, 'LineWidth', 1.2);
    grid on;
    xlabel('Frequency (Hz)');
    ylabel('|S(f)|');
    title(['Magnitude Spectrum of AM Signal, \mu = ', num2str(mu)]);
    xlim([-12000 12000]);
end

BT = 2*Bm;
fprintf('Transmission bandwidth = %.1f Hz\n', BT);


Pc = Ac^2 / 2;
Pmn = mean(mn.^2);

fprintf('\nCarrier power Pc = %.6f W (for 1-ohm load)\n', Pc);
fprintf('Normalized message power Pmn = %.6f\n\n', Pmn);

for k = 1:length(mu_values)
    mu = mu_values(k);

    s = Ac * (1 + mu*mn) .* cos(2*pi*fc*t);

    Ptotal_num = mean(s.^2);
    Psb_num = Ptotal_num - Pc;
    eta_num = Psb_num / Ptotal_num;

    eta_theory = (mu^2 * Pmn) / (1 + mu^2 * Pmn);

    fprintf('mu = %.1f\n', mu);
    fprintf('  Theoretical efficiency = %.6f (%.2f%%)\n', eta_theory, eta_theory*100);
    fprintf('  Numerical efficiency   = %.6f (%.2f%%)\n', eta_num, eta_num*100);
    fprintf('  Total power            = %.6f W\n', Ptotal_num);
    fprintf('  Sideband power         = %.6f W\n\n', Psb_num);
end

fprintf('Minimum of normalized message mn(t) = %.6f\n', min(mn));
for k = 1:length(mu_values)
    mu = mu_values(k);
    env_min = min(1 + mu*mn);
    fprintf('mu = %.1f --> minimum envelope factor [1 + mu*mn(t)] = %.6f\n', mu, env_min);
end