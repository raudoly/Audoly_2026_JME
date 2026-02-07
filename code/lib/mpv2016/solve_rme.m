function rme = solve_rme(log_omega,  phi,  st,  p)
% Rank-Monotonic Equilibrium along a sequence of aggregate shocks

T = length(log_omega);

r = p.r*exp(p.elast_r_to_omega*log_omega);
b = p.b*exp(p.elast_b_to_omega*log_omega);
c0 = p.c0*exp(p.elast_c0_to_omega*log_omega);
delta = p.delta*exp(p.elast_delta_to_omega*log_omega);

beta = 1./(1 + r);

h = zeros(p.np, T);
q = zeros(p.np, T);
V = zeros(p.np, T);
w = zeros(p.np, T);

n = [st.n zeros(p.np, T)];
chi = zeros(p.np, T);

lambda_dF = zeros(p.np, T);

% Firm's choices along shock sequence
for t = 1:T
    
    % Firm's optimal policies
    [chi(:, t), V(:, t), h(:, t), lambda_dF(:, t), q(:, t)] = solve_firm_policy_shocks(phi(:, t), n(:, t), delta(t), c0(t), p);

    % Worker law of motion
    n(:, t+1) = chi(:, t).*((1 - q(:, t)).*(1 - delta(t)).*n(:,  t) + h(:, t));

end

% Fill in wages backward (approximation b/c no expectation over shock)
for t = T-1:-1:1
    w(:, t) = (1 - q(:, t+1)).*V(:, t+1) + p.s*(p.sum_ab*(V(:, t+1).*lambda_dF(:, t+1)));
    w(:, t) = (1 - delta(t+1))*chi(:, t+1).*w(:, t);
    w(:, t) = w(:, t) - sum(V(:, t+1).*lambda_dF(:, t+1));
    w(:, t) = V(:, t) + b(t) - beta(t)*w(:, t);
    w(:, t) = w(:, t).*chi(:, t); 
end

w(:, T) = w(:, T-1); 

rme.T = T;
rme.log_omega = log_omega;
rme.delta = delta;
rme.c0 = c0;
rme.omega = exp(log_omega);
% rme.b = b;
rme.chi = chi;
rme.h = h;
rme.q = q;
rme.lambda_dF = lambda_dF;
rme.phi = phi;
rme.w = w;
rme.n = n;
rme.dL = n.*p.dP;
    
