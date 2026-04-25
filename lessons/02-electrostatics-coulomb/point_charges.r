# point_charges.r — Electric field of point-charge configurations.
#
# Physical system:  point charges in vacuum on a 2-D slice; superposition.
# Configurations:   dipole  (±q at  ±d/2 along x)
#                   quadrupole  (+q at (±d, 0); -q at (0, ±d))
# Key equation:     E(r) = k_e Σ q_i (r - r_i) / |r - r_i|^3
# Units:            SI throughout (m, C, V/m).
# Constants:        k_e = 1/(4πε₀) = 8.9875e9 N·m²/C².
#
# Lesson 02 — Electrostatics & Coulomb's Law.

# === Constants and grid ===
ke    = 8.9875e9;
q     = 1e-9;                     # 1 nC
d     = 0.02;                     # 2 cm
L     = 0.05;                     # half-domain (m)
N     = 51;
xs    = linspace(-L, L, N);
ys    = linspace(-L, L, N);
[X, Y] = meshgrid(xs, ys);

# === 1. Dipole:  +q at (+d/2, 0),  -q at (-d/2, 0) ===
Ex_d = zeros(size(X));
Ey_d = zeros(size(X));

# +q charge
rx = X - d / 2;
ry = Y;
r3 = (rx .^ 2 + ry .^ 2 + 1e-12) .^ 1.5;
Ex_d += ke *  q  * rx ./ r3;
Ey_d += ke *  q  * ry ./ r3;

# -q charge
rx = X + d / 2;
ry = Y;
r3 = (rx .^ 2 + ry .^ 2 + 1e-12) .^ 1.5;
Ex_d += ke * (-q) * rx ./ r3;
Ey_d += ke * (-q) * ry ./ r3;

# Field at the midpoint between the charges:  E_x = -8 k_e q / d².
# Wrap with real() because matrix `./` in rustlab stores complex internally;
# the imaginary part here is float-precision noise (~1e-11 relative).
print(real(Ex_d(26, 26)))         # ≈ -179750 V/m
print(real(Ey_d(26, 26)))         # ≈ 0  by symmetry

figure();
quiver(X, Y, Ex_d, Ey_d, "Dipole:  +q at (+d/2, 0),  -q at (-d/2, 0)");
savefig("point_charges_dipole_quiver.svg");

figure();
Emag_d = sqrt(Ex_d .* Ex_d + Ey_d .* Ey_d);
imagesc(log10(Emag_d), "viridis");
title("log_{10} |E|  for the dipole");
savefig("point_charges_dipole_magnitude.svg");

# === 2. Quadrupole:  +q at (±d, 0),  -q at (0, ±d) ===
charges = [  q,  d,  0;
             q, -d,  0;
            -q,  0,  d;
            -q,  0, -d ];

Ex_q = zeros(size(X));
Ey_q = zeros(size(X));
for k = 1:size(charges, 1)
  qk = charges(k, 1);
  xk = charges(k, 2);
  yk = charges(k, 3);
  rx = X - xk;
  ry = Y - yk;
  r3 = (rx .^ 2 + ry .^ 2 + 1e-12) .^ 1.5;
  Ex_q += ke * qk * rx ./ r3;
  Ey_q += ke * qk * ry ./ r3;
end

# At the origin, the four charges produce E = 0 by symmetry.
print(real(Ex_q(26, 26)))         # ≈ 0
print(real(Ey_q(26, 26)))         # ≈ 0

figure();
quiver(X, Y, Ex_q, Ey_q, "Quadrupole:  +q on x-axis, -q on y-axis (each at distance d)");
savefig("point_charges_quadrupole_quiver.svg");

figure();
Emag_q = sqrt(Ex_q .* Ex_q + Ey_q .* Ey_q);
imagesc(log10(Emag_q), "viridis");
title("log_{10} |E|  for the quadrupole");
savefig("point_charges_quadrupole_magnitude.svg");

print(1)
