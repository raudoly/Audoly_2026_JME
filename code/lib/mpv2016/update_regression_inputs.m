function [X, y] = update_regression_inputs(theta,  ks,  st,  p)
% Update regressors and regressands conditional on candidate
% parametrization of net surplus: matrix of coefficients
% 'theta'.

% Allocate memory
X = zeros(1+ks.nm, ks.T+1);
y = zeros(p.np+1, ks.T);
n = [st.n, zeros(p.np, ks.T)];

% Pre-allocate arrays
stS_n = repmat(st.S, 1, ks.ns);
stU_n = repmat(st.U, 1, ks.ns);
dP_n = repmat(p.dP, 1, ks.ns);
h_n = zeros(p.np, ks.ns);

% Simulate measure of workers forward
for t = 1:ks.T

    % Net surplus given states
    X_t = [ks.sim_log_omega_poly(:, t); X(:, t)];
    y_t = theta*X_t;
    S_t = exp(y_t(1:p.np, 1)).*st.S;
    U_t = exp(y_t(p.np+1, 1))*st.U;

    phi_t = S_t - U_t;

    % Get firm optimal policies
    [chi_t, ~, h_t, ~, q_t] = solve_firm_policy_shocks(phi_t, n(:, t), ks.sim_delta(t), ks.sim_c0(t), p);

    % Update measure of workers given these policies
    n(:, t+1) = chi_t.*((1 - q_t).*(1 - ks.sim_delta(t)).*n(:, t) + h_t);
    X(:, t+1) = build_endogenous_regressors(n(:, t+1).*p.dP, ks, p);

end

% Update value functions backward. All variables with suffix "_n"
% below are for each grid point of the aggregate shock,  where
% each column correponds to a different grid point.
for t = ks.T:-1:1

    X_n = [ks.log_omega_nodes; repmat(X(:, t+1), 1, ks.ns)];
    n_n = repmat(n(:, t+1), 1, ks.ns);

    % Value functions
    y_n = theta*X_n;
    S_n = exp(y_n(1:p.np, :)).*stS_n;
    U_n = exp(y_n(p.np+1, :)).*stU_n;

    phi_n = S_n - U_n;

    % Optimal policies
    chi_n = phi_n>=0.0;

    Z_n = 1 - sum(n(:, t+1).*p.dP) + (1 - ks.delta).*p.s.*(p.sum_bl*(chi_n.*n_n.*dP_n));
    V_n = (1 - ks.delta).*p.s.*(p.sum_bl*(chi_n.*phi_n.*n_n.*dP_n))./Z_n;

    for k = 1:ks.ns
        h_n(:, k) = p.mc_inv(chi_n(:, k).*(phi_n(:, k) - V_n(:, k)), ks.c0(k), p.c1);
    end

    lambda_dF_n = h_n.*dP_n./Z_n;
    q_n = p.s*(p.sum_ab*lambda_dF_n);

    % Continuation values
    U_cont = U_n + sum(V_n.*lambda_dF_n, 1);

    S_cont = (1 - q_n).*phi_n + p.s*(p.sum_ab*(V_n.*lambda_dF_n));
    S_cont = U_n + (1 - ks.delta).*chi_n.*S_cont;

    % Value functions,  in log-deviations from stationary equilibrium
    U_t = ks.sim_b(t) + ks.sim_beta(t)*U_cont*ks.tQ(:, ks.sim_state(t));
    S_t = ks.sim_omega(t)*p.p + ks.sim_beta(t)*S_cont*ks.tQ(:, ks.sim_state(t));

    y(:, t) = [log(S_t) - log(st.S); log(U_t) - log(st.U)];

end

% Stack exogenous and endogenous regressors
X = [ks.sim_log_omega_poly; X(:, 1:ks.T)];
    
