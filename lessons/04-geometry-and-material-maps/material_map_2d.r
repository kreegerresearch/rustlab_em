# material_map_2d.r — Air + FR-4 substrate + copper disk.
#
# Builds three synchronized ny×nx arrays — eps_r, mu_r, sigma — using the
# layered-overwrite idiom:
#
#   eps_r ← eps_r .* (1 - layer) + eps_layer * layer
#
# This is the input format every grid-based EM solver from Lesson 05 onward
# consumes directly. See ../../notebooks/04-geometry-and-material-maps.md.

# === Grid ===
N      = 200;
[X, Y] = meshgrid(linspace(-1.5, 1.5, N), linspace(-1.5, 1.5, N));

# === Geometry ===
substrate = rect_mask(X, Y, -1.2, -0.3, 2.4, 0.6);
metal     = disk_mask(X, Y, 0.4, 0.0, 0.25);

# === Material parameters (SI; ε_r and μ_r are dimensionless) ===
eps_air = 1.0;     mu_air = 1.0;   sig_air = 0.0;
eps_sub = 4.4;     mu_sub = 1.0;   sig_sub = 0.0;       # FR-4
eps_met = 1.0;     mu_met = 1.0;   sig_met = 5.8e7;     # copper

# === Layered overwrite: vacuum first, then substrate, then metal on top ===
eps_r = eps_air * ones(N, N);
eps_r = eps_r .* (1 - substrate) + eps_sub * substrate;
eps_r = eps_r .* (1 - metal)     + eps_met * metal;

mu_r  = mu_air  * ones(N, N);
mu_r  = mu_r  .* (1 - substrate) + mu_sub  * substrate;
mu_r  = mu_r  .* (1 - metal)     + mu_met  * metal;

sigma = sig_air * ones(N, N);
sigma = sigma .* (1 - substrate) + sig_sub * substrate;
sigma = sigma .* (1 - metal)     + sig_met * metal;

# === Plots ===
figure();
imagesc(eps_r, "viridis");
title("eps_r(x, y): air = 1, FR-4 = 4.4, copper disk overwrites");
savefig("eps_map.svg");

figure();
imagesc(sigma, "viridis");
title("sigma(x, y): zero everywhere except the copper disk");
savefig("sigma_map.svg");

# === Sanity check by sampling one cell from each region ===
# Indexing: row = y-index, col = x-index (rustlab is 1-based).
# Disk centre (x=0.4, y=0)  →  col ≈ N*(0.4 + 1.5)/3.0 + 1 ≈ 128, row = 100.
# Substrate-only cell: (x = -1.0, y = 0)  →  col ≈ 34, row = 100.
# Air cell: (x = 0, y = 1.0)  →  col = 100, row ≈ 167.
print(eps_r(100, 128))      # copper disk → 1.0 (metal overwrote substrate)
print(eps_r(100,  34))      # substrate only → 4.4
print(eps_r(167, 100))      # air → 1.0
print(sigma(100, 128))      # copper conductivity → 5.8e7
print(sigma(100,  34))      # lossless dielectric → 0
print(mu_r(100, 128))       # non-magnetic everywhere → 1.0
