% Demonstrates the effect of temporal autocorrelation over runs if
% block-designs are used. This is the only example (here) that needs data
% with more than one dimension.
%
% Goergen et al, in prep
%
% Author: Kai Goergen, Mar 27, 2014

error('Example is not finished, continue')

clear all
close all
%% input

n_dim = 2; % number of dimension in data

similarity_class = .9; % similarity between the classes in one run, 0..1
    % 1: class specific means are identical (no difference between classes)
    % 0: class specific means are both independent
    
similarity_time = .9; % similarity between neighbouring trials in time, 0..1
    % 1: no change over time
    % 0: neighbouring trials completely independent
    % a value somewhere in between should give a 'smooth' trajectory
    
independent_noise = 0; % add independent noise to each pattern. 0: no noise
    
% create class-specific prototypical patterns
proto_classA = randn(n_dim, 1);
% class B is more or less similar to class A, so add something here
proto_classB = similarity_class * proto_classA + (1-similarity_class) * randn(n_dim, 1);
display('Correlation + euclidean distance between class prototypes (if ndim2, corrcoeff always 1)')
corrcoef(proto_classA, proto_classB)
pdist([proto_classA, proto_classB]', 'euclidean')

%%
trial_counter = 0; % counts all trials of all sessions
for sess_ind = 1:4
    if mod(sess_ind, 2) == 1
        tabledata.Sess(sess_ind).name = {'A' 'B'};
    else
        tabledata.Sess(sess_ind).name = {'B' 'A'};
    end
    
    
    for sess_trial_ind = 1:length(tabledata.Sess(sess_ind).name)
        % get data for this trial
        trial_counter = trial_counter+1;

        if trial_counter == 1
            % get random data as first session 'mean'
            time_data(:, trial_counter) = randn(n_dim, 1);
        else
            % morph between last trial mean and random new mean
            time_data(:, trial_counter) = similarity_time * time_data(:, trial_counter-1) + (1-similarity_time) * randn(n_dim, 1);
        end
    
        % current pattern
        if strcmp(tabledata.Sess(sess_ind).name{sess_trial_ind}, 'A')
            curr_trial_data = time_data(:, trial_counter) + proto_classA + independent_noise * randn(n_dim, 1);
        else
            curr_trial_data = time_data(:, trial_counter) + proto_classB + independent_noise * randn(n_dim, 1);            
        end

        % add data to table
        tabledata.Sess(sess_ind).data(:, sess_trial_ind) = curr_trial_data;
        
        % also collect data for easy plotting
        alltrials(:, trial_counter) = curr_trial_data;
        allclasses(1, trial_counter) = tabledata.Sess(sess_ind).name(sess_trial_ind);
        allsessions(1, trial_counter) = sess_ind;
    end
end

%% plot trajectory
figure('name', 'data trajectory over time')
subplot(2,2,1)
plot(alltrials(1, :), alltrials(2, :));
for t_ind = 1:length(allclasses)
    text(alltrials(1, t_ind), alltrials(2, t_ind), sprintf('%s%i', allclasses{t_ind}, allsessions(t_ind)))
end

%% do MDS
Y = mdscale(pdist(alltrials', 'euclidean'), 2);
subplot(2,2,2)
scatter(Y(:, 1), Y(:, 2), '.')
for t_ind = 1:size(Y, 1)
    text(Y(t_ind, 1), Y(t_ind, 2), sprintf('%s%i', allclasses{t_ind}, allsessions(t_ind)))
end
title('MDS euclidean');

if n_dim > 2
    Y = mdscale(pdist(alltrials', 'correlation'), 2);
    subplot(2,2,3)
    scatter(Y(:, 1), Y(:, 2), '.')
    for t_ind = 1:size(Y, 1)
        text(Y(t_ind, 1), Y(t_ind, 2), sprintf('%s%i', allclasses{t_ind}, allsessions(t_ind)))
    end
    title('MDS correlation');
end
%% Sort
% add path to confound detection addon
display('Adding TDT Confound Detection Addon'); addpath(fullfile(pwd, '../behavioural_decoding')); if isempty(which('behavioural_decoding_batch')), error('Confound Detection Addon seems not been added successfully'), end
% get sorted Sess.U data
sorteddata = sort_tabledata(tabledata, {'A', 'B'});

%% Do the easy demo with this
% we have only 1 trial per condition here, so we dont need summary values
demo_cfg.use_summary_values = 0; % 0: single trial, 1: summary

if demo_cfg.use_summary_values 
    error('not available here')
else % trialwise
    demo_cfg.decoding_measures = {{'trial'}};
    demo_cfg.decoding_measures_expected_result = {   % this text will be shown when the results for this measure are displayed in easy demo
        'In this example, decoding accuracy minus chance should be -50 (=0% decoding accuracy)';
        };
end

[decoding_cfg, data, passed_data, result] = easy_demo(sorteddata, demo_cfg);
