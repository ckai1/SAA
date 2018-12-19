% example how systematic balancing accross run can cause 0% decoding
% accuracy (-50% below chance)
% main example in Goergen et al, in prep
%
% Author: Kai Goergen, Mar 27, 2014

clear all
close all
%% input

tabledata.Sess(1).name          = {'A' 'B'};
tabledata.Sess(1).trial         = [1    2];

tabledata.Sess(2).name          = {'B' 'A'};
tabledata.Sess(2).trial         = [1    2];

tabledata.Sess(3).name          = {'A' 'B'};
tabledata.Sess(3).trial         = [1    2];

tabledata.Sess(4).name          = {'B' 'A'};
tabledata.Sess(4).trial         = [1    2];

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
