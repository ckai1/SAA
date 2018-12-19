% SAA 1 (CV) and 2 (XsetCV difficulty) for aeffect experiment
%
% IN (optional)
%   substodo: List of subjects todo (default in file)
%   cfg: 
%       cfg.decoding_output: output for decoding, e.g. 'accuracy'
%       cfg.mode: '' (default) or 'SIMULATION' (see in file)
%       cfg.cv_type: cv type, e.g. 'CV' (default) or 'CV xset difficulty' 
%           CV + but train on other  difficulty level (see in file)
% OUT
%  in subfolder of current directory
%       - mat files with individual SAA results
%       - summary figure over all SAA results

% When modifying SAA
% These files need to be adapted:
%   - example_behavioural_decoding_MAIN.m: This file
%   - Single subject file
%   - get subjhect
% 
%
% Author: Kai, Marc
% Kai, 2.10.2018

function results = TaskRest_SAA1_behavioural_decoding_MAIN(substodo, cfg)

%% Init beh_cfg
beh_cfg = [];

%% Set paths, if not set, and store
beh_cfg.dirs = TaskRest_SAA1_addpaths();

%% Set a name and description for the current decoding (optional)
beh_cfg.name = 'decode_blockcondition';
if exist('cfg', 'var') && isfield(cfg, 'cv_type')
    beh_cfg.cv_type = cfg.cv_type;
else
    beh_cfg.cv_type = 'CV'; %CV_xset_difficulty'; % 'CV': leave-one-run-out, decode main condition
                        % 'CV_xset_difficulty': CV + but train on other 
                        %       difficulty level
end
beh_cfg.name = [beh_cfg.name '_' beh_cfg.cv_type];

% MODE
if exist('cfg', 'var') && isfield(cfg, 'mode')
    beh_cfg.mode = cfg.mode;
else
    beh_cfg.mode = 'SIMULATION'; % 'SIMULATION': use data from simulation, '': experiment
end
if ~isempty(beh_cfg.mode)
    beh_cfg.name = [beh_cfg.name '_' beh_cfg.mode]; % add simulation tag to name
end

% SUMMARY DATA
if exist('cfg', 'var') && isfield(cfg, 'use_summary')
    beh_cfg.use_summary = cfg.use_summary; % 'runwise'; % '': use data trial-wise, 'runwise': use run-wise summay (nanmean, nancount); % maybe add: blockwise, not implemented yet
else
    beh_cfg.use_summary = ''; % 'runwise'; % '': use data trial-wise, 'runwise': use run-wise summay (nanmean, nancount); % maybe add: blockwise, not implemented yet
end
    
if ~isempty(beh_cfg.use_summary)
    beh_cfg.name = [beh_cfg.name '_' beh_cfg.use_summary]; % add summary tag to name
end

% generate a description to display
beh_cfg.decoding_str = ['SAA '  beh_cfg.cv_type ' ' beh_cfg.name ' [Summe, Kongruent, Ähnlich]'];


%% Define subjects 

% define subjects, if not passed
if ~exist('substodo', 'var')
    beh_cfg.substodo = 2:3;
    mode = 'visualize_decodings';
else
    % return data e.g. to setup a trans_res function to correlate this 
    % behavioural data against searchlight outcomes
    beh_cfg.substodo = substodo;
    mode = 'return_data';
end

%% Specify function for single subject decoding

beh_cfg.individual_decoding_func = @TaskRest_SAA1_behavioural_decoding_individual;

%% Specify which measures should be used for decoding

% These are extracted in your version of example_get_all_confounds.m

%beh_cfg.decoding_measures{1} = {'curr.RT'}; % you could also specify multiple sets of measures
%beh_cfg.decoding_measures{2} = {'regexp:^prev.cue[0-9]*$'}; % also using regular expressions (marked by initial 'regexp:')

% A good idea might be to add one other small file that contains nothing
% but the decoding measures that you use. Like this, you can easily re-run
% all analyses if you e.g. add another decoding measure. In this case, the
% lines above change to
%

if isempty(beh_cfg.use_summary)
    % use trialwise measures
    %beh_cfg.decoding_measures = TaskRest_SAA1_standard_decoding_measures();
    beh_cfg.decoding_measures{1} = {'curr.reactiontime', 'curr.accuracy'};
elseif strcmp(beh_cfg.use_summary, 'runwise')
    % use runwise summary
    beh_cfg.decoding_measures = TaskRest_SAA1_standard_decoding_measures('use_summary_measures');
else
    error('Unkown summary mode "%s" please implement', beh_cfg.use_summary)
end
    
%% Specify a function for a sanity check (optional)

% beh_cfg.sanity_check_func = @example_sanitycheck;

%% Specify where to save results
beh_cfg.savedir = fullfile(pwd, ['results_' beh_cfg.name]);

%% Pass other parameters you need
% ...

%% add output to beh_cfg, if it exists
if exist('cfg', 'var') && isfield(cfg, 'decoding_output')
    beh_cfg.decoding_cfg_output = cfg.decoding_output;
end

%% Do all
results = behavioural_decoding_batch(beh_cfg);

%% Analyse / use all data
% if strcmp(mode, 'visualize_decodings')
    visualize_all_decodings(results);
% else
    % do nothing, data will be returned
% end