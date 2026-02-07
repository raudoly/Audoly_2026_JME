function ks = solve_krusellsmith(ks,st,p)
% Solve full model with aggregate shocks using Krusell-Smith
% (KS) algorithm adapted to this setting.

if ~ks.solve
    load(ks.filename,'theta');
    ks.theta = theta;
    return;
end

% Solution algorithm parameters
itermax = 2000;
relax = 5e-1;
convcrit = 1e-3;
ridge_parameter = 1e-4;

% Initialize
error_flag = false;

iter = 0;
crit = 1.0;
tstart = tic;

[theta,theta_new] = deal(zeros(p.np+1,ks.degree_poly+1+ks.nm));


% Iterate on coefficients until convergence
while iter<itermax && crit>convcrit

    iter = iter + 1;

    [X,y] = update_regression_inputs(theta,ks,st,p);

    % Run regressions separately at each grid point
    for jp = 1:p.np+1
        b = ridge(y(jp,ks.tsample)',X(:,ks.tsample)',ridge_parameter,0);
        theta_new(jp,:) = b(2:end);
        % Ignore constant, so impose the steady-state holds exactly.
    end

    if any(isnan(theta_new(:)))
        error_flag = true;
        error_msg = 'NaN in coefficient array!';
        break;
    end

    if ~isreal(theta_new)
        error_flag = true;
        error_msg = 'Imaginary part in solution!';
        break;
    end

    crit = max(abs(theta_new(:) - theta(:)));
    theta = theta + relax*(theta_new - theta);

    if ks.verbose
        fprintf('Iteration %d with distance %1.7f \n',iter,crit);
    end

end

if iter==itermax
    error_flag = true;
    error_msg = 'No convergence in coefficients given simulation parameters';
end

ks.error_flag = error_flag;

if error_flag
    disp(error_msg);
else
    total_time = toc(tstart)/3600;
    fprintf('Done iterating on coefficients in %1.3f hours.\n',total_time);
    ks.theta = theta;
    if ks.save
        save(ks.filename,'theta');
    end
end

