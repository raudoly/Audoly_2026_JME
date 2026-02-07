function show_statio_equi(par,saveOutput)
% Analyse characteristics of stationary
% equilibrium.

close all;

if nargin<2
    saveOutput = false;
end

% Inputs
p = initialize_inputs;
p = initialize_parameters(par,p);

% Stationary equilibrium
st = solve_steady_state(p);

if st.flag
    error('Not a valid equilibrium.');
end

st = compute_lm_stats(st,p);

pe_idx = find(st.chi,1); % entry/exit productivity index
g = (1 - p.mu)*(1 - p.delta)*(1 - st.q + st.h) - 1;
% h = (1 - p.mu)*(1 - p.delta)*st.h;
st.pi = st.chi.*(st.phi - st.V);

dLp_pmf = st.dLp/sum(st.dLp);
dKp_pmf = st.dKp/sum(st.dKp);

% Entering firms vs steady-state firm distribution
firms_entrants_vs_all = figure;
plot(p.p,[p.dP0 st.dK/sum(st.dK)]);
line([p.p(pe_idx),p.p(pe_idx)],ylim,'LineStyle',':','Color','k');
legend('New entrants','All firms','Entry/Exit','Location','Best');
xlabel('Productivity (p)'); ylabel('Density');

% Firm vs worker statio distributions
firms_vs_workers = figure;
plot(p.p,[dLp_pmf dKp_pmf]);
line([p.p(pe_idx),p.p(pe_idx)],ylim,'LineStyle',':','Color','k');
legend('Workers','Firms','Entry/Exit','Location','Best');
xlabel('Productivity (p)'); ylabel('Density');

% Hiring and quit rates
hiring_vs_quit_rate = figure;
plot(p.p(st.chi),[st.h(st.chi) st.q(st.chi)]);
line([p.p(pe_idx),p.p(pe_idx)],ylim,'LineStyle',':','Color','k');
legend('Hiring rate: h(p)','Quit rate: q(p)','Entry/Exit','Location','Best');
xlabel('Productivity (p)'); 
xl = xlim; xlim([xl(1) p.p(end)]); 
ylabel('Hiring/quit rate'); 

% Net growth rate
net_growth_rate = figure;
plot(p.p(st.chi),g(st.chi));
line([p.p(pe_idx),p.p(pe_idx)],ylim,'LineStyle',':','Color','k');
legend('Employment growth','Entry/Exit','Location','Best');
xlabel('Productivity (p)'); xl = xlim; xlim([xl(1) p.p(end)]); 
ylabel('Monthly growth rate'); 

% Firm profits
profits = figure;
plot(p.p(st.chi),st.pi(st.chi));
line([p.p(pe_idx),p.p(pe_idx)],ylim,'LineStyle',':','Color','k');
legend('Profits','Entry/Exit','Location','Best');
xlabel('Productivity (p)'); xl = xlim; xlim([xl(1) p.p(end)]); 
ylabel('Profits per worker'); 

% Offered contract
contract = figure;
plot(p.p(st.chi),st.V(st.chi));
line([p.p(pe_idx),p.p(pe_idx)],ylim,'LineStyle',':','Color','k');
legend('Contract','Entry/Exit','Location','Best');
xlabel('Productivity (p)'); xl = xlim; xlim([xl(1) p.p(end)]); 
ylabel('Net contract value'); 

% ... and wage
wage = figure;
plot(p.p(st.chi),st.w(st.chi));
line([p.p(pe_idx),p.p(pe_idx)],ylim,'LineStyle',':','Color','k');
legend('Wage','Entry/Exit','Location','Best');
xlabel('Productivity (p)'); xl = xlim; xlim([xl(1) p.p(end)]); 
ylabel('Wage per worker'); 


% Hockey stick
% hockey_stick = figure;
% plot(g(st.chi),h(st.chi),'LineWidth',1.5);
% line([0.0 h(end)],[0.0 h(end)],'LineStyle',':','Color','k','LineWidth',1.5);
% xlabel('Monthly growth rate');
% ylabel('Monthly hires as a fraction of employment');

% NB. Without a kink in hiring cost, it is not going to show up.

% Additional stats
shr_b_w = p.b/sum(st.w.*dLp_pmf);
shr_b_p = p.b/sum(p.p.*dLp_pmf);
shr_c_p = sum((p.c(st.h)./p.p).*dKp_pmf);
shr_b_p_unc = p.b/sum(p.p.*p.dP0);

more_stats = table(...
	[shr_b_w;shr_b_p;shr_b_p_unc;shr_c_p;st.eu_shr_exit],...
	'Rownames',{'b/mean(w)','b/mean(p)','b/mean(p)_unc','c(h)/p','shr_exit_eu'},...
	'VariableNames',{'Value'});

disp(more_stats);


if saveOutput
    saveas(firms_entrants_vs_all,'../figs/explainer_entrants_vs_all_firms','epsc');
	saveas(firms_vs_workers,'../figs/explainer_workers_vs_firms','epsc');
	saveas(hiring_vs_quit_rate,'../figs/explainer_hiring_and_quits','epsc');
    saveas(net_growth_rate,'../figs/explainer_net_growth_rate','epsc');
end
