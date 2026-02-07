function m = summarize_measure(dL,p,nm)
% Compute moments summary for measure of workers.

m0 = 1 - sum(dL);

dLpmf = dL/(1 - m0); % sum(dL) + u = 1 by definition

m = zeros(nm,1);

for k = 1:nm
    m(k) = dot(p.^k,dLpmf);
end

m = [m0;m];
