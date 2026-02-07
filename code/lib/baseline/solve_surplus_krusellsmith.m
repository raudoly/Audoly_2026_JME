function phi = solve_surplus_krusellsmith(log_omega,ks,st,p)
% Model surplus along shock sequence from KS solution

T = length(log_omega);
phi = zeros(p.np,T);
dL = [st.dL,zeros(p.np,T)];

for t = 1:T

    % Exogenous shocks
    log_omega_poly_t = log_omega(t).^((1:ks.degree_poly)');
    c0_t = p.c0*exp(p.elast_c0_to_omega*log_omega(t));
    delta_t = p.delta*exp(p.elast_delta_to_omega*log_omega(t));
    
    % Compute net surplus given regressors
    X_t = [log_omega_poly_t;build_endogenous_regressors(dL(:,t),ks,p)];    
    y_t = ks.theta*X_t;
    
    S_t = exp(y_t(1:p.np)).*st.S;
    U_t = exp(y_t(p.np+1))*st.U;
    
    phi(:,t) = S_t - U_t;

    % Get firm optimal policies
    [chi_t,~,h_t,~,q_t] = solve_firm_policy_shocks(phi(:,t),dL(:,t),delta_t,c0_t,p);  

    % Iterate on law of motion for workers...
    dLp = chi_t.*((1 - q_t + h_t).*(1 - p.mu).*(1 - delta_t).*dL(:,t) + p.mu*p.dP0);
    dL(:,t+1) = p.tP*dLp;

end
    