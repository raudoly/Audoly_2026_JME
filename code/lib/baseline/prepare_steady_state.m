function st = prepare_steady_state(st,p)
% Additional steady-state computations

% Unemployed worker value 
U = p.mu*sum(st.phi.*st.chi.*p.dP0) + (1 - p.mu)*sum(st.V.*st.lambda_dF);
U = (p.b + p.beta*U)/(1 - p.beta);

% Firm-worker value
S = st.chi.*( - p.c(st.h,p.c0,p.c1) + st.h.*(st.phi - st.V) + (1 - st.q).*st.phi + p.s*(p.sum_ab*(st.V.*st.lambda_dF)) );
S = U + p.mu*sum(st.phi.*st.chi.*p.dP0) + (1 - p.mu)*(1 - p.delta)*S;
S = p.p + p.beta*p.P*S;

st.U = U;
st.S = S;

