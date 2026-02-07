function [Z,Zprob] = tauchen_truncated(N,mu,rho,sig,m)
% Amended version of the Tauchen procedure for a large number of
% grid points with a relatively small grid. The distribution is
% truncated to avoid putting excess mass on the endpoints of the
% grid.

Z     = zeros(N,1);
Zprob = zeros(N,N);
a     = (1-rho)*mu;

Z(N)  = m * sqrt(sig^2 / (1 - rho^2));
Z(1)  = -Z(N);
zstep = (Z(N) - Z(1)) / (N - 1);

for i=2:(N-1)
    Z(i) = Z(1) + zstep * (i - 1);
end 

Z = Z + a / (1-rho);

for j = 1:N
    for k = 1:N
        Zprob(j,k) = cdf_normal((Z(k) - a - rho * Z(j) + zstep / 2) / sig) - ...
                     cdf_normal((Z(k) - a - rho * Z(j) - zstep / 2) / sig);
    end
    renorm = cdf_normal((Z(N) - a - rho * Z(j) + zstep / 2) / sig) - ...
             cdf_normal((Z(1) - a - rho * Z(j) - zstep / 2) / sig);
    Zprob(j,:) = Zprob(j,:)/renorm;
end


function c = cdf_normal(x)
	c = 0.5 * erfc(-x/sqrt(2));
