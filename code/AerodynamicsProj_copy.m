clc; clear; close all;

%% =======================
%  Joukowski Airfoil Model
%  Modified Parameters
%% =======================

% Flow conditions
V_inf = 125;              % Free-stream velocity (m/s)
c     = 1.25;             % Chord length (m)

% Airfoil geometry (UPDATED)
tc_ratio = 0.095;         % Max thickness ratio (9.5%)
hc_ratio = 0.03;          % Max camber ratio (3%)

% Angles of attack
alpha_plot  = 6;          % AoA for flow plots (deg)
alpha_sweep = -5:1:10;    % AoA sweep for Cl, Cm

%% =======================
%  Joukowski Parameters
%% =======================

b     = c/4;                          % Joukowski parameter
eps_t = tc_ratio / 1.3;               % Thickness control
beta  = 2 * hc_ratio;                 % Camber control (rad)
a     = b * (1 + eps_t) / cos(beta);  % Circle radius

% Cylinder center shift
x0 = -b * eps_t;
y0 =  a * beta;
z0 = x0 + 1i*y0;

%% =======================
%  Airfoil Geometry
%% =======================

theta = linspace(0,2*pi,450);
Zp    = a * exp(1i*theta);          % Circle (Z')
Z     = Zp + z0;                     % Shifted circle
z_af  = Z + b^2 ./ Z;                % Airfoil (Joukowski)

figure(1)
fill(real(z_af),imag(z_af),[0.85 0.85 0.85],'EdgeColor','k')
axis equal; grid on
xlabel('x (m)'); ylabel('y (m)')
title(sprintf('Joukowski Airfoil (t/c=9.5%%, h/c=3%%)'))
saveas(gcf,'Fig1_Geometry.png')

%% =======================
%  Flow Field & Streamlines
%% =======================

r_vals     = linspace(a,8*a,110);
theta_vals = linspace(0,2*pi,160);
[R,TH]     = meshgrid(r_vals,theta_vals);

Zp_grid = R .* exp(1i*TH);
Z_grid  = Zp_grid + z0;
Z1_grid = Z_grid + b^2 ./ Z_grid;

alpha = deg2rad(alpha_plot);
Gamma = 4*pi*V_inf*a*sin(alpha + beta);

% Velocity in Z' plane
Vr = V_inf .* cos(TH - alpha) .* (1 - a^2 ./ R.^2);
Vt = -V_inf .* ( sin(TH - alpha) .* (1 + a^2 ./ R.^2) ...
               + 2*(a./R).*sin(alpha + beta) );

dW_dZp = (Vr - 1i*Vt) .* exp(-1i*TH);
dZ1_dZp = 1 - b^2 ./ (Zp_grid + z0).^2;

V_complex = dW_dZp ./ dZ1_dZp;
V_mag = abs(V_complex);

% Stream function
W = V_inf*(Zp_grid*exp(-1i*alpha) + (a^2./Zp_grid)*exp(1i*alpha)) ...
    + 1i*Gamma/(2*pi)*log(Zp_grid./a);
Psi = imag(W);

% Rotate for visualization
rot = exp(-1i*alpha);
Z1r = Z1_grid * rot;
zafr = z_af * rot;

figure(2)
contour(real(Z1r),imag(Z1r),Psi,60,'LineWidth',1.1); hold on
fill(real(zafr),imag(zafr),'k')
axis equal; axis([-c c+0.5 -c c])
xlabel('x (m)'); ylabel('y (m)')
title(['Streamlines at \alpha = ',num2str(alpha_plot),'°'])
saveas(gcf,'Fig2_Streamlines.png')

figure(3)
contourf(real(Z1r),imag(Z1r),V_mag,50,'LineColor','none')
colorbar; hold on
fill(real(zafr),imag(zafr),'k')
axis equal; axis([-c c+0.5 -c c])
xlabel('x (m)'); ylabel('y (m)')
title('Velocity Magnitude')
saveas(gcf,'Fig3_Velocity.png')

%% =======================
%  Pressure Coefficient Cp
%% =======================

theta_s = linspace(0.15,2*pi-0.15,320);
Zps = a * exp(1i*theta_s);
Zs  = Zps + z0;
Z1s = Zs + b^2 ./ Zs;

Vt_s = -V_inf*(2*sin(theta_s - alpha) + 2*sin(alpha + beta));
dZ1_dZps = 1 - b^2 ./ Zs.^2;
V_surf = abs(Vt_s ./ abs(dZ1_dZps));

Cp = 1 - (V_surf./V_inf).^2;

figure(4)
plot(real(Z1s),Cp,'LineWidth',1.6)
set(gca,'YDir','reverse'); grid on
xlabel('x (m)'); ylabel('C_p')
title('Pressure Coefficient Distribution')
saveas(gcf,'Fig4_Cp.png')

%% =======================
%  Lift & Moment Coefficients
%% =======================

Cl_all = zeros(size(alpha_sweep));
Cm_all = zeros(size(alpha_sweep));

for n = 1:length(alpha_sweep)
    a_i = deg2rad(alpha_sweep(n));
    
    % Lift coefficient (analytical)
    Cl_all(n) = 2*pi*(1 + eps_t)*sin(a_i + beta);
    
    % Cp for moment
    Vt_i = -V_inf*(2*sin(theta_s - a_i) + 2*sin(a_i + beta));
    Vsi  = abs(Vt_i ./ abs(dZ1_dZps));
    Cp_i = 1 - (Vsi./V_inf).^2;
    
    x = real(Z1s); y = imag(Z1s);
    x_ref = -b;
    M = 0;
    
    for k = 1:length(x)-1
        dx = x(k+1)-x(k);
        dy = y(k+1)-y(k);
        cp_m = 0.5*(Cp_i(k)+Cp_i(k+1));
        xm = 0.5*(x(k)+x(k+1));
        ym = 0.5*(y(k)+y(k+1));
        
        dFx = -cp_m*dy;
        dFy =  cp_m*dx;
        M = M + (xm-x_ref)*dFy - ym*dFx;
    end
    
    Cm_all(n) = M/c;
end

figure(5)
plot(alpha_sweep,Cl_all,'-o','LineWidth',1.5)
grid on
xlabel('\alpha (deg)'); ylabel('C_l')
title('Lift Coefficient vs AoA')
saveas(gcf,'Fig5_Cl_alpha.png')

figure(6)
plot(alpha_sweep,Cm_all,'-s','LineWidth',1.5)
grid on
xlabel('\alpha (deg)'); ylabel('C_m')
title('Moment Coefficient vs AoA')
saveas(gcf,'Fig6_Cm_alpha.png')

disp('Simulation finished successfully.')
