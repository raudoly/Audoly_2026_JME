function lin = solve_linearization(lin,st,p)
% Solve model with aggregate shocks using Reiter's method.
% Notation is based on Schmitt-Grohe and Uribe (JEDC, 2004). 

% Vector of steady-state variables using SGU's notation:
% X = "states" 
% Y = "jumps"

X_st = [log(st.dL); log(1 - sum(st.dL)); 0.0];   
Y_st = [log(st.S); log(st.U)];         

% Vector of equations at the steady-state
F_st = compute_F(Y_st,Y_st,X_st,X_st,lin.rho_omega,p);

% Numerically compute jacobian at the steady-state
F_y_next = dF(@(x) compute_F(x,Y_st,X_st,X_st,lin.rho_omega,p),F_st,Y_st); % wrt Y'
F_x_next = dF(@(x) compute_F(Y_st,Y_st,x,X_st,lin.rho_omega,p),F_st,X_st); % wrt X'

F_y = dF(@(x) compute_F(Y_st,x,X_st,X_st,lin.rho_omega,p),F_st,Y_st); % wrt Y
F_x = dF(@(x) compute_F(Y_st,Y_st,X_st,x,lin.rho_omega,p),F_st,X_st); % wrt X

% Linearize system around steady state
[g_x,h_x,exitflag] = gx_hx(F_y,F_x,F_y_next,F_x_next); 

if exitflag~=1
	error('Could not solve linear system.');
end

lin.g_x = g_x;
lin.h_x = h_x;
lin.X_st = X_st;
lin.Y_st = Y_st;

if lin.diagnose
	diagnose_linearization(lin,st,p);
end

% One-time shock
% otShock = [-1.0; zeros(sim.GRlength,1)];
% [dLpath,NSpath,lOmpath] = sim_pol(otShock,shock_params(2),gx,hx,st,p,s);
% irf = path_output(NSpath,dLpath,lOmpath,st,p,s);

% Full simulation
% compute unconditional simulation, given a sequence of shocks
% sim_shocks = simu.sig_shock*simu.shockdraws;
% [Ssim,Lsim,logAsim] = simulate_states(sim_shocks,gx,hx,st,p.np);
% cyc = simu_output(Ssim,Lsim,logAsim,simu,p,s);
	
function F = compute_F(Y_next,Y,X_next,X,rho_omega,p)
% Function to return the F difference identities for the model equations.

% Unpack variables
dL_next = exp(X_next(1:p.np,1));
S_next = exp(Y_next(1:p.np,1));
U_next = exp(Y_next(p.np+1,1));
u_next = exp(X_next(p.np+1));
log_omega_next = X_next(p.np+2,1);

dL = exp(X(1:p.np,1));
S = exp(Y(1:p.np,1));
U = exp(Y(p.np+1,1));           
u = exp(X(p.np+1));
log_omega = X(p.np+2,1);

% Optimal firm decisions conditional on \phi_{t+1}, dL_{t+1}
phi = S_next - U_next;

[chi,V,h,lambda_dF,q] = solve_firm_policy(phi,dL_next,p);

% Unemployment value
U_LHS = U;
U_RHS = U_next + p.mu*sum(chi.*phi.*p.dP0) + (1 - p.mu)*sum(V.*lambda_dF);
U_RHS = p.b + p.beta*U_RHS;

% Surplus value
S_LHS = S;
S_RHS = -p.c(h) + (1 - q).*phi + h.*(phi - V) + p.s*(p.sum_ab*(V.*lambda_dF));
S_RHS = U_next + p.mu*sum(chi.*phi.*p.dP0) + (1 - p.mu)*(1 - p.delta)*chi.*S_RHS; 
S_RHS = exp(log_omega)*p.p + p.beta*p.P*S_RHS;

% Optimal firm decisions conditional on \phi_{t}, dL_{t}
phi = S_RHS - U_RHS; 
[chi,~,h,lambda_dF,q] = solve_firm_policy(phi,dL,p); 

% Update employment measure
dL_LHS = dL_next;
dL_RHS = p.tP*(chi.*((1 - q + h).*(1 - p.mu).*(1 - p.delta).*dL + p.mu*p.dP0));

