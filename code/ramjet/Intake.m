%% ==================Intake============================
clc; clear; close all;

%% ----------------------------------------
gamma = 1.4;
M1    = 2.75;              

theta1_range = 0.5 : 0.1 : 25;  
theta2_range = 0.5 : 0.1 : 25; 

opts_fzero = optimset('Display','off');

%% ---------------------------------------
best = struct('theta1',NaN,'theta2',NaN,'rec',-Inf,...
              'beta1',NaN,'beta2',NaN,'M2',NaN,'M3',NaN,'M4',NaN);

count_feasible = 0;

for theta1 = theta1_range
    [ok1, beta1, M2, P02_P01] = obliqueStage(M1, theta1, gamma, opts_fzero);
    if ~ok1, continue; end
    for theta2 = theta2_range
        [ok2, beta2, M3, P03_P02] = obliqueStage(M2, theta2, gamma, opts_fzero);
        if ~ok2, continue; end
        if M3 <= 1
            continue;
        end
        P04_P03 = totalPressureRatioNormalShock(M3, gamma);
        M4      = downstreamMachNormalShock(M3, gamma);
        recovery = P02_P01 * P03_P02 * P04_P03;
        count_feasible = count_feasible + 1;
        if recovery > best.rec
            best.theta1 = theta1;
            best.theta2 = theta2;
            best.rec    = recovery;
            best.beta1  = beta1;
            best.beta2  = beta2;
            best.M2     = M2;
            best.M3     = M3;
            best.M4     = M4;
        end
    end
end

%% ---------------------------------------
fprintf('================ OPTIMUM INTAKE DESIGN ================\n');
fprintf('Feasible designs checked: %d\n\n', count_feasible);

fprintf('Best theta1  = %.3f deg\n', best.theta1);
fprintf('Best theta2  = %.3f deg\n', best.theta2);
fprintf('Best beta1   = %.3f deg\n', best.beta1);
fprintf('Best beta2   = %.3f deg\n', best.beta2);
fprintf('Mach after shock 1 (M2) = %.4f\n', best.M2);
fprintf('Mach after shock 2 (M3) = %.4f\n', best.M3);
fprintf('Mach after normal shock (M4) = %.4f\n', best.M4);
fprintf('Total pressure recovery (P0,4/P0,1) = %.6f\n', best.rec);
fprintf('=======================================================\n');

%% ---------------------------------------
REC = nan(length(theta1_range), length(theta2_range));
for i = 1:length(theta1_range)
    th1 = theta1_range(i);
    [ok1, ~, M2, P02_P01] = obliqueStage(M1, th1, gamma, opts_fzero);
    if ~ok1, continue; end
    for j = 1:length(theta2_range)
        th2 = theta2_range(j);
        [ok2, ~, M3, P03_P02] = obliqueStage(M2, th2, gamma, opts_fzero);
        if ~ok2 || M3 <= 1, continue; end
        P04_P03 = totalPressureRatioNormalShock(M3, gamma);
        REC(i,j) = P02_P01 * P03_P02 * P04_P03;
    end
end

figure; 
contourf(theta2_range, theta1_range, REC, 30, 'LineColor','none');
colorbar; grid on;
xlabel('\theta_2 (deg)'); ylabel('\theta_1 (deg)');
title('Total Pressure Recovery P0,4 / P0,1');
hold on;
plot(best.theta2, best.theta1, 'wo', 'MarkerFaceColor','w', 'MarkerSize',7);
text(best.theta2, best.theta1, '  Optimum', 'Color','w', 'FontWeight','bold');
                    
%% =========================FUNCTIONS========================

function [ok, beta_deg, M2, P0out_P0in] = obliqueStage(M1, theta_deg, gamma, opts_fzero)
    ok = false; beta_deg = NaN; M2 = NaN; P0out_P0in = NaN;
    theta = deg2rad(theta_deg);
    theta_max = thetaMaxAttached(M1, gamma);
    if theta >= theta_max
        return;
    end

    beta_min = asin(1/M1) + 1e-6;
    beta_max = pi/2 - 1e-6;
    f = @(beta) tan(theta) - 2*cot(beta) .* ...
        ((M1^2*sin(beta).^2 - 1) ./ (M1^2*(gamma + cos(2*beta)) + 2));
    beta_guess = (beta_min + beta_max)/2;

    try
        beta = fzero(f, beta_guess, opts_fzero);
    catch
        return;
    end

    if ~(beta > beta_min && beta < beta_max)
        return;
    end

    Mn1 = M1*sin(beta);
    P0out_P0in = totalPressureRatioNormalShock(Mn1, gamma);
    Mn2 = sqrt((1 + 0.5*(gamma-1)*Mn1^2) / (gamma*Mn1^2 - 0.5*(gamma-1)));
    M2 = Mn2 / sin(beta - theta);
    beta_deg = rad2deg(beta);
    ok = (M2 > 0);
end

function theta_max = thetaMaxAttached(M, gamma)
    beta_min = asin(1/M) + 1e-6;
    beta_max = pi/2 - 1e-6;
    betas = linspace(beta_min, beta_max, 5000);
    thetas = atan( 2*cot(betas) .* ...
        ((M^2*sin(betas).^2 - 1) ./ (M^2*(gamma + cos(2*betas)) + 2)) );
    theta_max = max(thetas);
end

function P02_P01 = totalPressureRatioNormalShock(M1, gamma)
    p2_p1 = 1 + 2*gamma/(gamma+1) * (M1^2 - 1);
    rho2_rho1 = ((gamma+1)*M1^2) / ((gamma-1)*M1^2 + 2);
    T2_T1 = p2_p1 / rho2_rho1;
    M2 = downstreamMachNormalShock(M1, gamma);
    P01 = 1 * (1 + 0.5*(gamma-1)*M1^2)^(gamma/(gamma-1)); % normalized by p1=1
    P02 = p2_p1 * (1 + 0.5*(gamma-1)*M2^2)^(gamma/(gamma-1)); % normalized by p1=1
    P02_P01 = P02 / P01;
    if P02_P01 > 1
        P02_P01 = min(P02_P01, 1);
    end
end

function M2 = downstreamMachNormalShock(M1, gamma)
    M2 = sqrt((1 + 0.5*(gamma-1)*M1^2) / (gamma*M1^2 - 0.5*(gamma-1)));
end
