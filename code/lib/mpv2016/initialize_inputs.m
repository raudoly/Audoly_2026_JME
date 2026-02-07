function p = initialize_inputs(model_version)
% Initialize structure 'p' with model inputs

% Productivity distribution
if nargin<1
	p.p_distribution = 'lognormal';
end

if nargin==1
	if strcmp(model_version, 'pareto')
		p.p_distribution = 'pareto';
	else
		p.p_distribution = 'lognormal';
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


