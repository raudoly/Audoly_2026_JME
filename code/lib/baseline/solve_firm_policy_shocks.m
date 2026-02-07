function [chi, V, h, lambda_dF, q] = solve_firm_policy_shocks(phi, dL, delta, c0, p)
% Solve for the firm's optimal policies, conditional on \phi
% and dL and realizations of additional exogenous shocks 
% (shocks to c0 and \delta)

chi = phi>=0.0;												
Z = 1 - sum(dL) + (1 - delta)*p.s*p.sum_bl*(chi.*dL);
V = (1 - delta)*p.s*(p.sum_bl*(chi.*phi.*dL))./Z;
h = p.mc_inv(chi.*(phi - V), c0, p.c1);
lambda_dF = (1 - delta)*chi.*h.*dL./Z;
q = p.s*(p.sum_ab*lambda_dF);
    