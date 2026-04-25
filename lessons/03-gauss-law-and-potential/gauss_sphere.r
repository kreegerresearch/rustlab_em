# gauss_sphere.r — Uniformly charged sphere via Gauss's law.
#
# Physical system:  ball of radius R with total charge Q in vacuum.
# Inside  (r ≤ R):  E_r = k_e Q r / R³,    V = k_e Q (3R² - r²) / (2R³)
# Outside (r ≥ R):  E_r = k_e Q / r²,      V = k_e Q / r
# Continuity at r = R:  E_r = k_e Q / R²,  V = k_e Q / R.
# Units:            SI (m, C, V/m, V).
#
# Lesson 03 — Gauss's Law & Electric Potential.

ke = 8.9875e9;
R  = 0.05;                    # 5 cm sphere radius
Q  = 1e-9;                    # 1 nC total charge

rs = linspace(0.001, 0.20, 400);
Er = zeros(length(rs));
Vr = zeros(length(rs));

for k = 1:length(rs)
  r = rs(k);
  if r <= R
    Er(k) = ke * Q * r / (R * R * R);
    Vr(k) = ke * Q * (3 * R * R - r * r) / (2 * R * R * R);
  else
    Er(k) = ke * Q / (r * r);
    Vr(k) = ke * Q / r;
  end
end

# === Sanity checks ===
print(Er(1))                  # ≈ 0   (linear in r near origin)
idx_R = argmin(abs(rs - R));
print(Er(idx_R))              # ≈ k_e Q / R² ≈ 3595 V/m at the surface
print(ke * Q / (R * R))       # closed form for the surface value
print(Vr(1))                  # ≈ 3 k_e Q / (2R) ≈ 269.6 V at center
print(ke * Q / R)             # surface potential ≈ 179.75 V

# === Plot E_r(r) ===
figure();
plot(rs * 100, Er, "Spherical charge:  E_r(r)");
xlabel("r (cm)");
ylabel("E_r (V/m)");
savefig("gauss_sphere_Er.svg");

# === Plot V(r) ===
figure();
plot(rs * 100, Vr, "Spherical charge:  V(r)");
xlabel("r (cm)");
ylabel("V (V)");
savefig("gauss_sphere_V.svg");

print(1)
