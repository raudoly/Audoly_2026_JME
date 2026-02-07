function st = solve_steady_state(p) 
% Find steady-state equilibrium by iterating on measures and surplus.
% Enforces \lambda<1 because UE<1 in data.

% Initialize measures
dLp0 = zeros(p.np,1);       % employment mass (end of period)
dKp0 = zeros(p.np,1);       % firm mass (end of period)
dL = zeros(p.np,1);         % employment mass (beginning of period)        
dK = zeros(p.np,1);         % firm mass (beginning of period)
lambda_dF = zeros(p.np,1);       % offer distribution
 
% Initialize net surplus
phi0 = p.p - p.b;
phi = zeros(p.np,1);

% Solve iterating on net surplus and measure of workers
iter = 0; 
crit = 1.0; 
max_iter = 20000;       
relax = 1e-1;          

while iter<max_iter && crit>1e-8 && sum(lambda_dF)<1.0

    iter = iter + 1;

    % use previous period values
    dLp = dLp0; 
    dKp = dKp0;
    
    phi = relax*phi0 + (1 - relax)*phi; % dampening here for convergence

    % optimal decisions
    [chi,V,h,lambda_dF,q] = solve_firm_policy(phi,dL,p);

    % update net surplus
    phi0 = - p.c(h,p.c0,p.c1) + (1 - q).*phi + h.*(phi - V) + p.s*(p.sum_ab*(V.*lambda_dF));
    phi0 = (1 - p.delta)*chi.*phi0 - sum(V.*lambda_dF);
    phi0 = p.p - p.b + p.beta*(1 - p.mu)*(p.P*phi0);

    % update labor and firm measures
    dLp0 = chi.*((1 - q + h).*(1 - p.mu).*(1 - p.delta).*dL + p.mu*p.dP0);
    dKp0 = chi.*(dK + p.mu.*p.dP0);
    dL = p.tP*dLp0;
    dK = p.tP*dKp0;

    % convergence criterium
    crit = max(abs([dLp0 - dLp;dKp0 - dKp;phi0 - phi])); 

end

% Flag problematic equilibria
st.flag = false;
st.flag = st.flag || iter==max_iter;
st.flag = st.flag || sum(lambda_dF)>=1;
st.flag = st.flag || ~any(chi);

if st.flag 
    return;
end

% Equilibrium wages
w = (1 - p.delta)*chi.*((1 - q).*V + p.s*(p.sum_ab*(V.*lambda_dF)));
w = w - sum(V.*lambda_dF);
w = V + p.b - p.beta*(1 - p.mu)*p.P*w;
w = chi.*w;

% Pack up stationary equilibrium 
% (structure st)
st.phi = phi;
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

