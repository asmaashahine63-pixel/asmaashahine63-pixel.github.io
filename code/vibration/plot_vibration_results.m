% Companion MATLAB plotter created for the portfolio from supplied spreadsheets.
% NOT original laboratory acquisition software or team-submitted source code.
% Run with current folder set to this script's directory, with CSV files alongside.
close all; clear; clc;
base = fileparts(mfilename('fullpath'));
if isempty(base), base = pwd; end
names = {'free-measured.csv','free-theoretical.csv'};
labels = {'Measured-parameter model','Theoretical model'};
figure('Name','Free vibration comparison'); hold on;
for i=1:2
  M = readmatrix(fullfile(base,names{i}));
  plot(M(:,1), M(:,8), 'DisplayName', labels{i});
end
xlabel('Time (s)'); ylabel('Displacement (m)'); title('Free vibration response'); legend('show'); grid on;
names = {'forced-trial1.csv','forced-trial2.csv','forced-theoretical.csv'};
labels = {'Measured trial 1','Measured trial 2','Theoretical'};
figure('Name','Forced vibration comparison'); hold on;
for i=1:3
  M = readmatrix(fullfile(base,names{i}));
  plot(M(:,4), M(:,3), '-o', 'DisplayName', labels{i});
end
xlabel('Frequency ratio r = omega/omega_n'); ylabel('Response ratio X/Y');
title('Forced vibration resonance'); legend('show'); grid on;
