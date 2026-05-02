# solenoid_field.r — Finite solenoid: stack of loops, on-axis Bz.
#
# Geometry:   N_l = 50 loops of radius R = 2 cm spread uniformly over
#             length L = 10 cm. Current I = 1 A per turn.
# Theory:     interior B_z ≈ μ₀ n I (Ampère, infinite limit);
#             at the ends, B_z drops to ~half the peak.
#
# Reference: ../../notebooks/06-magnetostatics.md.

mu0  = 4 * pi * 1e-7;
Isol = 1.0;
Rs   = 0.02;
N_l  = 50;
L_s  = 0.10;
zs_l = linspace(-L_s/2, L_s/2, N_l);
N_seg = 60;
phi  = linspace(0, 2*pi, N_seg + 1);
phi  = phi(1:N_seg);
dphi = 2 * pi / N_seg;

# Sample Bz along the axis (x = y = 0).
zline = linspace(-0.10, 0.10, 121);
Bz_axis = zeros(length(zline));
for iz = 1:length(zline)
  fz_p = zline(iz);
  bz = 0.0;
  for li = 1:N_l
    z_loop = zs_l(li);
    for k = 1:N_seg
      sx = Rs * cos(phi(k));
      sy = Rs * sin(phi(k));
      Rxk = -sx; Ryk = -sy; Rzk = fz_p - z_loop;
      r2 = Rxk*Rxk + Ryk*Ryk + Rzk*Rzk;
      if r2 < 1e-10; r2 = 1e-10; end
      inv_r3 = 1.0 / (r2 ^ 1.5);
      dl_x = -Rs * sin(phi(k)) * dphi;
      dl_y =  Rs * cos(phi(k)) * dphi;
      bz = bz + (dl_x * Ryk - dl_y * Rxk) * inv_r3;
    end
  end
  Bz_axis(iz) = bz * mu0 * Isol / (4 * pi);
end

B_amp = mu0 * (N_l / L_s) * Isol;
print(real(Bz_axis(61)))          # centre of solenoid
print(B_amp)                      # μ₀ n I (infinite limit)

# Plot
figure();
hold on;
plot(zline * 100, real(Bz_axis), "Finite solenoid: on-axis Bz(z)");
plot([-L_s/2 * 100, L_s/2 * 100], [B_amp, B_amp]);
hold off;
xlabel("z (cm)");
ylabel("Bz (T)");
legend("Biot-Savart sum", "mu0 n I (infinite limit)");
savefig("solenoid_axis.svg");
