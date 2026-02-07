function pn = firmpan(st, p, T, n)
% Simulate cohort of firms in steady-state equilibrium.

% T: max age firms + 1
% n: monthly number of entrants

rng(12041961);

if nargin<3
    % BSD data is left censored: no firms older that 45
    % Still allow for older firms.
    T = 80;          
end

if nargin<4
    % Typical cohort of starters (age = 0) in BSD is ~150K
    n = 15000;      
end

mT = 12*T;          % age max in months
mTx = mT + 12;      % extra year to get exits
N = 12*n;           % entrants over a year

% Flag problem with simulation
pn.flag = 0;

% Interpolant for firm decisions
phi = griddedInterpolant(p.lnp, st.phi);

q = griddedInterpolant(p.lnp, st.q);
h = griddedInterpolant(p.lnp, st.h);
w = griddedInterpolant(p.lnp, st.w);

% Allocate arrays
facti = [kron(eye(12), ones(n, 1)) zeros(N, mT)];
fsize = zeros(size(facti));
fprod = zeros(size(facti));
fwage = zeros(size(facti));

% Quantile function for entrants productivity 
P0 = cumsum(p.dP0);             
idxval = P0>.001 & P0<.999; % Valid indices for interpolation

if sum(idxval)<10 
    pn.flag = 1;
    return; % Exit procedure if distribution is mass point
end

invP0 = griddedInterpolant(P0(idxval), p.lnp(idxval)); % quantile function

% Initial values
drawsP0 = P0(find(st.phi>0, 1)) + (1 - P0(find(st.phi>0, 1)))*rand(N, 1);   
drawsP0 = invP0(drawsP0);

fprod(facti==1) = drawsP0;      % inital log-productivities
fsize(facti==1) = 1;            % ... employment
fwage(facti==1) = w(drawsP0);   % ... and wages 

% Simulate panel forward
for t = 2:mTx   

    % Idiosyncratic productivity for incumbents
    incu = facti(:, t-1)==1;

    if strcmp(p.distr_p, 'pareto_redrawn')
        redraw = rand(N, 1)>p.rho_p;
        fprod(incu & redraw, t) = invP0(rand(sum(incu & redraw), 1));
        fprod(incu & ~redraw, t) = fprod(incu & ~redraw, t-1); 
    else                                         
        fprod(incu, t) = p.rho_p*fprod(incu, t-1) + p.sig_p*randn(sum(incu), 1);
    end

    % Exit for incumbent firms 
    phi_itp = phi(fprod(incu, t));
    facti(incu, t) = phi_itp>=0;
    
    % Check if there are surviving firms   
    surv = facti(:, t-1)==1 & facti(:, t)==1;
    
    if ~any(surv)
        pn.flag = 1;
        break;
    end

    % Employment/wages for surviving incumbents
    q_itp = q(fprod(surv, t));
    h_itp = h(fprod(surv, t));
    
    fsize(surv, t) = (1 - p.mu)*(1 - p.delta)*(1 - q_itp + h_itp).*fsize(surv, t-1);
    fwage(surv, t) = w(fprod(surv, t));

end

if pn.flag
    return;
    % In case no surviving 
    % firms up to age T.
end 

% Compute variables similar to data
active = facti(:, 12:12:mT)==1;
death = facti(:, 12:12:mT)==1 & facti(:, 24:12:mTx)==0; 
emp = fsize(:, 12:12:mT);
lnp = fprod(:, 12:12:mT);

vad = exp(fprod).*fsize; 
vad = vad*kron(eye(T+1), ones(12, 1));  % sum of VA over 12 months
vad = vad(:, 1:T);

tec = fwage.*fsize; 
tec = tec*kron(eye(T+1), ones(12, 1));  % tot. emp. cost over 12 months
tec = tec(:, 1:T);

emp(~active) = 0.0; 
vad(~active) = 0.0;
tec(~active) = 0.0;

% Pack-up yearly panel
pn.T = T;
pn.N = N;
pn.active = active;
pn.death = death;
pn.lnp = lnp;
pn.emp = emp;
pn.vad = vad;
pn.lemp = log(emp);
pn.lnp = fprod(:, 12:12:mT);
pn.lpdy = log(vad) - log(emp);
pn.lwag = log(tec) - log(emp);
pn.age = repmat(0:T-1, N, 1);


