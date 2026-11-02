clc;
clear;
close all;

Ac = 5;                  
fc = 10e3;               

fs = 200e3;              
T  = 0.02;               
t  = 0:1/fs:T-1/fs;     

m = 2*cos(400*pi*t) + cos(800*pi*t);


m_max = max(m);
mn = m / m_max;

Bm = 400;               

mu_values = [0.5 1.5];

f_cut = 600;             
[b,a] = butter(6, f_cut/(fs/2));

for k = 1:length(mu_values)
    mu = mu_values(k);

    s = Ac * (1 + mu*mn) .* cos(2*pi*fc*t);

   
    env = abs(hilbert(s));
    mn_hat = (env/Ac - 1)/mu;

    mn_hat_f = filtfilt(b, a, mn_hat);

    m_hat = mn_hat_f * m_max;

    
    figure;
    plot(t*1000, s, 'b', 'LineWidth', 1);
    hold on;
    plot(t*1000, env, 'r', 'LineWidth', 1.5);
    plot(t*1000, -env, 'r', 'LineWidth', 1.5);
    grid on;
    xlabel('Time (ms)');
    ylabel('Amplitude');
    title(['AM Signal and Envelope, \mu = ', num2str(mu)]);
    legend('AM signal', 'Envelope', 'Location', 'best');
    xlim([0 5]);

   
    figure;
    plot(t*1000, mn, 'k', 'LineWidth', 1.5);
    hold on;
    plot(t*1000, mn_hat_f, '--', 'LineWidth', 1.5);
    grid on;
    xlabel('Time (ms)');
    ylabel('Amplitude');
    title(['Recovered Normalized Message, \mu = ', num2str(mu)]);
    legend('Original m_n(t)', 'Recovered m_n(t)', 'Location', 'best');
    xlim([0 20]);

   
    figure;
    plot(t*1000, m, 'k', 'LineWidth', 1.5);
    hold on;
    plot(t*1000, m_hat, '--', 'LineWidth', 1.5);
    grid on;
    xlabel('Time (ms)');
    ylabel('Amplitude');
    title(['Recovered Original Message, \mu = ', num2str(mu)]);
    legend('Original m(t)', 'Recovered m(t)', 'Location', 'best');
    xlim([0 20]);


    err = m - m_hat;
    mse = mean(err.^2);
    fprintf('mu = %.1f --> MSE = %.6e\n', mu, mse);

    env_factor_min = min(1 + mu*mn);
    fprintf('mu = %.1f --> minimum envelope factor = %.6f\n', mu, env_factor_min);
end