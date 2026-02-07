function X = build_endogenous_regressors(dL, ks, p)
 % BUILD_ENDOGENOUS_REGRESSORS Build endogenous regressors for KS algorithm.
 %
 % X = BUILD_ENDOGENOUS_REGRESSORS(dL, ks, p) computes the endogenous
 % regressor vector used in the Krusell-Smith (KS) forecasting rule.
 %
 % Inputs
 %   dL : vector
 %       Current cross-sectional measure (typically n .* p.dP).
 %   ks : struct
 %       Krusell-Smith settings/objects (uses ks.nm and ks.log_st_m).
 %   p  : struct
 %       Model parameters (uses p.p).
 %
 % Output
 %   X  : vector
 %       Endogenous regressors in deviation from steady state.
 
 m = summarize_measure(dL,p.p,ks.nm);
 X = log(m) - ks.log_st_m; % moments in deviation from Steady-State