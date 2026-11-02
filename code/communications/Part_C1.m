clc;
clear;
close all;


fs = 500e3;                 
T  = 0.02;                  
t  = 0:1/fs:T-1/fs;
dt = 1/fs;


m = 2*cos(400*pi*t) + cos(800*pi*t);
m_max = max(m);
mn = m / m_max;


Bm = 400;                  

SNR_dB_values = [20 10 5];

Ac_AM = 5;
fc_AM = 10e3;
mu = 1;                     

s_dsb_lc = Ac_AM * (1 + mu*mn) .* cos(2*pi*fc_AM*t);


s_dsb_sc = Ac_AM * m .* cos(2*pi*fc_AM*t);


Ac_FM = 1;
fc_FM = 20e3;
kf = 2000;                  

m_int = cumsum(m) * dt;
s_fm = Ac_FM * cos(2*pi*fc_FM*t + kf*m_int);


fcut_msg = 600;
[b_msg, a_msg] = butter(6, fcut_msg/(fs/2));

fcut_fm = 1000;
[b_fm, a_fm] = butter(6, fcut_fm/(fs/2));


fprintf('===============================================================\n');
fprintf('C1 - Noise Performance Comparison\n');
fprintf('===============================================================\n\n');

fprintf('%8s %12s %15s %15s\n', 'SNRin', 'Scheme', 'SNRout(dB)', 'MSE');
fprintf('---------------------------------------------------------------\n');

for ii = 1:length(SNR_dB_values)

    SNRin = SNR_dB_values(ii);

  
    r_lc = add_awgn_manual(s_dsb_lc, SNRin);

    env_lc = abs(hilbert(r_lc));

   
    mn_hat_lc = (env_lc/Ac_AM - 1) / mu;

    mn_hat_lc = filtfilt(b_msg, a_msg, mn_hat_lc);

    m_hat_lc = mn_hat_lc * m_max;

    alpha_lc = (m_hat_lc * m.') / (m_hat_lc * m_hat_lc.');
    m_hat_lc_aligned = alpha_lc * m_hat_lc;

    [snrout_lc, mse_lc] = calc_output_snr(m, m_hat_lc_aligned);
    fprintf('%8.1f %12s %15.4f %15.6e\n', SNRin, 'DSB-LC', snrout_lc, mse_lc);

   
    r_sc = add_awgn_manual(s_dsb_sc, SNRin);

    mixed_sc = r_sc .* cos(2*pi*fc_AM*t);
    m_hat_sc = (2/Ac_AM) * filtfilt(b_msg, a_msg, mixed_sc);

    alpha_sc = (m_hat_sc * m.') / (m_hat_sc * m_hat_sc.');
    m_hat_sc_aligned = alpha_sc * m_hat_sc;

    [snrout_sc, mse_sc] = calc_output_snr(m, m_hat_sc_aligned);
    fprintf('%8.1f %12s %15.4f %15.6e\n', SNRin, 'DSB-SC', snrout_sc, mse_sc);

  
    r_fm = add_awgn_manual(s_fm, SNRin);

    z = hilbert(r_fm);

    phi = unwrap(angle(z));

    finst = [diff(phi)/(2*pi*dt), 0];

    m_hat_fm = (2*pi/kf) * (finst - fc_FM);

    m_hat_fm = filtfilt(b_fm, a_fm, m_hat_fm);

    alpha_fm = (m_hat_fm * m.') / (m_hat_fm * m_hat_fm.');
    m_hat_fm_aligned = alpha_fm * m_hat_fm;

    [snrout_fm, mse_fm] = calc_output_snr(m, m_hat_fm_aligned);
    fprintf('%8.1f %12s %15.4f %15.6e\n', SNRin, 'WBFM', snrout_fm, mse_fm);

  
    figure;
    plot(t*1000, m, 'k', 'LineWidth', 1.5); hold on;
    plot(t*1000, m_hat_lc_aligned, '--', 'LineWidth', 1.1);
    plot(t*1000, m_hat_sc_aligned, '--', 'LineWidth', 1.1);
    plot(t*1000, m_hat_fm_aligned, '--', 'LineWidth', 1.1);
    grid on;
    xlabel('Time (ms)');
    ylabel('Amplitude');
    title(['Recovered Signals at Input SNR = ', num2str(SNRin), ' dB']);
    legend('Original m(t)', 'DSB-LC', 'DSB-SC', 'Wideband FM', 'Location', 'best');
    xlim([0 20]);

end

fprintf('---------------------------------------------------------------\n');


function y = add_awgn_manual(x, SNRdB)
    Px = mean(x.^2);
    SNRlin = 10^(SNRdB/10);
    Pn = Px / SNRlin;
    n = sqrt(Pn) * randn(size(x));
    y = x + n;
end

function [snr_out_dB, mse] = calc_output_snr(m, mhat)
    err = m - mhat;
    Ps = mean(m.^2);
    Pn = mean(err.^2);
    mse = Pn;
    snr_out_dB = 10*log10(Ps/Pn);
end