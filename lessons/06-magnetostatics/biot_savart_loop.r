# biot_savart_loop.r — Magnetic field of a single circular current loop.
#
# Geometry:   horizontal loop, radius R = 5 cm, current I = 1 A, in xy-plane.
# Method:     numerical Biot-Savart over N_seg loop segments, sampled on
#             a 41×41 meridional (x, z) grid (y = 0). Off-axis Bx and on-
#             axis Bz both come out; By = 0 by symmetry on the y = 0 slice.
# Verifies:   Bz(z) on the symmetry axis matches μ₀IR²/[2(R²+z²)^{3/2}].
#
# Reference: ../../notebooks/06-magnetostatics.md.

mu0   = 4 * pi * 1e-7;
Iloop = 1.0;
R     = 0.05;

# === Loop discretization ===
N_seg = 100;
phi   = linspace(0, 2*pi, N_seg + 1);
phi   = phi(1:N_seg);
rxs   = R * cos(phi);
rys   = R * sin(phi);
rzs   = zeros(N_seg);
dphi  = 2 * pi / N_seg;
dlx   = -R * sin(phi) * dphi;
dly   =  R * cos(phi) * dphi;
dlz   = zeros(N_seg);

# === Meridional grid (y = 0 slice) ===
Nm = 41;
xs = linspace(-0.10, 0.10, Nm);
zs = linspace(-0.10, 0.10, Nm);
Bxg = zeros(Nm, Nm);
Bzg = zeros(Nm, Nm);
for iz = 1:Nm
  for ix = 1:Nm
    fx = xs(ix); fy = 0.0; fz = zs(iz);
    bx = 0.0; bz = 0.0;
    for k = 1:N_seg
      Rxk = fx - rxs(k);
      Ryk = fy - rys(k);
      Rzk = fz - rzs(k);
      r2 = Rxk*Rxk + Ryk*Ryk + Rzk*Rzk;
      if r2 < 1e-10; r2 = 1e-10; end
      inv_r3 = 1.0 / (r2 ^ 1.5);
      bx = bx + (dly(k)*Rzk - dlz(k)*Ryk) * inv_r3;
      bz = bz + (dlx(k)*Ryk - dly(k)*Rxk) * inv_r3;
    end
    Bxg(iz, ix) = bx * mu0 * Iloop / (4 * pi);
    Bzg(iz, ix) = bz * mu0 * Iloop / (4 * pi);
  end
end

# === On-axis check at (x = 0, z = 0) ===
print(real(Bzg(21, 21)))                        # ≈ 1.257e-5 T
print(real(mu0 * Iloop / (2 * R)))              # closed form

# === Plots ===
figure();
quiver(xs, zs, real(Bxg), real(Bzg), "B in the meridional (x, z) plane");
xlabel("x (m)");
ylabel("z (m)");
savefig("loop_quiver.svg");

# On-axis Bz vs closed form along the z-axis (x = 0, ix = 21).
Bz_num = real(Bzg(:, 21));
Bz_an  = mu0 * Iloop * R^2 ./ (2 * (R^2 + zs .^ 2) .^ 1.5);
figure();
hold on;
plot(zs * 100, Bz_num, "On-axis Bz(z)");
plot(zs * 100, Bz_an);
hold off;
xlabel("z (cm)");
ylabel("Bz (T)");
legend("Numerical", "mu0 I R^2 / [2(R^2 + z^2)^(3/2)]");
savefig("loop_axis.svg");
