% This is the same example as 2b, but it only computes many repetitions for
% 1 subject, which is much faster than repeating it for many subjects.
%
% Because we saw in example 2b that the design does not influence the
% result, we can do this.
%
% Result: 
% The result also shows that CV decoding accuracies are not binomially
% distributed.
%
% Main example in Goergen et al, in prep
%
% Author: Kai Goergen, Mar 27, 2014

clear all
close all

%% specify where to save result figures & in which format
% leave result_figures.folder to skip saving
result_figures.folder = fullfile(fileparts(which('easy_demo')), 'results', 'autofigures'); 
result_figures.format = {'-dpng', '-depsc2'};
if ~isempty(result_figures.folder), display(['Saving figures to ' result_figures.folder]), mkdir(result_figures.folder), end
% line for saving, save_fig from TDT 
% if ~isempty(result_figures.folder), save_fig(fullfile(result_figures.folder, 'figname'), result_figures); end


%% add path
% add path to confound detection addon
display('Adding TDT Confound Detection Addon'); addpath(fullfile(pwd, '../behavioural_decoding')); if isempty(which('behavioural_decoding_batch')), error('Confound Detection Addon seems not been added successfully'), end
% TDT will be added in easy_demo (or add it here)    

%% input
% create a table with all 16 possible assignments
x = dec2bin(0:2^4-1);

