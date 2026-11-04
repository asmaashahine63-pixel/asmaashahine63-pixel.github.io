import numpy as np
import matplotlib.pyplot as plt

# Domain parameters
Lx, Ly = 1.0, 1.0  # Wall dimensions in meters
Nx, Ny = 100, 100  # Number of grid points
dx = Lx / (Nx - 1)
dy = Ly / (Ny - 1)
Lambda = 1.8  # Relaxation factor
tolerance = 1e-6
max_iter = 10000

# Temperature boundary conditions
T_x_0 = 100.0  # x=0
T_x_Lx = 0.0  # x=L_x
T_y_0 = 25.0   # y=0
T_y_Ly = 75.0  # y=L_y

# Initialize temperature grid
T = np.zeros((Ny, Nx))
T[:, 0] = T_x_0
T[:, -1] = T_x_Lx
T[0, :] = T_y_0
T[-1, :] = T_y_Ly

# Iterative solver: SOR
for iteration in range(max_iter):
    T_old = T.copy()

    for j in range(1, Ny - 1):
        for i in range(1, Nx - 1):
            T[j, i] = (1 - Lambda) * T[j, i] + (Lambda / 4) * (
                    T[j, i + 1] + T[j, i - 1] + T[j + 1, i] + T[j - 1, i]
            )

    # Neumann BCs: zero flux (top and bottom)
    T[0, :] = T_x_0
    T[-1, :] = T_x_Lx
    T[0, :] = T_y_0
    T[-1, :] = T_y_Ly

    # Convergence check
    if np.max(np.abs(T - T_old)) < tolerance:
        print(f'Converged in {iteration} iterations.')
        break

# Plot results
plt.figure(figsize=(8, 6))
cp = plt.contourf(T, 100, cmap='inferno')
plt.title('Temperature Distribution in Insulated Wall')
plt.xlabel('Width (x)')
plt.ylabel('Height (y)')
plt.colorbar(cp, label='Temperature (°C)')
plt.show()