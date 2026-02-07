function st = solve_steady_state_separate(p) 
% Find steady-state equilibrium by iterating on measures and
% value functions S and U separately. The baseline version 
% solve_steady_state.m iterates on the *net* surplus instead.

% Note: Enforces \lambda<1 because UE<1 in data.

% Initialize measures
dLp0 = zeros(p.np,1);           % employment mass (end of period)
dKp0 = zeros(p.np,1);           % firm mass (end of period)
dL = zeros(p.np,1);             % employment mass (beginning of period)        
dK = zeros(p.np,1);             % firm mass (beginning of period)
lambda_dF = zeros(p.np,1);      % offer distribution
    
% Initialize surplus values
S = p.p;
U = p.b;

S0 = zeros(p.np,1);
U0 = 0.0;

% Solve iterating on net surplus and measure of workers
iter = 0; 
crit = 1.0; 
maxiter = 100000;       
relax = 1e-1;           

while iter<maxiter && crit>1e-8 && sum(lambda_dF)<1.0

    iter = iter + 1;

    dLp = dLp0; 
    dKp = dKp0;

    S = relax*S0 + (1 - relax)*S; 
    U = relax*U0 + (1 - relax)*U; 
    
    % Firm optimal decisions
    chi = S>=U;
    u = 1 - sum(dL);
    Z = u + (1 - p.delta)*p.s*p.sum_bl*(chi.*dL);
    V = (u*U + (1 - p.delta)*p.s*(p.sum_bl*(chi.*S.*dL)))./Z;
    h = p.mc_inv(chi.*(S - V),p.c0,p.c1);
    lambda_dF = (1 - p.delta)*chi.*h.*dL./Z;
    q = p.s*(p.sum_ab*lambda_dF);

    % Value of entrepreneurship
    Q = sum((U + chi.*(S - U)).*p.dP0);

    % Value of firm-worker surplus
    psi = - p.c(h,p.c0,p.c1) + (1 - q).*S + h.*(S - V) + p.s*(p.sum_ab*(V.*lambda_dF));
    S0 = p.mu*Q + (1 - p.mu)*((~chi + p.delta*chi)*U + chi.*(1 - p.delta).*psi);
    S0 = p.p + p.beta_e*p.P*S0;

    % Value of unemployment
    U0 = p.mu*Q + (1 - p.mu)*(U + sum((V - U).*lambda_dF));
    U0 = p.b + p.beta_u*U0; 

    % Update labor and firm measures
    dLp0 = chi.*((1 - q + h).*(1 - p.mu).*(1 - p.delta).*dL + p.mu*p.dP0);
    dKp0 = chi.*(dK + p.mu.*p.dP0);

    dL = p.tP*dLp0;
    dK = p.tP*dKp0;

    % Convergence criterium
    crit = max(abs([dLp0 - dLp;dKp0 - dKp;U0 - U;S0 - S])); 

end

% Flag problematic equilibria
st.flag = false;
st.flag = st.flag || iter==maxiter;
st.flag = st.flag || sum(lambda_dF)>=1;
st.flag = st.flag || ~any(chi);

if st.flag 
    return;
end

% Equilibrium wages
w = (1 - q).*V + p.s*(p.sum_ab*(V.*lambda_dF));
w = p.mu*Q + (1 - p.mu)*((~chi + p.delta*chi).*U + chi.*(1 - p.delta).*w);
w = V - p.beta_e*p.P*w;
w = chi.*w;

% Pack up steady-state equilibrium (structure st)
st.S = S;
st.U = U;
st.chi = chi;
st.V = V;
st.h = h;
st.lambda_dF = lambda_dF;
st.q = q;
st.dKp = dKp;
st.dLp = dLp;
st.dL = dL;
st.dK = dK;
st.w = w;

