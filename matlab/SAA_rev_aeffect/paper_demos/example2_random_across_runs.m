% Original from behavioural decoding toolbox
%
% extends example one resolving the problem that CV is wrong.
% demonstrates however that none of the outcomes comes close to the 
% estimated decoding accuracy of 50%.
%
% Author: Kai Goergen, Mar 27, 2014

clear all
close all

%% add path
% add path to confound detection addon
display('Adding TDT Confound Detection Addon'); addpath(fullfile(pwd, '../behavioural_decoding')); if isempty(which('behavioural_decoding_batch')), error('Confound Detection Addon seems not been added successfully'), end
% TDT will be added in easy_demo (or add it here)    

%% input
% create a table with all 16 possible assignments
x = dec2bin(0:2^4-1);

%% loop through all assignments

for x_ind = 1:size(x, 1)
    tabledata = [];
    
    for s_ind = 1:4
        if x(x_ind, s_ind) == '0'
            tabledata.Sess(s_ind).name          = {'A' 'B'};
        else
            tabledata.Sess(s_ind).name          = {'B' 'A'};
        end
        tabledata.Sess(s_ind).trial         = [1    2];
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
        demo_cfg.decoding_measures = {{'trial'}};
        demo_cfg.decoding_measures_expected_result = {   % this text will be shown when the results for this measure are displayed in easy demo
            'In this example, decoding accuracy minus chance should be -50 (=0% decoding accuracy)';
            };
    end

    % switch off plotting
    demo_cfg.plot = 0;
    [decoding_cfg, data, passed_data, result, curr_beh_result] = easy_demo(sorteddata, demo_cfg);

    % collect all results
    all_results.decoding_measures_str = curr_beh_result.decoding_measures_str; % should be the same for all
    all_results.subj_results(x_ind) = curr_beh_result.subj_results; % copy results
    % set condition as name ;
    subjnr = x(x_ind, :);
    subjnr = strrep(subjnr, '0', 'AB '); % Replace 0 -> 'AB ' & 1 -> 'BA '
    subjnr = strrep(subjnr, '1', 'BA ');
    all_results.subj_results(x_ind).subjnr = subjnr;
    % to create manual plot at the end (for demo only)
    all_accuracies(x_ind) = curr_beh_result.subj_results.results.accuracy_minus_chance.output;
    all_sbj_names{x_ind} = subjnr;
end

%% display all results
visualize_all_decodings(all_results)

%% Plot AB BA manually
figure
barh(all_accuracies, 'k')
set(gca, 'YTick', 1:length(all_sbj_names)) % necessary for xticklabel to work properly
set(gca, 'YTickLabel', all_sbj_names) % necessary for xticklabel to work properly
set(gca, 'YDir', 'reverse')
% manual: ylim and xticks for all possible outcomes (for random CV)
ylim([0, 17])
set(gca, 'XTick', -50:1/8*100:50) % necessary for xticklabel to work properly


