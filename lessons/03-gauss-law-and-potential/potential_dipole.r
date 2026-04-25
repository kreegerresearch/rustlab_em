# potential_dipole.r — Dipole scalar potential and E = -∇V.
#
# Physical system:  ±q at (±d/2, 0) in vacuum.
# Potential:        V(x, y) = k_e p x / (x² + y²)^{3/2}  with  p = q d.
# Field recovered:  E = -∇V  via Lesson 01's `gradient` operator.
# Units:            SI (m, C, V, V/m).
#
# Lesson 03 — Gauss's Law & Electric Potential.

ke = 8.9875e9;
q  = 1e-9;
d  = 0.02;
p  = q * d;
L  = 0.05;
N  = 51;
xs = linspace(-L, L, N);
ys = linspace(-L, L, N);
[X, Y] = meshgrid(xs, ys);
dx = xs(2) - xs(1);
dy = ys(2) - ys(1);

# === Far-field dipole potential ===
# Bounded by ~ k_e p / dx² at the nearest-to-origin column (~45 V here), so
# no clipping needed — the 1e-12 floor on r² protects the (0,0) cell.
r3 = (X .^ 2 + Y .^ 2 + 1e-12) .^ 1.5;
V  = ke * p * X ./ r3;

figure();
hold on;
imagesc(V, "viridis");
contour(X, Y, V, 12, "k");
title("Dipole potential V(x, y)");
hold off;
savefig("potential_dipole_heatmap.svg");

# === Recover E = -∇V and compare to far-field at a clean test cell ===
[Vx, Vy] = gradient(V, dx, dy);
Ex_fromV = -Vx;
Ey_fromV = -Vy;

# Test cell at (x=0, y=0.04) — perpendicular bisector, far from charges.
# Far-field analytic:  E_x = -k_e p / y³.
print(real(Ex_fromV(46, 26)))     # ≈ -2812 V/m
print(real(Ey_fromV(46, 26)))     # ≈ 0  by symmetry
print(-ke * p / (0.04 ^ 3))       # closed-form check ≈ -2812 V/m

# === Plot the recovered field as a quiver overlay ===
figure();
quiver(X, Y, Ex_fromV, Ey_fromV, "Dipole field recovered as -∇V");
savefig("potential_dipole_quiver.svg");

print(1)
