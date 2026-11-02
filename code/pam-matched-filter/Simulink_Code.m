clear; clc; close all;

SNR = 0:2:20;                  

M = 8;                             
Bits_per_Symbol = log2(M);                       

assignin('base', 'M', M);
assignin('base', 'bps', Bits_per_Symbol);

pamSyms = pammod(0:M-1, M);
avgEnergy = mean(abs(pamSyms).^2);

Measured_BER = zeros(size(SNR));
Measured_SER = zeros(size(SNR));
Expected_BER = zeros(size(SNR));
Expected_SER = zeros(size(SNR));

for s = 1:length(SNR)
    snr_db = SNR(s);
    assignin('base', 'snr_db', snr_db);

    simOut = sim('Simulink_Simulation', 'StopTime', '1000', 'SrcWorkspace', 'base', 'SaveOutput', 'on');

    BER_array = simOut.get('BER_output');   
    SER_array = simOut.get('SER_output');

    Measured_BER(s) = BER_array(end, 1);     
    Measured_SER(s) = SER_array(end, 1);

    % Computing Theoretical BER and SER
    EbN0 = 10^(snr_db / 10) / bps;

    Expected_BER(s) = (2 * (M - 1)) / (M * bps) * ...
                      qfunc(sqrt((6 * bps / (M^2 - 1)) * EbN0));

    Expected_SER(s) = 2 * (M - 1) / M * ...
                      qfunc(sqrt((6 * bps / (M^2 - 1)) * EbN0));
end

% Plotting BER and SER
figure('Name', sprintf('%d-PAM BER & SER vs. SNR', M));
semilogy(SNR, Measured_BER, 'bo-', 'LineWidth', 2);hold on;
semilogy(SNR, Expected_BER, 'b--', 'LineWidth', 1.8);
semilogy(SNR, Measured_SER, 'rs-', 'LineWidth', 2);
semilogy(SNR, Expected_SER, 'r--', 'LineWidth', 1.8);
grid on;
xlabel('SNR (dB)', 'FontSize', 12);
ylabel('Error Rate', 'FontSize', 12);
title(sprintf('%d-PAM BER & SER vs. SNR: Simulink vs. Theory', M), 'FontSize', 14);
legend({'Simulink BER', 'Theory BER', 'Simulink SER', 'Theory SER'},'Location', 'southwest');