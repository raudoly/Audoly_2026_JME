function st = solve_steady_state(p) 
% Find steady-state equilibrium by iterating on measures and surplus.
% Enforces \lambda<1 because UE<1 in data.

% Initial values
n0 = zeros(p.np,1);        
lambda_dF = zeros(p.np,1); 
phi = (p.p - p.b)/(1 - p.beta);
phi0 = (p.p - p.b)/(1 - p.beta);

% Solve iterating on net surplus and measure of workers
iter = 0; 
crit = 1.0; 
max_iter = 50000;       
relax = 1e-1;          

while iter<max_iter && crit>1e-8 && sum(lambda_dF)<1.0

    iter = iter + 1;

    n = n0; 
    phi = relax*phi0 + (1 - relax)*phi; % Dampening for convergence
    
    % Optimal decisions
    [chi,V,h,lambda_dF,q] = solve_firm_policy(phi,n,p);

    % Update marginal net surplus
    phi0 = (1 - p.delta)*((1 - q).*phi + p.s*(p.sum_ab*(V.*lambda_dF)));
    phi0 = p.p - p.b + p.beta*chi.*phi0;

    % Update measure of workers
    n0 = chi.*((1 - q).*(1 - p.delta).*n + h);
    
    % Check convergence
    crit = max(abs([n0 - n; phi0 - phi]));

end

% Flag problematic equilibria
st.flag_max_iter = iter==max_iter;
st.flag_lambda = sum(lambda_dF)>=1;
st.flag_active = ~any(chi); 

st.flag = false;
st.flag = st.flag || st.flag_max_iter;
st.flag = st.flag || st.flag_lambda;
st.flag = st.flag || st.flag_active;

if st.flag 
    return;
end

% Equilibrium wages
w = (1 - p.delta)*((1 - q).*V + p.s*(p.sum_ab*(V.*lambda_dF))) - sum(V.*lambda_dF); 
w = V + p.b - p.beta*w;

% Pack up stationary equilibrium
st.phi = phi;
st.chi = chi;
st.V = V;
st.h = h;
st.lambda_dF = lambda_dF;
st.q = q;
st.n = n;
st.w = w;
