# laplace_2d.r — Laplace equation on a unit square via direct sparse solve.
#
# PDE:        ∇²V = 0  on (0,1)²
# Boundary:   V(x, 0) = V(0, y) = V(1, y) = 0;   V(x, 1) = sin(π x)
# Analytic:   V(x, y) = sin(π x) sinh(π y) / sinh(π)
# Method:     interior-only grid; Dirichlet boundary contributions
#             added to the right-hand side; spsolve picks Cholesky.
#
# Reference: ../../notebooks/05-poisson-laplace-bvp.md.

# === Grid ===
N  = 41;
h  = 1.0 / (N + 1);
xs = h * (1:N);
ys = h * (1:N);
[X, Y] = meshgrid(xs, ys);

# === Assembly: -∇² V = b ===
L = laplacian_2d(N, N, h, h);
A = -1 * L;

# Boundary contribution: top row sees a missing V_top neighbour. The
# matrix L treats the virtual cell outside the grid as 0; the missing
# +V_top/h² flux moves to the RHS.
b_bc = zeros(N, N);
for j = 1:N
  b_bc(N, j) = sin(pi * xs(j)) / (h * h);
end
b = b_bc(:)';

V_flat = spsolve(A, b);
V = reshape(V_flat, N, N);

# === Plots ===
figure();
hold on;
imagesc(real(V), "viridis");
contour(X, Y, real(V), 10, "k");
title("Laplace V(x, y) — V_top = sin(pi x), other edges 0");
hold off;
savefig("laplace_2d_field.svg");

# === Verification against analytic separation-of-variables solution ===
V_an = sin(pi * X) .* sinh(pi * Y) / sinh(pi);
err = abs(V - V_an);
i_mid = 20;
print(real(V(i_mid, i_mid)))         # ≈ 0.183 (x ≈ y ≈ 0.476)
print(V_an(i_mid, i_mid))            # ≈ 0.183
print(real(max(err(:))))             # ≈ 1.6e-4 — well below (1/42)² ≈ 6e-4
