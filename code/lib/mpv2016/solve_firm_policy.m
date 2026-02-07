function [chi, V, h, lambda_dF, q] = solve_firm_policy(phi, n, p)
 % SOLVE_FIRM_POLICY Firm policy functions in stationary equilibrium (MPV2016).
 %
 % [chi, V, h, lambda_dF, q] = SOLVE_FIRM_POLICY(phi, n, p) computes firm-level
 % policy rules and implied objects used in the stationary equilibrium.
 %
 % Inputs
 %   phi : vector
 %       Surplus by idiosyncratic productivity state.
 %   n   : vector
 %       Firm measure/employment by productivity state.
 %   p   : struct
 %       Parameter struct (expects fields such as dP, delta, s, sum_bl,
 %       sum_ab, c0, c1, mc_inv).
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
 Z = 1 - sum(n.*p.dP) + (1 - p.delta)*p.s*p.sum_bl*(chi.*n.*p.dP);
 V = (1 - p.delta)*p.s*(p.sum_bl*(chi.*phi.*n.*p.dP))./Z;
 h = p.mc_inv(chi.*(phi - V), p.c0, p.c1);
 lambda_dF = h.*p.dP./Z;
 q = p.s*(p.sum_ab*lambda_dF);
