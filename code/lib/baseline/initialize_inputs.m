function p = initialize_inputs(model_version)
% Initialize structure 'p' with model inputs

% Set type of idiosyncratic shocks
if nargin<1
	p.distr_p = 'lognormal_ar1';
end

if nargin==1
	if strcmp(model_version, 'pareto_redrawn')
		p.distr_p = 'pareto_redrawn';
	else
		p.distr_p = 'lognormal_ar1';
	end
end

% Grid size for productivity 
p.np = 401;                           	

% Discounting
p.r_yearly = .05;                     	
p.r = (1 + p.r_yearly)^(1/12) - 1;      
p.beta = 1/(1 + p.r);                  	

% Matrices to sum above/below on p grid
p.sum_bl = tril(ones(p.np), -1);              
p.sum_ab = triu(ones(p.np), +1);        

% Size of entrants
p.n0 = 1;

