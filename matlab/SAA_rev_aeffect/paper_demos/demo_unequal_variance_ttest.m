% simulation for p-value-distribution, code mainly copied from ttest2

s_vec = [.1, .2, .5, 1, 2, 5, 10]; % a times as much variance in class 2 than in class 1
n_rep = 20000;

vartype = 2 % 1: equal variances, 2: unequal variance

alpha = 0.05;
tail = 0; % 1: right, -1: left (remark: p-values not symmetric for 1!)


%% Group size
nx = 6;
ny = 6;

%% Do simulatoin
% init output
P = nan(length(s_vec), n_rep);

for s_ind = 1:length(s_vec)
    s = s_vec(s_ind);
    display(s)

    %     for rep_ind = 1:n_rep % much faster without loop
    %% generate data

    display('Adding all ttests at once (MUCH faster)')

    x = randn(nx, n_rep);
    y = randn(ny, n_rep) * s;

%     % get variance for each group
%     s2x = var(x);
%     s2y = var(y);
%     
%     % get difference of the means
%     difference = mean(x) - mean(y);
% 
%     if vartype == 1 % equal variances
%         dfe = nx + ny - 2;
%         sPooled = sqrt(((nx-1) .* s2x + (ny-1) .* s2y) ./ dfe);
%         se = sPooled .* sqrt(1./nx + 1./ny);
%         ratio = difference ./ se;
% 
%         if (nargout>3)
%             stats = struct('tstat', ratio, 'df', cast(dfe,class(ratio)), ...
%                 'sd', sPooled);
%             if isscalar(dfe) && ~isscalar(ratio)
%                 stats.df = repmat(stats.df,size(ratio));
%             end
%         end
%     elseif vartype == 2 % unequal variances
%         s2xbar = s2x ./ nx;
%         s2ybar = s2y ./ ny;
%         dfe = (s2xbar + s2ybar) .^2 ./ (s2xbar.^2 ./ (nx-1) + s2ybar.^2 ./ (ny-1));
%         se = sqrt(s2xbar + s2ybar);
%         ratio = difference ./ se;
% 
% %         if (nargout>3)
% %             stats = struct('tstat', ratio, 'df', cast(dfe,class(ratio)), ...
% %                 'sd', sqrt(cat(dim, s2x, s2y)));
% %             if isscalar(dfe) && ~isscalar(ratio)
% %                 stats.df = repmat(stats.df,size(ratio));
% %             end
% %         end
% 
%         % Satterthwaite's approximation breaks down when both samples have zero
%         % variance, so we may have gotten a NaN dfe.  But if the difference in
%         % means is non-zero, the hypothesis test can still reasonable results,
%         % that don't depend on the dfe, so give dfe a dummy value.  If difference
%         % in means is zero, the hypothesis test returns NaN.  The CI can be
%         % computed ok in either case.
%         if se == 0, dfe = 1; end
%     end
% 
%     if tail == 0 % two-tailed test
%         p = 2 * tcdf(-abs(ratio),dfe);
% %         if nargout > 2
% %             spread = tinv(1 - alpha ./ 2, dfe) .* se;
% %             ci = cat(dim, difference-spread, difference+spread);
% %         end
%     elseif tail == 1 % right one-tailed test
%         p = tcdf(-ratio,dfe);
% %         if nargout > 2
% %             spread = tinv(1 - alpha, dfe) .* se;
% %             ci = cat(dim, difference-spread, Inf(size(p)));
% %         end
%     elseif tail == -1 % left one-tailed test
%         p = tcdf(ratio,dfe);
% %         if nargout > 2
% %             spread = tinv(1 - alpha, dfe) .* se;
% %             ci = cat(dim, -Inf(size(p)), difference+spread);
% %         end
%     else
%         error('stats:ttest2:BadTail',...
%               'TAIL must be ''both'', ''right'', or ''left'', or 0, 1, or -1.');
%     end

    [H, p] = ttest2(x, y);

    P(s_ind, :) = p;

    % do a 2-sampled t-test
    % improve speed: get t-test code from cv-simulation
    %         [H,P(s_ind, rep_ind),CI,STATS] = ttest2(c1, c2, 0.05, 'right'); %
    %         right: c1 > c2
    %     end

    %% Do all t-tests at once


end

%% Plot result (should be equal if s == 1)

figure

centers = 0.025:0.05:1;

% hist(P', centers);
N = hist(P', centers);

s_vec_str = {};
for s_ind = 1:length(s_vec)
    s_vec_str{s_ind} = num2str(s_vec(s_ind));
end

hp = plot(centers(1:end-1), N(1:end-1, :)/n_rep, 'DisplayName', s_vec_str);
% add 10% line (currently)
hold on
plot([0, 1], [1 1] * 1/length(centers), 'b', 'DisplayName', 'control')
colormap summer
legend(hp)

