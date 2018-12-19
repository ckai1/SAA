% example for a demo that uses tabledata as input.
% factorial.cue (without dummy) nice example for decoding based on
% 'variance' (although not really...)

clear all
close all
%% input

tabledata.Sess(1).name          = {'A' 'A' 'B' 'B' 'B'};
tabledata.Sess(1).RT            = [750 800 650 725 800];
tabledata.Sess(1).factorial.cue = [1   17   3   4   3];  % factorial


tabledata.Sess(2).name          = {'A' 'A' 'A' 'B' 'B'};
tabledata.Sess(2).RT            = [750 800 650 725 800];
tabledata.Sess(2).factorial.cue = [1   17   1   4   3];  % factorial


tabledata.Sess(3).name          = {'A' 'A' 'B' 'B' 'B'};
tabledata.Sess(3).RT            = [750 800 650 725 800];
tabledata.Sess(3).factorial.cue = [1   17   3   4   3];  % factorial


tabledata.Sess(4).name          = {'A' 'A' 'A' 'B' 'B'};
tabledata.Sess(4).RT            = [750 800 650 725 800];
tabledata.Sess(4).factorial.cue = [1   17   1   4   3];  % factorial

%% convert input tabedata into .trial form + display
% trialdata = bede_convert_table_to_trial(tabledata);
% bede_plot_design(trialdata.Sess)

%% Sort
sorteddata = sort_tabledata(tabledata, {'A', 'B'});

%% Create dummies
% Be aware that for e.g. classical multivariate regression, one of these 
% dummy variables should be left out, because they are collinear
sorteddata = create_dummies(sorteddata);

%% Check if data is still equal
bede_plot_design(bede_convert_sortedU_to_trial(sorteddata))

%% Do the easy demo with this
cfg.use_summary_values = 0; % 0: single trial, 1: summary

if cfg.use_summary_values 
    error('todo')
    cfg.decoding_measures = {{'nancount.curr.cond'}, {'nansum.curr.cond'}}; % make sure to have double {{}} here
else % trialwise
    % use the normal values 
    % curr.cond will work 100% here, although the data is unbalanced, 
    % because the values are different enough
    cfg.decoding_measures = {{'RT'}, {'factorial.cue'}, {'regexp:cue[1-4]'}};
    cfg.decoding_measures_expected_result = {   % this text will be shown when the results for this measure are displayed in easy demo
        'Dont now what should happen with RT';
        'Dont now what should happen with factorial.cue';
        'Dont now what should happen with cue[1-4]';
        };
end

[cfg, data, passed_data, result] = easy_demo(sorteddata, cfg);
