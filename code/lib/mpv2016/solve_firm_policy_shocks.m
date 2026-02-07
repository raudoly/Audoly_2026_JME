function [chi, V, h, lambda_dF, q] = solve_firm_policy_shocks(phi, n, delta, c0, p)
 % SOLVE_FIRM_POLICY_SHOCKS Firm policy rules given time-varying shocks (MPV2016).
 %
 % [chi, V, h, lambda_dF, q] = SOLVE_FIRM_POLICY_SHOCKS(phi, n, delta, c0, p)
 % computes firm-level policies when separation rate (delta) and the vacancy
 % posting cost intercept (c0) vary over time (aggregate shocks).
 %
 % Inputs
 %   phi   : vector
 %       Surplus by idiosyncratic productivity state.
 %   n     : vector
 %       Firm measure/employment by productivity state.
 %   delta : scalar
 %       Separation rate for the current period.
 %   c0    : scalar
 %       Vacancy posting cost intercept for the current period.
 %   p     : struct
 %       Parameter struct (expects fields such as dP, s, sum_bl, sum_ab,
 %       c1, mc_inv).
 %
 % Outputs
 %   chi       : vector
 %       Indicator for active firms (phi >= 0).
 %   V         : vector
 %       Continuation value term used in hiring.
 %   h         : vector
 %       Hiring policy.
 %   lambda_dF : vector
 %       Job-finding intensity measure (scaled by productivity probabilities).
 %   q         : vector
 %       Job-filling rate.
 
 chi = phi>=0.0;												
 Z = 1 - sum(n.*p.dP) + (1 - delta)*p.s*p.sum_bl*(chi.*n.*p.dP);
 V = (1 - delta)*p.s*(p.sum_bl*(chi.*phi.*n.*p.dP))./Z;
 h = p.mc_inv(chi.*(phi - V), c0, p.c1);
 lambda_dF = h.*p.dP./Z;
 q = p.s*(p.sum_ab*lambda_dF);
