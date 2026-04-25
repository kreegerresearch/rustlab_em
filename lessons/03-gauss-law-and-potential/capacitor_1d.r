# capacitor_1d.r — Parallel-plate capacitor in 1-D from Gauss's law.
#
# Physical system:  two infinite parallel plates with surface charge ±σ,
#                   separated by gap d, vacuum between.
# Closed forms:     E = σ/ε₀  inside the gap  (zero outside)
#                   V = E·d  across the gap; linear ramp
#                   C = ε₀ A / d
# Units:            SI throughout.
#
# Lesson 03 — Gauss's Law & Electric Potential.

eps0 = 8.8541878128e-12;     # F/m
A    = 0.01;                 # 100 cm² plate area
d    = 0.01;                 # 1 cm gap
Q    = 1e-9;                 # 1 nC stored charge

sigma = Q / A;
E_in  = sigma / eps0;
V0    = E_in * d;
C     = eps0 * A / d;

print(sigma)                 # 1e-7 C/m²
print(E_in)                  # ≈ 11293 V/m
print(V0)                    # ≈ 113 V
print(C)                     # ≈ 8.854e-12 F = 8.854 pF
print(Q / V0)                # ≈ same as C — independent check

# === Plot E_z(z) and V(z) across the gap ===
zs = linspace(-0.005, 0.015, 401);
Ez = zeros(length(zs));
Vz = zeros(length(zs));

for k = 1:length(zs)
  z = zs(k);
  if z > 0 && z < d
    Ez(k) = E_in;
    Vz(k) = V0 * (1 - z / d);
  elseif z <= 0
    Ez(k) = 0;
    Vz(k) = V0;
  else
    Ez(k) = 0;
    Vz(k) = 0;
  end
end

figure();
plot(zs * 1000, Ez, "Capacitor E_z(z) across the gap");
xlabel("z (mm)");
ylabel("E_z (V/m)");
savefig("capacitor_1d_E.svg");

figure();
plot(zs * 1000, Vz, "Capacitor V(z) across the gap");
xlabel("z (mm)");
ylabel("V (V)");
savefig("capacitor_1d_V.svg");

print(1)
