function p = initialize_parameters_simplified(par,p,productivity_distribution)
% Initialize params in simplified version of model

if nargin<2
	productivity_distribution = 'normal_ar1';
end

p.c0 	= par(1);
p.mu 	= par(2);

p.c1 = 2.0; 									% Convex recruitment costs
p.s = 1.0; 										% Same search intensity
p.delta = 0.0035; 								% EU rate in UK data

p.c = @(h) p.c0/(p.c1 + 1)*h.^(p.c1 + 1);		% Cost of hiring
p.mc_inv = @(J) (J/p.c0).^(1/p.c1);				% Inverse marginal cost

rho = 0.98;										% Persistence productivity

switch productivity_distribution

	case 'normal_ar1'

		p.b = 0.0; 								
		sig = .07; 								% Reasonable dispersion wrt data

		[lnp,p.P] = tauchen_truncated(p.np,0.0,rho,sig,3);

		p.p = exp(lnp);
		p.tP = transpose(p.P);

		p.dP0 = null(p.tP - eye(p.np));
		p.dP0 = p.dP0/sum(p.dP0);

	case 'pareto_redrawn'

		p.b = .5; 								
		pareto_shape = 1.0;

		pmin = 1.0;
		pmax = 20.0;

		p.p = linspace(pmin,pmax,p.np)';

		% p.dP0 = pareto_shape*p.p.^(-pareto_shape-1)/(1-pmax^(-pareto_shape));
		p.dP0 = pareto_shape*p.p.^(-pareto_shape-1);
		p.dP0 = p.dP0/sum(p.dP0);  

		p.P = rho*eye(p.np) + (1 - rho)*repmat(p.dP0',p.np,1);
		p.tP = transpose(p.P);

	case 'gamma_redrawn'

		p.b = 0.0;
		gamma_shape = 2.5;

		pmin = gaminv(.001,gamma_shape,1/gamma_shape);
		pmax = gaminv(.999,gamma_shape,1/gamma_shape);

		p.p = linspace(pmin,pmax,p.np)';

		p.dP0 = gampdf(p.p,gamma_shape,1/gamma_shape);
		p.dP0 = p.dP0/sum(p.dP0);  

		p.P = rho*eye(p.np) + (1 - rho)*repmat(p.dP0',p.np,1);
		p.tP = transpose(p.P);

end

p.lnp = log(p.p);
	




