function p = initialize_parameters(par, p)
% Initialize parameters used to fit moments. 
 
% Exogenous job separation shock 
p.delta = par(1); 		

% Cost of hiring function
p.c0 = par(2);		
p.c1 = par(3);		

p.c = @(h, c0, c1) (c0*h).^(c1 + 1)/(c1 + 1);	    % Cost of hiring
p.mc_inv = @(J, c0, c1) (J/c0).^(1/c1)/c0;        % Inverse marginal cost

% Relative search effort employed workers (s<1)
p.s = par(4); 		

% Measure of workers starting firms
p.mu = par(5);

% Idiosyncratic productivity distribution
p.rho_p = par(6);       
p.sig_p = par(7);

switch p.distr_p

	case 'lognormal_ar1'

        [p.lnp, p.P] = tauchen_truncated(p.np, 0.0, p.rho_p, p.sig_p, 3);

        p.tP = transpose(p.P);          
        p.p = exp(p.lnp);

        % New entrants draw from stationary distribution 
        p.dP0 = null(p.tP - eye(p.np));
        p.dP0 = p.dP0/sum(p.dP0);

    case 'pareto_redrawn'

        p.lnp = linspace(0.0, 2.5, p.np)'; % 2.5 > idr in VA in data
        p.p = exp(p.lnp);

        % Everyone draws from same distribution,  including new entrants
        p.dP0 = p.sig_p*p.p.^(-p.sig_p-1);
        p.dP0 = p.dP0/sum(p.dP0);

        p.P = p.rho_p*eye(p.np) + (1 - p.rho_p)*repmat(p.dP0', p.np, 1);
        p.tP = transpose(p.P);

end

% Flow value of unemployment
p.b = par(8)*sum(p.p.*p.dP0);        

