function st = prepare_steady_state(st,p)
% Additional steady-state computations

% Unemployed worker value 
U = p.b + p.beta*sum(st.V.*st.lambda_dF);
U = U/(1 - p.beta);

% Firm-worker value
S = U + (1 - p.delta)*st.chi.*((1 - st.q).*st.phi + p.s*(p.sum_ab*(st.V.*st.lambda_dF)));
S = p.p + p.beta*S;

% Measure of workers
dL = st.n.*p.dP;

if sum(dL)>1.0
    error('Measure of workers exceeds 1!');
end

st.U = U;
st.S = S;
st.dL = dL;
