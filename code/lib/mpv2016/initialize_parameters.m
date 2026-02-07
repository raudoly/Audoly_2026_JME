function p = initialize_parameters(par, p)
% Initialize model parameters.
% Initialize grids.

% Exogenous job separation shock 
p.delta = par(1); 	

% Cost of hiring function
p.c0 = par(2);		
p.c1 = par(3);	

p.c = @(h, c0, c1) (c0*h).^(c1 + 1)/(c1 + 1);	    % Cost of hiring
p.mc_inv = @(J, c0, c1) (J/c0).^(1/c1)/c0;          % Inverse marginal cost

% Relative search effort employed workers (s<1)
p.s = par(4); 	

% Productivity distribution
p.sig_p = par(5);

switch p.p_distribution

	case 'lognormal'

        [p.lnp, P] = tauchen_truncated(p.np, 0.0, 0.0, p.sig_p, 3);
          
        p.p = exp(p.lnp);
        p.dP = transpose(P(1, :));

    case 'pareto'

        p.lnp = linspace(0.0, 2.5, p.np)'; % 2.5 > idr in VA in data
        p.p = exp(p.lnp);

        % Normalized pareto distribution
        p.dP = p.sig_p*p.p.^(-p.sig_p-1);
        p.dP = p.dP/sum(p.dP);
        
end

% Flow value of unemployment
p.b = par(6)*sum(p.p.*p.dP);

