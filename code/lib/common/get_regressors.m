function X = get_regressors(dL, st, p)
% Return vector of regressors for out of steady-state solution.
    
m = p.reduce_dL(dL);
mhat = log(m) - log(st.m); % Moments in log deviation from steady-state
X = mhat;
    