% Unemployment rate
u_LHS = u_next;
u_RHS = (1 - p.mu)*((1 - sum(lambda_dF))*u + sum((~chi + p.delta*chi).*dL));
u_RHS = p.mu*sum(~chi.*p.dP0) +u_RHS;    

% Aggregate shock
shock_LHS = log_omega_next;
shock_RHS = rho_omega*log_omega;

F = [ ...
    S_LHS - S_RHS;...
    U_LHS - U_RHS;...
    dL_LHS - dL_RHS;...
    u_LHS - u_RHS;...
    shock_LHS - shock_RHS;...
    ];

function dF = dF(F,Fbar,xbar)
% Numerically compute the Jacobian at the steady-state by forward diff.
% F: function to differentiate
% Fbar: system evaluated at the steady-state
% xbar: vector of inputs at the steady-state

nx = length(xbar);
dF = zeros(length(Fbar),nx);

h = 1e-2; % With all variables in logs, ~ 1% change

for jx = 1:nx
	x = xbar;
    % h = max(1e-5,abs(x(jx))*1e-2);
	x(jx) = x(jx) + h;
	Fh = F(x);
	dF(:,jx) = (Fh - Fbar)/h;
end

function [dL,phi] = simulate_lin(z,lin,st,p)
% Model simulation from linearization 
% "_hat" = log-deviation from steady-state

% Allocate memory
phi = zeros(p.np,lin.T);
dL = zeros(p.np,lin.T);

% Simulation using linearization
X_hat = zeros(p.np+2,1);

for t = 1:lin.T
	
	% X current period
	X_hat = lin.h_x*X_hat; 
	X_hat(end,1) = X_hat(end,1) + lin.sig_omega*z(t); 

	% Extract states
	dL(:,t) = st.dL.*exp(X_hat(1:p.np,1));

	% Extract controls
	Y_hat = lin.g_x*X_hat;
	U = st.U*exp(Y_hat(p.np+1,1));
	S = st.S.*exp(Y_hat(1:p.np,1));
	phi(:,t) = S - U;

end

function [dL,phi] = simulate_pol(z,lin,st,p)
% Model simulation using implied policies at each step.
% "hat" = log-deviation from steady-state

phi = zeros(p.np,lin.T);
dL = [st.dL,zeros(p.np,lin.T)];

log_omega = 0.0;

for t = 1:lin.T
	
	% Aggregate shock
	log_omega = lin.rho_omega*log_omega + lin.sig_omega*z(t);

	% Extract control variables
	Y_hat = lin.g_x*[log(dL(:,t)) - log(st.dL); log(1 - sum(dL(:,t))) - log(1 - sum(st.dL)); log_omega];
	U = st.U*exp(Y_hat(p.np+1,1));
	S = st.S.*exp(Y_hat(1:p.np,1));

	phi(:,t) = S - U;

	% compute policies and update employment mass
	[chi,~,h,~,q] = solve_firm_policy(phi(:,t),dL(:,t),p);
	dL(:,t+1) = p.tP*(chi.*((1 - q + h).*(1 - p.mu).*dL(:,t) + p.mu*p.dP0));

end

function diagnose_linearization(lin,st,p)

% Sequence of shocks 
rng(7021992);

z = randn(lin.T,1);

% Solve model using two concepts
dL_lin = simulate_lin(z,lin,st,p);
dL_pol = simulate_pol(z,lin,st,p);

% Flag negative measure
if any(dL_lin(:)<0)
	disp('Perturbation method implies negative pmf.');
end

% Summary stats on difference between two measures
dL_errors = abs(100*log(dL_lin(:,2:lin.T)./dL_pol(:,2:lin.T)));

fprintf('\n');
disp('Den-Haan Stats:');
disp('---------------');
fprintf('Avg absolute error is %1.5f percent\n', mean(dL_errors(:)));
fprintf('Max absolute error is %1.5f percent\n', max(dL_errors(:)));

% Summarize differences in distribution of workers
nm = 2;

summary_dL_lin = repmat(summarize_measure(st.dL,p.p,nm),1,lin.T);
summary_dL_pol = repmat(summarize_measure(st.dL,p.p,nm),1,lin.T);

