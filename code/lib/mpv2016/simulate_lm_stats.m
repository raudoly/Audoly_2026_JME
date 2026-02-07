% Simulate labor market stats in stationary equilibrium.
function lm_stats = simulate_lm_stats(st, p)
% SIMULATE_LM_STATS Simulate labor market statistics in stationary equilibrium (MPV2016).
%
% lm_stats = SIMULATE_LM_STATS(st, p) computes unemployment, vacancies, and
% worker flow rates implied by the stationary equilibrium objects.
%
% Inputs
%   st : struct
%       Steady-state solution objects (expects fields n, chi, lambda_dF, q).
%   p  : struct
%       Parameter struct (expects fields dP, delta, s).
%
% Output
%   lm_stats : struct
%       Structure with fields u, v, ue, eu, ee.

u = 1 - sum(st.n.*p.dP);
L = sum(st.chi.*st.n.*p.dP);
v = sum(st.lambda_dF)*(u + (1 - p.delta)*p.s*sum(st.chi.*st.n.*p.dP));

ue_flow = u*sum(st.lambda_dF);
eu_flow = p.delta*sum(st.chi.*st.n.*p.dP);
ee_flow = sum(st.q.*st.chi.*st.n.*p.dP);

ue = -log(1.0 - ue_flow/u);
eu = -log(1.0 - eu_flow/L);
ee = -log(1.0 - ee_flow/L);

lm_stats.u = u;
lm_stats.v = v; 

lm_stats.ue = ue;
lm_stats.eu = eu;
lm_stats.ee = ee;
    