% This example demonstrates how unequal number of trials causes a positive
% bias even when no difference between the two classes exists, both when
%   1. trials are used directly (and no counter measure is employed), or
%   2. all trials per session are averaged, so that an equal number of data
%      is provided to the classifier
%
% Biases are clearly visible for e.g. 
%   1d data: n_class_a = 40
%            n_class_b = 5
%
% 200d data: n_class_a = 10
%            n_class_b = 5
%
% Both for e.g. 1000 simulated experiments (repetitions).
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

%% create data

display('Creating data')

n_class_a = 10;
n_class_b = 5;

n_dim = 1; % number of dimension of data (plotting boundary + weights only for n_dim == 1)

n_experiments = 1000; % number of simulationed experiments (repetitions)

tabledata = [];
demo_cfg = [];

for s_ind = 1:6 % number of sessions
    % here, we have n_class_a times A, and n_class_b time B
    tabledata.Sess(s_ind).name = [repmat({'A'}, 1, n_class_a) repmat({'B'}, 1, n_class_b)];
    % create many repetitions of random data (each is a different
    % realization of a single experiment
    for experiment_ind = 1:n_experiments
        experiment_name = sprintf('experiment%03i', experiment_ind);

        %% dimensions within each field (unclear if it works at the moment)
        tabledata.Sess(s_ind).curr.(experiment_name) = randn(n_dim, length(tabledata.Sess(s_ind).name));
        % add name curr.experiment001 as decoding measure for trialwise decoding
        trial_wise.demo_cfg.decoding_measures(experiment_ind) = {{['curr.' experiment_name]}};
        % add name nanmean.curr.experiment001 etc. for run-wise mean decoding
        run_wise.demo_cfg.decoding_measures(experiment_ind) = {{['nanmean.curr.' experiment_name]}};

    end
end

% plot design (if you like)
% bede_plot_design(bede_convert_table_to_trial(tabledata))
%% Sort
% get sorted Sess.U data
display('Sorting data')
sorteddata = sort_tabledata(tabledata, {'A', 'B'});

%% Do trialwise/runwise decoding

for type_ind = 1:2 % 1:single trial, 2:runwise mean

    if type_ind == 1
        % use trialdata
        demo_cfg.use_summary_values = 0; % 0: single trial, 1: summary
        demo_cfg.decoding_measures = trial_wise.demo_cfg.decoding_measures;
        type_name = 'trialwise';
    else
        % use summary data
        demo_cfg.use_summary_values = 1; % 0: single trial, 1: summary
        demo_cfg.decoding_measures = run_wise.demo_cfg.decoding_measures;
        type_name = 'runwise on runmean';
    end

    % switch off plotting
    demo_cfg.plot = 0;

    % RUN DECODING
    [decoding_cfg, data, passed_data, result, all_results] = easy_demo(sorteddata, demo_cfg);

    % get all decoding accuracies
    sub_das = all_results.subj_results.results.accuracy_minus_chance.output;

    %% Lets look at the full histogram
    figure('name', ['Example3: Histogram across all, unbiased data ' type_name])
    unique_das = unique(sub_das(:));
    counts = histc(sub_das(:), unique_das);
    p_counts = counts/sum(counts);
    bar(unique_das, p_counts);
    hold on
    % add 95% CI interval (binomial)
    [phat, pci] = binofit(counts,sum(counts));
    errorbar(unique_das, phat, phat-pci(:, 1), pci(:, 2)-phat, 'k', 'LineStyle', 'none')

    % add inverse to compare symmetry
    plot(-unique_das, counts/sum(counts), 'g-+')
    labels = unique([-unique_das(end:-1:1); unique_das]);
    labelstr = {};
    for l_ind = 1:length(labels)
        labelstr{l_ind} = sprintf('%0.1f', labels(l_ind));
    end
    set(gca, 'Xtick', labels, 'XTickLabel', labelstr);

    legend({'simulated outcome', 'inverse simulated outcome (compare symmetry)'})

    mean_outcome = sum(unique_das.*counts)/sum(counts);
    title({sprintf('Example3: Histogram decoding accuraies, equal randn in both classes, %s simulated n=%i', type_name, sum(counts));
        sprintf('unequal # of trials per class: #class A: %i, #class B:%i (per Session), #dim:%i', n_class_a, n_class_b, n_dim);
        sprintf('mean da min chance=%f', mean_outcome)});

    %% collect all decision boundaries
    if n_dim == 1
        % init boundaries
        boundaries = zeros(length(all_results.subj_results.results.primal_SVM_weights.output{1}), length(all_results.subj_results.results.primal_SVM_weights.output));
        weights = zeros(length(all_results.subj_results.results.primal_SVM_weights.output{1}), length(all_results.subj_results.results.primal_SVM_weights.output));

        display('Collecting boundaries & weights')
        for trial_ind = 1:length(all_results.subj_results.results.primal_SVM_weights.output)
            for sess_ind = 1:length(all_results.subj_results.results.primal_SVM_weights.output{trial_ind})
                curr_weights = all_results.subj_results.results.primal_SVM_weights.output{trial_ind}{sess_ind};
                boundaries(sess_ind, trial_ind) = -curr_weights.b/curr_weights.w;
                weights(sess_ind, trial_ind) = curr_weights.w;
            end
        end
        % plot boundary histogram
        %     display('Getting unique boundaries')
        %     unique_boundaries = unique(boundaries(:));
        %     display('Calculating histogram')
        %     boundary_counts = histc(boundaries(:), unique_boundaries);
        %     display('Plotting histogram')
        %     figure('name', ['Example3: Histogram boundaries, unbiased data ' type_name])
        %     bar(unique_boundaries, boundary_counts);
    end

    %% Plot boundaries
    if n_dim == 1
        display('Plotting boundary distribution')
        figure('name', ['boundary ksdensity ' type_name])
        ksdensity(boundaries(:))
        % add -inf and inf boundaries
        posinf = sum(isinf(boundaries(:)) & boundaries(:) > 0)
        neginf = sum(isinf(boundaries(:)) & boundaries(:) < 0) %
        legend({['#(-inf)=' num2str(neginf) '; #(+inf)=' num2str(posinf)]})
        title({['boundary ksdensity ' type_name];
            sprintf('unequal # of trials per class: #class A: %i, #class B:%i (per Session)', n_class_a, n_class_b);})
    end

    %% Scatter boundary * weight
    if n_dim == 1
        % positive boundary for negative weights expected
        figure('name', ['boundary x weight ' type_name])
        scatter(boundaries(:), weights(:));
        xlabel('Boundary value'); ylabel('Weight');
        title({['boundary x weight ' type_name];
            sprintf('unequal # of trials per class: #class A: %i, #class B:%i (per Session)', n_class_a, n_class_b);})
        % zoom into 3x std (to exclude outliers and show hyperbolic form)
        xlim([-1 1] * 3*std(boundaries(:)))
        ylim([-1 1] * 3*std(weights(:)))

        %% Plot sensitivity vs specificity as ksdens
        display('Plotting boundary distribution')
        figure('name', ['ksdensity of sensitivity vs specificity ' type_name])
        ksdensity(all_results.subj_results.results.sensitivity.output)
        hold all
        ksdensity(all_results.subj_results.results.specificity.output)
        xlim([0 100])
        xlabel('class predicted correct %')
        ylabel('ksdensity')
        legend({'Sensitivity (Class -1 correct)', 'Specificity (Class 1 correct)'})
        title({['ksdensity of sensitivity vs specificity ' type_name];
            sprintf('unequal # of trials per class: #class A: %i, #class B:%i (per Session)', n_class_a, n_class_b);})
    end

    %% Plot DA vs sensitivity vs specifiticy
    display('Plotting boundary distribution')
    figure('name', ['DA vs sensitivity vs specificity ' type_name])
    data = [all_results.subj_results.results.accuracy_minus_chance.output, all_results.subj_results.results.sensitivity.output-50, all_results.subj_results.results.specificity.output-50];
    bar(mean(data,1))
    hold on
    errorbar(mean(data,1), std(data)./sqrt(length(all_results.subj_results.results.accuracy_minus_chance.output)), 'k', 'LineStyle', 'none');
    set(gca, 'XTick', 1:3, 'XtickLabel', {'Decoding Accuracy (chance: 0)', 'Sensitivity - 50% (Class -1 correct)', 'Specificity - 50% (Class 1 correct)'})
    title({['DA vs sensitivity vs specificity (all minus chance, errorbar SEM) ' type_name];
        sprintf('unequal # of trials per class: #class A: %i, #class B:%i (per Session), #dim:%i', n_class_a, n_class_b, n_dim);})
end