%% loop through all assignments
display('Creating data')
for x_ind = 1 % :size(x, 1)% we only take one design here
    tabledata = [];
    demo_cfg = [];
    
    for s_ind = 1:4
        if x(x_ind, s_ind) == '0'
            tabledata.Sess(s_ind).name          = {'A' 'B'};
        else
            tabledata.Sess(s_ind).name          = {'B' 'A'};
        end
        % for each matrix, we create 500 different gaussian random data
        % (faster than calculating it indificually
        for trial_ind = 1:8000
            trial_name = sprintf('trial%03i', trial_ind);
            tabledata.Sess(s_ind).(trial_name) = randn(1,2);
            demo_cfg.decoding_measures(trial_ind) = {{trial_name}}; % we add it to the list of todo decodings
        end
    end

    % plot design (if you like)
    % bede_plot_design(bede_convert_table_to_trial(tabledata))
    %% Sort
    % get sorted Sess.U data
    display('Sorting data')
    sorteddata = sort_tabledata(tabledata, {'A', 'B'});

    %% Do the easy demo with this
    % we have only 1 trial per condition here, so we dont need summary values
    demo_cfg.use_summary_values = 0; % 0: single trial, 1: summary

    if demo_cfg.use_summary_values 
        error('not available here')
    else % trialwise
        % demo_cfg.decoding_measures = {{'trial'}}; % done in loop above
        % here, we have noe expected result
        % demo_cfg.decoding_measures_expected_result = {};   % this text will be shown when the results for this measure are displayed in easy demo
    end

    % switch off plotting
    demo_cfg.plot = 0;
    [decoding_cfg, data, passed_data, result, curr_beh_result] = easy_demo(sorteddata, demo_cfg);

    % collect all results
    all_results.decoding_measures_str = curr_beh_result.decoding_measures_str; % should be the same for all
    all_results.subj_results(x_ind) = curr_beh_result.subj_results; % copy results
    all_results.subj_results(x_ind).subjnr = x(x_ind, :); % set condition as name 
end

%% collect data
n_subs = length(all_results.subj_results);
for s_ind = 1:n_subs
    curr_das = all_results.subj_results(s_ind).results.accuracy_minus_chance.output;
    unique_das = unique(curr_das);
    sub_das(s_ind, :) = curr_das;
end

%% So lets look at the full histogram
figure('name', 'Example2b: Histogram across all')
unique_das = unique(sub_das(:));
counts = histc(sub_das(:), unique_das);
p_counts = counts/sum(counts);
bar(unique_das, p_counts);
hold on
% add 95% CI interval (binomial)
[phat, pci] = binofit(counts,sum(counts));
h_errbar = errorbar(unique_das, phat, phat-pci(:, 1), pci(:, 2)-phat, 'k', 'LineStyle', 'none');
set(get(get(h_errbar,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % exclude errorbar from legend

% add inverse to compare symmetry
plot(unique_das(end:-1:1), counts/sum(counts), 'g-+')
set(gca, 'Xtick', unique_das);

% add binomial distribution for comparison

plot(unique_das, binopdf(0:8, 8, .5), 'r-+')
legend({'simulated outcome [95% CI]', 'inverse simulated outcome (compare symmetry)', 'binomial'})

mean_outcome = sum(unique_das.*counts)/sum(counts);
title({sprintf('Example 2b, simulated n=%i', sum(counts)); 'Demonstrates: Outcome is not binomially distributed and not symmetrical. But mean da minus chance is close to 0 (=chance).'; sprintf('Probably +/-0.x because its a simulation: mean da min chance=%f', mean_outcome)});

if ~isempty(result_figures.folder), save_fig(fullfile(result_figures.folder, 'example2c_hist_sim_vs_binomial'), result_figures); end

%%  plot the cdfs against each other to demonstrate how many 
% false results for binomial

figure('name', 'Example2b: cdf across all')
bar(unique_das, cumsum(counts/sum(counts)));
hold on
% add 95% CI interval (binomial)
[phat, pci] = binofit(cumsum(counts),sum(counts));
h_errbar = errorbar(unique_das, phat, phat-pci(:, 1), pci(:, 2)-phat, 'k', 'LineStyle', 'none');
set(get(get(h_errbar,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % exclude errorbar from legend

% add binomial cdf (cumsum(pdf) used to do the same like for simulation)
plot(unique_das, cumsum(binopdf(0:8, 8, .5)), 'r-+')

% plot upper alpha .95 and lower .05 lines
plot([min(unique_das), max(unique_das)], [.05 .05], 'k');
plot([min(unique_das), max(unique_das)], [.95 .95], 'k');

ylim([0,1]);
xlim([-55,55]);
set(gca, 'Xtick', unique_das);

if ~isempty(result_figures.folder), save_fig(fullfile(result_figures.folder, 'example2c_cdf_sim_vs_binomial'), result_figures); end

%% and plot ps against each other

figure('name', 'p simulation vs p binomial')

for up_low = 1:2  % 1: low, 2: up
    
    p_sim = cumsum(counts)/sum(counts);
%     p_sim_diff = cumsum(counts(end:-1:1))/sum(counts);
    
    p_sim_low = p_sim;
    if up_low == 2
        p_sim = [1; 1-p_sim(1:end-1)]; % subtract because of upper test
        p_sim_up = p_sim;
    end
    
    p_bino = cumsum(binopdf([0:8]', 8, .5));
    p_bino_low = p_bino;
    if up_low == 2
        p_bino = [1; 1-p_bino(1:end-1)]; % subtract of upper test
        p_bino_up = p_bino;
    end
    
    if up_low == 1 % low
        plot(p_sim_low, p_bino_low, '-+r');
        % labels
        for t_ind = 1:length(p_sim)
            text(p_sim_low(t_ind)-.03, p_bino_low(t_ind)+.03, num2str(unique_das(t_ind)), 'color', 'r');
        end
    else
        plot(p_sim_up, p_bino_up, '-+k');
        for t_ind = 1:length(p_sim)
            text(p_sim_up(t_ind)+.03, p_bino_up(t_ind)-.03, num2str(unique_das(t_ind)), 'color', 'k');
        end
    end
    
    hold on
    xlim([0,1]); ylim([0,1]);
end

legend({'test above chance', 'test below chance'}, 'Location', 'NorthWest')

xlabel('p simulation');
ylabel('p binomial');
    
title({'p simulation vs p binomial';
    'The result shows that ALL events that have a probability of 25% above chance (75% da)';
    'or 37.5% below chance would be falsely considered significant using \alpha=0.05 in a binomial test'})

% add significant sectors
plot([.05 .05], [0 1], 'k');
plot([0 1], [.05 .05], 'k');
% .95 is wrong, because cumsum needs be counted backwards
% plot([.95 .95], [0 1], 'k'); 
% plot([0 1], [.95 .95], 'k');

if ~isempty(result_figures.folder), save_fig(fullfile(result_figures.folder, 'example2c_p_sim_vs_p_binomial'), result_figures); end

%% Plot bar to compare proportion of false positives (conservative)

% Remark: The non conservative test will randomly decide with a certain
% probability if a result in the group of outcomes that is in the bin that
% lies across .05 is significant or not

n_sig_bino_up = sum(counts(p_bino_up <= .05));
p_sig_bino_up = n_sig_bino_up / sum(counts)

n_sig_sim_up = sum(counts(p_sim_up <= .05));
p_sig_sim_up = n_sig_sim_up / sum(counts)

n_sig_bino_low = sum(counts(p_bino_low <= 0.05));
p_sig_bino_low = n_sig_bino_low / sum(counts)

n_sig_sim_low = sum(counts(p_sim_low <= 0.05));
p_sig_sim_low = n_sig_sim_low / sum(counts)


% plot
figure('name', 'conservative test')

% add 0.05 line
plot([0.5, 2.5], [.05, .05], 'k')
title({'(common) conservative test'; '(a correct test should have p <=0.05 significant results)'})

% Plot both against each other
res = [p_sig_sim_low, p_sig_bino_low;
    p_sig_sim_up, p_sig_bino_up];

hold on
h = bar(res);

% add 95% confindence interval (binomial)
[phat, pci] = binofit(res([1 3 2 4])*sum(counts),sum(counts));
h_errbar = errorbar([0.87 1.13 1.87 2.13], res([1 3 2 4]), res([1 3 2 4]')-pci(:, 1), pci(:, 2)-res([1 3 2 4]'), 'k', 'LineStyle', 'none');
set(get(get(h_errbar,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % exclude errorbar from legend

set(gca, 'xtick', [1 2], 'xtickLabel', {'lower', 'upper'})
legend(h, {'simulation', 'binomial'})
ylabel('p significant')

if ~isempty(result_figures.folder), save_fig(fullfile(result_figures.folder, 'example2c_conservative_test'), result_figures); end

%% exact test
% calculate how many more we would need to assign (assuming that the n_sig
% that we have are the probability that we have)
p_conservative_bino_up = p_bino_up(find(p_bino_up<=0.05, 1));
n_conservative_bino_up = n_sig_bino_up;
% number we would get in an exact test
n_exact_bino_up = (n_conservative_bino_up/p_conservative_bino_up)*.05 % (100%)*0.5
p_exact_bino_up = n_exact_bino_up / sum(counts)

% same for simulation (only to check that way is correct, the easier way is
% sum(counts)*.05)
p_conservative_sim_up = p_sim_up(find(p_sim_up<=0.05, 1));
n_conservative_sim_up = n_sig_sim_up;
% number we would get in an exact test
n_exact_sim_up = (n_conservative_sim_up/p_conservative_sim_up)*.05 % (100%)*0.5
display('n_exact_sim_up should be 400 if alpha=.05 and sum(counts) = 8000')
p_exact_sim_up = n_exact_sim_up / sum(counts)

% calculate how many more we would need to assign (assuming that the n_sig
% that we have are the probability that we have)
p_conservative_bino_low = p_bino_low(find(p_bino_low<=0.05, 1, 'last'));
n_conservative_bino_low = n_sig_bino_low;
% number we would get in an exact test
n_exact_bino_low = (n_conservative_bino_low/p_conservative_bino_low)*.05 % (100%)*0.5
p_exact_bino_low = n_exact_bino_low / sum(counts)

% same for simulation (only to check that way is correct, the easier way is
% sum(counts)*.05)
p_conservative_sim_low = p_sim_low(find(p_sim_low<=0.05, 1, 'last'));
n_conservative_sim_low = n_sig_sim_low;
% number we would get in an exact test
n_exact_sim_low = (n_conservative_sim_low/p_conservative_sim_low)*.05 % (100%)*0.5
display('n_exact_sim_low should be 400 if alpha=.05 and sum(counts) = 8000')
p_exact_sim_low = n_exact_sim_low / sum(counts)


% plot
figure('name', 'exact test')

% add 0.05 line
plot([0.5, 2.5], [.05, .05], 'k')
title({'exact test'; '(a correct test should have p=0.05 significant results)'})
% Plot both against each other
res = [p_exact_sim_low, p_exact_bino_low;
    p_exact_sim_up, p_exact_bino_up];

hold on
h = bar(res);

% add 95% confindence interval (binomial)
[phat, pci] = binofit(res([1 3 2 4])*sum(counts),sum(counts));
h_errbar = errorbar([0.87 1.13 1.87 2.13], res([1 3 2 4]), res([1 3 2 4]')-pci(:, 1), pci(:, 2)-res([1 3 2 4]'), 'k', 'LineStyle', 'none');
set(get(get(h_errbar,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % exclude errorbar from legend


set(gca, 'xtick', [1 2], 'xtickLabel', {'lower', 'upper'})
legend(h, {'simulation', 'binomial'})
ylabel('p significant')
if ~isempty(result_figures.folder), save_fig(fullfile(result_figures.folder, 'example2c_exact_test'), result_figures); end