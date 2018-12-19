% create p-values manually and add it manually to right y axis (when max
% value if xaxis is 50

% load original file
open('example2_random_across_runs.fig')

% select plot to modify
subplot(2, 2, 2)

% outcome for all runs equal
[h, vals(1)] = ttest2([1 1 1 1], [2 2 2 2])
[h, vals(2)] = ttest2([1 1 1 2], [2 2 2 1])
[h, vals(3)] = ttest2([1 1 2 2], [2 2 1 1])

% manually specify index vector
pind = [1 2 2 3 2 3 3 2 2 3 3 2 3 2 2 1]

% get labels as cellstr
ps = vals(pind)

for i = 1:length(pind)
    if vals(pind(i)) < .05
        ps_str{i} = sprintf('%0.1f < .05', vals(pind(i)));
    else
        ps_str{i} = sprintf('%0.1f n.s.', vals(pind(i)));
    end
    % add it as text to right axis
    text(52, 0.25+i, ps_str{i})
end

% add p as column
text(52, 0.25, 'p t-test (2-sided)')

% display save figure
display('TODO: If ok, please save figure as example2_random_across_runs_plus_individual_ttest.fig')
