Number_of_bits_in_pulse = 10;                  
Number_of_pulses = 250;  
M_values = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024];
SNR_range = 0.5:0.25:65;

pulse = ones(1, Number_of_bits_in_pulse);
pulse = pulse / norm(pulse);  
Flipped_Pulse = fliplr(pulse);

for m = 1:length(M_values)
    M = M_values(m);
    
    RandomSignal = 2 * randi([0, M-1], 1, Number_of_pulses) - (M - 1);

    Fullsignal = zeros(1, Number_of_pulses * Number_of_bits_in_pulse);
    for i = 1:Number_of_pulses
        start_idx = (i-1)*Number_of_bits_in_pulse + 1;
        Fullsignal(start_idx:start_idx+Number_of_bits_in_pulse-1) = RandomSignal(i);
    end
    Fullsignal = Fullsignal / sqrt(Number_of_bits_in_pulse);

    bit_error_rate = zeros(1, length(SNR_range));
    for snr = 1:length(SNR_range)
        SNR = SNR_range(snr);
        
        noisy_signal = awgn(Fullsignal, SNR, 'measured');
        
        correlated_signal = conv(noisy_signal, Flipped_Pulse);
        
        correlated_symbol_samples = zeros(1, Number_of_pulses);
        for i = 1:Number_of_pulses
            sample_idx = i * Number_of_bits_in_pulse;
            correlated_symbol_samples(i) = correlated_signal(sample_idx);
        end

        num_errors = sum(abs(round(correlated_symbol_samples) - RandomSignal) > 1);
        symbol_error_rate(snr) = num_errors / Number_of_pulses;

        tx_bits = de2bi((RandomSignal + (M - 1)) / 2, log2(M), 'left-msb');
        valid_levels = -M+1 : 2 : M-1;
        [~, idx] = min(abs(correlated_symbol_samples' - valid_levels), [], 2);
        rx_symbols = valid_levels(idx)';
        rx_indices = (rx_symbols + (M - 1)) / 2;
        rx_indices = max(0, min(M-1, round(rx_indices)));
        rx_bits = de2bi(rx_indices, log2(M), 'left-msb');
        num_bit_errors = sum(tx_bits(:) ~= rx_bits(:));
        bit_error_rate(snr) = num_bit_errors / (Number_of_pulses * log2(M));
    end

    SER_results{m} = symbol_error_rate;
    BER_results{m} = bit_error_rate;

    % Plot transmitted signal
    figure, plot(Fullsignal);
    xlabel('Time'); ylabel('Amplitude'); title([num2str(M) '-PAM Transmitted Signal']);    
    % Plot SER and BER vs SNR
    figure; plot(SNR_range, symbol_error_rate, 'b-', SNR_range, bit_error_rate, 'r-', 'LineWidth', 1.5);
    xlabel('SNR (dB)'), ylabel('Error Rate'), title([num2str(M) '-PAM: SER and BER']), legend('SER','BER','Location','southwest'), grid on;
end

figure, hold on
cellfun(@(ser) semilogy(SNR_range, ser, 'LineWidth', 1.5), SER_results);
legend(arrayfun(@(M) [num2str(M) 'PAM'], M_values, 'UniformOutput', false), 'Location', 'northeast');
xlabel('SNR (dB)'), ylabel('Symbol Error Rate (SER)'), title('SER vs SNR for different PAM levels'), grid on, hold off

figure, hold on
cellfun(@(ber) semilogy(SNR_range, ber, 'LineWidth', 1.5), BER_results);
legend(arrayfun(@(M) [num2str(M) 'PAM'], M_values, 'UniformOutput', false), 'Location', 'northeast');
xlabel('SNR (dB)'), ylabel('Bit Error Rate (BER)'), title('BER vs SNR for different PAM levels'), grid on, hold off