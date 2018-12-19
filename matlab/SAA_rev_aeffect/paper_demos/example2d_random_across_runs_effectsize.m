% This example demonstrate how a simple power analysis can be calculated.
% In the example here, we again have the same design as in the main example
% with random alterations (example 2b).
%
% Again, we assume H0 according to which no difference exists between the
% conditions A & B that we are interested in.
%
% However, we can here set the EFFECT SIZE FOR THE CONFOUNDING VARIABLE
% trial nr.
%
% Then, multiple simulations will be run for all 16 possible design 
% matrices (level 1), that show how the distribution of outcomes would be
% under these conditions for the single matrices.
%
% Then, a 2nd level (level 2) simulation is done how a mean outcome looks
% like if multiple subjects are combined.
%
% The example could be easily extended so that instead of the mean for 
% example the p-values of a 2nd level t-test are reported. We chose to
% display the mean values here to show how the variability of primary
% outcomes (and how this relates to the number of measured subjects).
%
% Main example in Goergen et al, in prep
%
% Author: Kai Goergen, Mar 27, 2014

clear all
close all

%% add path
% add path to confound detection addon
display('Adding TDT Confound Detection Addon'); addpath(fullfile(pwd, '../behavioural_decoding')); if isempty(which('behavioural_decoding_batch')), error('Confound Detection Addon seems not been added successfully'), end
% TDT will be added in easy_demo (or add it here)    

%% effect size
% specify an effect size for the confound 'trial number'
%
% also in this example, there is NO DIFFERENCE between the original
% conditions, A and B (it can obviously be added in the simulation easily,
% but in this example we are interested in the effect of the confound)
%
% in this example, the value specifies the mean difference between two
% gaussian distributions with identical variance
%
% the 'true' decoding accuracy (for infinite samples) between the trials 
% (NOT the classes, these will still be 50%) is calculated and 
% displayed below.
%
% this does not mean that the design that is used can indeed estimate this
% true decoding accuracy, or it unbiased

confound_effect_size = 0.1; % Effect size as Cohen's d:
    % Shift of mean oftrial 2relative to trial 1 in 
    % units of standard deviation, NOT shift between classes A and B.
    % (Near) optimal separation (as in the introductory example 2) is
    % achieved for large values, e.g. 1000)
    % Available mat files: 0.1, 1, 1000, 500 1st level repetitions

% further simulation parameters
n_rep_1st_level = 500; % number of outcomes for each single subject
n_rep_2nd_level = 5000; % repetition for each 2nd level with n_subs_2nd_level (below)
n_subs_2nd_level = [1, 2, 3, 5:5:20, 100]; % number of subjects drawn in experiment, can be a vector

% remarks: 
% 1. outcomes for the first level will be calculated before the second
%    level, thus the runtime of both is independent
% 2. the 1st level computation is very efficient once the simulation has
%    started, thus also bigger numbers hardly make it slower (there is
%    however quite some overhead to get it started even with slow values
%    here, so better chose lager ones)
% 3. same argument for repetitions on the second level
% 4. if your only interested at the sencond level, check if a file with
%    decoding outcomes is already present (e.g. 
%       example2d_1stlevel_sub_das_cfeffsize_1000 with effect size 1000)

%% specify where to save result figures & in which format
% leave result_figures.folder to skip saving
result_figures.folder = fullfile(fileparts(which('easy_demo')), 'results', 'autofigures'); 
result_figures.format = {'-dpng', '-depsc2'};
if ~isempty(result_figures.folder), display(['Saving figures to ' result_figures.folder]), mkdir(result_figures.folder), end
% Line for saving with TDT
% if ~isempty(result_figures.folder), save_fig(fullfile(result_figures.folder, 'figname'), result_figures); end

%% input
% create a table with all 16 possible assignments
x = dec2bin(0:2^4-1);