for t = 1:lin.T
	summary_dL_lin(:,t) = summarize_measure(dL_lin(:,t),p.p,nm);
	summary_dL_pol(:,t) = summarize_measure(dL_pol(:,t),p.p,nm);
end

close all;

plt([summary_dL_lin(1,:)',summary_dL_pol(1,:)'],'Unemployment Rate');
plt([summary_dL_lin(2,:)',summary_dL_pol(2,:)'],'Worker Productivity Distribution: First Moment');
plt([summary_dL_lin(3,:)',summary_dL_pol(3,:)'],'Worker Productivity Distribution: Second Moment');

function f = plt(ts,ttl)

f = figure;

plot(ts,'LineWidth',2);
xlabel('t (month)');
title(ttl);
legend('Linearization','Using policies','Location','Best');

% -------------------------------------------------------------------------

% Everything Below is the code do a second-order linearization.
% This code was still running after three days on standard
% desktop. Not sure it's correct.

% disp('Starting to solve second-order system...'); tStart = tic;
% 
% % compute second derivatives terms: same argument
% Fypyp   = d2Fsame( @(x) compute_F(x,Y_st,X_st,X_st,p,s,lin.rho_omega, Fss, Y_st, sim.diffstep); % wrt Y', Y'
% Fyy     = d2Fsame( @(x) compute_F(Y_st,x,X_st,X_st,p,s,lin.rho_omega, Fss, Y_st, sim.diffstep); % wrt Y, Y
% Fxpxp   = d2Fsame( @(x) compute_F(Y_st,Y_st,x,X_st,p,s,lin.rho_omega, Fss, X_st, sim.diffstep); % wrt X', X'
% Fxx     = d2Fsame( @(x) compute_F(Y_st,Y_st,X_st,x,p,s,lin.rho_omega, Fss, X_st, sim.diffstep); % wrt X, X
% 
% % compute second derivatives terms: distinct argument
% Fypy    = d2Fdistinct( @(x,y) compute_F(x,y,X_st,X_st,p,s,lin.rho_omega, Fss, Y_st, Y_st, sim.diffstep); % wrt Y', Y
% Fypxp   = d2Fdistinct( @(x,y) compute_F(x,Y_st,y,X_st,p,s,lin.rho_omega, Fss, Y_st, X_st, sim.diffstep); % wrt Y', X'
% Fypx    = d2Fdistinct( @(x,y) compute_F(x,Y_st,X_st,y,p,s,lin.rho_omega, Fss, Y_st, X_st, sim.diffstep); % wrt Y', X
% 
% Fyyp    = d2Fdistinct( @(x,y) compute_F(y,x,X_st,X_st,p,s,lin.rho_omega, Fss, Y_st, Y_st, sim.diffstep); % wrt Y, Y'
% Fyxp    = d2Fdistinct( @(x,y) compute_F(Y_st,x,y,X_st,p,s,lin.rho_omega, Fss, Y_st, X_st, sim.diffstep); % wrt Y, X'
% Fyx     = d2Fdistinct( @(x,y) compute_F(Y_st,x,X_st,y,p,s,lin.rho_omega, Fss, Y_st, X_st, sim.diffstep); % wrt Y, X
% 
% Fxpyp   = d2Fdistinct( @(x,y) compute_F(y,Y_st,x,X_st,p,s,lin.rho_omega, Fss, X_st, Y_st, sim.diffstep); % wrt X', Y'
% Fxpy    = d2Fdistinct( @(x,y) compute_F(Y_st,y,x,X_st,p,s,lin.rho_omega, Fss, X_st, Y_st, sim.diffstep); % wrt X', Y
% Fxpx    = d2Fdistinct( @(x,y) compute_F(Y_st,Y_st,x,y,p,s,lin.rho_omega, Fss, X_st, X_st, sim.diffstep); % wrt X', X
% 
% Fxyp    = d2Fdistinct( @(x,y) compute_F(y,Y_st,X_st,x,p,s,lin.rho_omega, Fss, X_st, Y_st, sim.diffstep); % wrt X, Y'
% Fxy     = d2Fdistinct( @(x,y) compute_F(Y_st,y,X_st,x,p,s,lin.rho_omega, Fss, X_st, Y_st, sim.diffstep); % wrt X, Y
% Fxxp    = d2Fdistinct( @(x,y) compute_F(Y_st,Y_st,y,x,p,s,lin.rho_omega, Fss, X_st, X_st, sim.diffstep); % wrt X, X'
%    % NB. Some of these cross terms should be redundant by definition. Work out reshape at some point.
% 
% % now, call SGU routines
% [gxx,hxx] = gxx_hxx_sparse(Fx,Fxp,Fy,Fyp,Fypyp,Fypy,Fypxp,Fypx,Fyyp,Fyy,Fyxp,Fyx,Fxpyp,Fxpy,Fxpxp,Fxpx,Fxyp,Fxy,Fxxp,Fxx,hx,gx); 
% %     [gss,hss] = gss_hss(Fx,Fxp,Fy,Fyp,Fypyp,Fypy,Fypxp,Fypx,Fyyp,Fyy,Fyxp,Fyx,Fxpyp,Fxpy,Fxpxp,Fxpx,Fxyp,Fxy,Fxxp,Fxx,hx,gx,gxx,eta);
% 
% fprintf('Done solving second-order system: %1.3f seconds.\n', toc(tStart));

% function d2F = d2Fdistinct(F,Fbar,xbar,ybar,diffstep)
% % Numerically compute second order derivative.
% % For case where arguments are distinct.
% 
% nx  = length(xbar);
% ny  = length(ybar);
% d2F = zeros(length(Fbar),nx,ny);
% 
% for i = 1:nx
% 	for j = 1:ny
% 	   
% 	   % reset to steady-state value
% 	   x = xbar;
% 	   y = ybar;
% 
% 	   % step for x
% 	   hx = ndfstep(x(i,1),diffstep);
% 	   x(i,1) = x(i,1) + hx;
% 
% 	   % step for y
% 	   hy = ndfstep(y(j,1),diffstep);
% 	   y(j,1) = y(j,1) + hy;
% 
% 	   % function evals
% 	   Fxy = F(x,y);
% 	   Fx  = F(x,ybar);
% 	   Fy  = F(xbar,y);
% 
% 	   % second-order derivative
% 	   d2F(:,i,j) = (Fxy - Fx - Fy + Fbar)/(hx*hy);
% 
% 	end
% end
% 
% function d2F = d2Fsame(F,Fbar,xbar,diffstep)
% % Numerically compute second order derivative.
% % For case where arguments are distinct.
% 
% nx = length(xbar);
% 
% d2F = zeros(length(Fbar),nx,nx);
% 
% for i = 1:nx
% 	for j = 1:nx
% 
% 	   % reset to steady-state values
% 	   x1 = xbar; 
% 	   x2 = xbar;
% 
% 	   if i==j % branch out for case where exact same x
% 		  
% 		  % step size for both
% 		  hx = ndfstep(x1(i,1),diffstep);
% 		  
% 		  % evaluate function
% 		  x1(i,1) = x1(i,1) + hx;
% 		  Fx = F(x1);  % F(x + h)            
% 		  x1(i,1) = x1(i,1) + hx;
% 		  F2x = F(x1); % F(x + 2h)
% 		  
% 		  % compute derivative
% 		  d2F(:,i,j) = (F2x - 2*Fx + Fbar)/(hx^2);
% 	   
% 	   else % general case
% 		  
% 		  % eval wrt x1
% 		  hx1 = ndfstep(x1(i,1),diffstep);
% 		  x1(i,1) = x1(i,1) + hx1;
% 		  Fx1 = F(x1);
% 
% 		  % eval wrt x2
% 		  hx2 = ndfstep(x2(j,1),diffstep);
% 		  x2(j,1) = x2(j,1) + hx2;
% 		  Fx2 = F(x2);
% 
% 		  % eval wrt x1, x2
% 		  x1x2 = xbar;
% 		  x1x2(i,1) = x1x2(i,1) + hx1;
% 		  x1x2(j,1) = x1x2(j,1) + hx2;           
% 		  Fx1x2 = F(x1x2);
% 
% 		  % compute derivative
% 		  d2F(:,i,j) = (Fx1x2 - Fx1 - Fx2 + Fbar)/(hx1*hx2);
% 		  
% 	   end
% 	end
% end

