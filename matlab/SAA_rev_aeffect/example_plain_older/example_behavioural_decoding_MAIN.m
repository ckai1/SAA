% Example file how to use behavioural decoding
%
% These files need to be adapted:
%   - example_behavioural_decoding_MAIN.m: This file
%   - Single subject file
% 
% OPTIONAL
%   decoding_cfg_output: output for decoding_cfg, default set in individual function

function results = example_behavioural_decoding_MAIN(substodo, decoding_cfg_output)

%% Set paths, if not set
example_addpaths();

%% Init beh_cfg
beh_cfg = [];

%% Set a name and description for the current decoding (optional)
beh_cfg.name = 'Example behavioural decoding';
beh_cfg.decoding_str = 'Example CV, Left vs Right';

%% Define subjects 

% define subjects, if not passed
if ~exist('substodo', 'var')
    beh_cfg.substodo = [1 3 7];
    mode = 'visualize_decodings';
else
    % return data e.g. to setup a trans_res function to correlate this 
    % behavioural data against searchlight outcomes
    beh_cfg.substodo = substodo;
    mode = 'return_data';
end

%% Specify function for single subject decoding

beh_cfg.individual_decoding_func = @example_behavioural_decoding_individual;

%% Specify which measures should be used for decoding

% These are extracted in your version of example_get_all_confounds.m

% beh_cfg.decoding_measures{1} = {'curr.RT'}; % you could also specify multiple sets of measures
% beh_cfg.decoding_measures{2} = {'regexp:^prev.cue[0-9]*$'}; % also using regular expressions (marked by initial 'regexp:')

% A good idea might be to add one other small file that contains nothing
% but the decoding measures that you use. Like this, you can easily re-run
% all analyses if you e.g. add another decoding measure. In this case, the
% lines above change to
%
beh_cfg.decoding_measures = example_standard_decoding_measures();

%% Specify a function for a sanity check (optional)

beh_cfg.sanity_check_func = @example_sanitycheck;

%% Specify where to save results
beh_cfg.savedir = fullfile(pwd, 'results_example_behavioural_decoding');

%% Pass other parameters you need
% ...

%% add output to beh_cfg, if it exists
if exist('decoding_cfg_output', 'var')
    beh_cfg.decoding_cfg_output = decoding_cfg_output;
end

%% Do all
results = behavioural_decoding_batch(beh_cfg);

%% Analyse / use all data
if strcmp(mode, 'visualize_decodings')
    visualize_all_decodings(results);
else
    % do nothing, data will be returned
end