%% Plot theoretical distribution
% plot gaussian
titlestr = ['Values of classes, effectsize=' num2str(confound_effect_size)];
figure('name', titlestr)

% calculate 'optimal' DA if both classes are weighted equally
xvals = -5:.1:(5+confound_effect_size);
plot(xvals, normpdf(xvals, 0, 1)); % class A
hold all
plot(xvals, normpdf(xvals, confound_effect_size, 1)); % class B

% add 'optimal' decision boundary (easy for gaussians)
plot([1 1]*confound_effect_size/2, get(gca, 'ylim'), 'k')

text(confound_effect_size/2, .1, {'Optimal decision boundary'; ['True decoding accuracy=' num2str(normcdf(confound_effect_size/2, 0, 1))]})
legend({'pdf trial 1', 'pdf trial 2', 'optimal decision boundary'})
title('optimal decoding on CONFOUND trial nr')

%% Check if some similar data exist (we only save the effectsize as marker)
savename = ['example2d_1stlevel_sub_das_cfeffsize_' num2str(confound_effect_size) '.mat'];
if exist(savename, 'file')
    display(['Data for this effect size already exists in ' savename '.'])
    display('I do not know whether the number of repetitions in the file are the same as the once you specified.')
    if strcmpi(input(['Do you want to load this data (y/n): '], 's'), 'y')
        display(['Loading data from ' savename])
        load(savename);
        % get unique_das again, they were not saved
        unique_das = unique(sub_das(:));
        generate_data = 0;
    else
        generate_data = 1;
    end
else
    generate_data = 1;
end

if generate_data
    % create data
    %% loop through all assignments
    display('Creating 1st level data')

    for s_ind = 1:size(x, 1)
        tabledata = [];
        demo_cfg = [];

        for sess_ind = 1:4
            if x(s_ind, sess_ind) == '0'
                tabledata.Sess(sess_ind).name          = {'A' 'B'};
            else
                tabledata.Sess(sess_ind).name          = {'B' 'A'};
            end
            % for each matrix, we create 500 different gaussian random data
            % (faster than calculating it indificually
            for experiment_ind = 1:n_rep_1st_level
                experiment_name = sprintf('experiment%03i', experiment_ind);

                % get random data 
                % and shift second trial by specified confound effect size
                tabledata.Sess(sess_ind).(experiment_name) = randn(1,2) + [0, confound_effect_size];

                demo_cfg.decoding_measures(experiment_ind) = {{experiment_name}}; % we add it to the list of todo decodings
            end
        end

        % plot design (if you like)
        % bede_plot_design(bede_convert_table_to_trial(tabledata))
        %% Sort
        % get sorted Sess.U data
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
        all_results.subj_results(s_ind) = curr_beh_result.subj_results; % copy results
        all_results.subj_results(s_ind).subjnr = x(s_ind, :); % set condition as name 
    end

    %% display all results
    % visualize_all_decodings(all_results)

    % create a histogram for each of the different outcomes
    figure('name', 'Example 2d: distribution of outcomes for different design matrices')

    n_subs = length(all_results.subj_results);
    unique_das = []; % collect all unique outcomes across all subjects
    sub_das = [];
    for sess_ind = 1:n_subs
        curr_das = all_results.subj_results(sess_ind).results.accuracy_minus_chance.output;
        unique_das = unique([unique_das(:); curr_das(:)]); % add new unique values to unique_das
        sub_das(sess_ind, :) = curr_das;
    end

    % plot all
    for sess_ind = 1:n_subs
        subplot(n_subs, 1, sess_ind)
        counts = histc(sub_das(sess_ind, :), unique_das);
        bar(unique_das, counts);
        text(60, 0, ['Design ' all_results.subj_results(sess_ind).subjnr])
    end

    subplot(n_subs, 1, 1)
    title({'Example2d: Result: histograms are equal for subjects of the same classes (1: 0000/1111, 2: 0001 etc + inverse, 3: 0011)'});

    %% So lets look at the histogram of the three classes
    figure('name', 'Example2d: Histogram for each class')

    % get classes
    class_inds = cell(3,1);
    class_str = cell(3,1);

    for s_ind = 1:n_subs
        curr_design_name = all_results.subj_results(s_ind).subjnr;
        curr_sum = sum(curr_design_name == '1'); % count number of ones
        if curr_sum == 0 || curr_sum == 4
            class_inds{1}(end+1) = s_ind;
            class_str{1}(end+1, :) = curr_design_name;
        elseif curr_sum == 1 || curr_sum == 3
            class_inds{2}(end+1) = s_ind;
            class_str{2}(end+1, :) = curr_design_name;
        elseif curr_sum == 2
            class_inds{3}(end+1) = s_ind;
            class_str{3}(end+1, :) = curr_design_name;
        end
    end
    
    %% Save results if desired
    if strcmpi(input(['Do you want to save data to ' savename ' (y/n): '], 's'), 'y')
        save(savename, 'sub_das', 'n_*', 'class_*', 'confound_effect_size')
    end
    
end

%% plot all three classes + all classes

figure('name', 'Example2d: Histogram of different classes + across all')

% also add 4th class with all classes for full histogram
class_inds{4} = 1:16;
class_str{4} = 'All (1:16)';

for class_ind = 1:4
    subplot(4,1,class_ind)
    curr_data = sub_das(class_inds{class_ind}, :);
    counts = histc(curr_data(:), unique_das);
    p_counts = counts/sum(counts);
    bar(unique_das, p_counts);
    hold on
    % add 95% CI interval (binomial)
    [phat, pci] = binofit(counts,sum(counts));
    errorbar(unique_das, phat, phat-pci(:, 1), pci(:, 2)-phat, 'k', 'LineStyle', 'none')
    
    mean_outcome = sum(unique_das.*counts)/sum(counts);
    
    text(60, max(phat)*.5, {'Class members:'; class_str{class_ind}; 'Class mean:'; ['DA min chance=' num2str(mean_outcome)]})
end

subplot(4, 1, 1)
title(['Example2d: Histogram of different classes + across all, confound effect size=' num2str(confound_effect_size)])

%%
%% Perform 2nd level simulation
%%

% Parameters are defined at the top
% n_rep_1st_level = 500; % number of outcomes for each single subject
% n_rep_2nd_level = 500; % repetition for each 2nd level with n_subs_2nd_level (below)
% n_subs_2nd_level = [1, 2, 3, 5:5:20]; % number of subjects drawn in experiment, can be a vector

% loop over number of subjects included in 2nd level statistic

% the only input we variable that we use here is the matrix of decoding
% accuracy outcomes that we have in
%   sub_das(subject, realization)
% in which subject is the number of different designs we have used, and
% realization contains each of the repetitions that we have done.
% This makes it easy to reuse this code somewhere else


n_simulated_subjects = size(sub_das, 1)
n_realizations_per_subjects = size(sub_das, 2)

out = [];

for nsubvector_ind = 1:length(n_subs_2nd_level)
    curr_n_subs = n_subs_2nd_level(nsubvector_ind);

    out(nsubvector_ind).mean = zeros(1, n_rep_2nd_level); % init outcome
    
    % perform repetitions for this number of subjects
    for rep2_ind = 1:n_rep_2nd_level
        % this part could be obviously made much faster by drawing all at
        % once and calculating the mean at once, but like this it is easier
        % to understand (and still amazingly fast)
        
        % if you like to select specific subjects and get realizations for
        % them, you need to select the subject first and the get the
        % realization. This gets slow but works similar to below
        
%         curr_subs = randi(n_simulated_subjects, 1, curr_n_subs); % draw subjects (randomly)
%         curr_realizations = randi(n_realizations_per_subjects, 1, curr_n_subs); % draw random realization for each subject
%         curr_values = zeros(1, length(curr_subs));
%         for ind = 1:length(curr_subs)
%         % get values for this combination
%             curr_values(c) = sub_das(curr_subs(c), curr_realizations(c));
%         end

        % however, because we take each subject equally likely, and each
        % realization for each subject as well, we simply randomly draw
        % decoding accuracy outcomes (as many as we have subjects) from the
        % full list of subject decoding accuarcies
        outcome_inds = randi(numel(sub_das), 1, curr_n_subs);
        curr_values = sub_das(outcome_inds);
        % calculate the mean
        out(nsubvector_ind).mean(rep2_ind) = mean(curr_values);
    end
end

%% finally, we plot all: pdf

figure('name', '2nd level pdf of mean outcomes', 'Position', get(0,'ScreenSize')) % fullscreen

for nsubvector_ind = 1:length(n_subs_2nd_level)
    subplot(length(n_subs_2nd_level), 1, nsubvector_ind)
    
    unique_das = unique(out(nsubvector_ind).mean);
    counts = histc(out(nsubvector_ind).mean, unique_das);
    
    % plot probability + 95% CI
    [phat, pci] = binofit(counts',sum(counts));
    h_errbar = errorbar(unique_das, phat, phat-pci(:, 1), pci(:, 2)-phat, 'k', 'LineStyle', 'none');
    set(get(get(h_errbar,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % exclude errorbar from legend
    hold all
    bar(unique_das, phat);
    % get complete range
    xlim([-55 55])
    text(55, 0, sprintf('NSubs = %i', n_subs_2nd_level(nsubvector_ind)));
end

subplot(length(n_subs_2nd_level), 1, 1)
title({['2nd level simulations for confound trial nr with effect size = ' num2str(confound_effect_size)];
    ['n rep 1st level = ' num2str(n_rep_1st_level), ', n rep 2nd level = ' num2str(n_rep_2nd_level), ', n designs = ' num2str(n_simulated_subjects)];
    })

% auto save, if desired
if ~isempty(result_figures.folder), save_fig(fullfile(result_figures.folder, ['example2d_pdf_2ndlevel_outcomes_effsize' num2str(confound_effect_size)]), result_figures); end

%% finally, we plot all: cdf

figure('name', '2nd level cdf of mean outcomes', 'Position', get(0,'ScreenSize')) % fullscreen

for nsubvector_ind = 1:length(n_subs_2nd_level)
    subplot(length(n_subs_2nd_level), 1, nsubvector_ind)
    
    unique_das = unique(out(nsubvector_ind).mean);
    counts = histc(out(nsubvector_ind).mean, unique_das);
    
    % plot probability + 95% CI
    [phat, pci] = binofit(cumsum(counts'),sum(counts));
    h_errbar = errorbar(unique_das, phat, phat-pci(:, 1), pci(:, 2)-phat, 'color', [.5 .5 .5], 'LineStyle', 'none');
    set(get(get(h_errbar,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % exclude errorbar from legend
    hold on    
    stairs(unique_das, phat);
    % get complete range
    xlim([-55 55])
    text(55, 0, sprintf('NSubs = %i', n_subs_2nd_level(nsubvector_ind)));
end

subplot(length(n_subs_2nd_level), 1, 1)
title({'cdf of 2nd level simulations, errorbars display unique outcomes + 95% CI at each step';
    ['2nd level simulations for confound trial nr with effect size = ' num2str(confound_effect_size)];
    ['n rep 1st level = ' num2str(n_rep_1st_level), ', n rep 2nd level = ' num2str(n_rep_2nd_level), ', n designs = ' num2str(n_simulated_subjects)];
    })

% auto save, if desired
if ~isempty(result_figures.folder), save_fig(fullfile(result_figures.folder, ['example2d_cdf_2ndlevel_outcomes_effsize' num2str(confound_effect_size)]), result_figures); end