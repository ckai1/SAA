function decoding_measures = TaskRest_SAA1_standard_decoding_measures(mode)
% function decoding_measures = TaskRest_SAA1_standard_decoding_measures(mode)
%
% Standard SAA variables for TaskRest Exp
%
% This function simply returns some standard decoding measures as list of
% cell strings (and lists of cell strings for groups).
%
% If you only want to use one measure, you can pass it as simple string
% 'nanmean.curr.RT', (or as regular expression "use any field .." below)
%
% If you want to use multiple measures, add it as a cell inside the cell
% ("use both fields" below)
%
% IN OPTIONAL
%   mode: if 'use_summary_measures': 'nanmean.' will be put in front of all
%   measures, and 'nancount.' will be added to the first field. Default: ''
%
% OUT 
% decoding measure: 2n/2n+1 x 1 cellstring with n decoding measures,
%   potentially with regular expressions, plus m randn data
%
% Example: 
% decoding_measures = {
%       'nancount.curr.RT';                        % count (if you use a summary measure)
%       'nanmean.curr.RT';                        
%       'nanmean.prev.RT';                        
%       'regexp:^nanmean.curr.cue[0-9]*$';                      % use any cue field with a number (good for factorial variables that contain numbers)
%       'regexp:^nanmean.curr.cue[0-9]*$';                      % use any cue field with a number (good for factorial variables that contain numbers)
%       {'nanmean.curr.RT'; 'regexp:^nanmean.curr.cue[0-9]*$'}; % use both fields
%  }

%
% if use_summary_measure = 1:
%

%
% Otherwise the same without nancount/nanmean
%
% If you use summary measures, DEFINITIVELY include the number of
% datapoints used
%'nanmean.curr.RT';      
%
% SEE ALSO XXX_get_all_confounds

%% Confound defintion

% also change in get_all_confounds
% all (for MR pilot as of 22.10.2018)
confound_list = {
    ... % special part in design
    'name', {'NA'}, 'factorial';
    'trialnumb', -1, '';
    'sessionnumb', -1, '';
    'blocknumb', -1, '';
    'block_difficulty', '', 'factorial';
    'cue_img', 'NA', 'factorial';    
    ... % design
    'rotfirstobject', {'NA'}, 'factorial';
    'rotsecondobject', {'NA'}, 'factorial';
    'rotcondition', -1, 'factorial';
    'rotdifficulty', -1, '';
    'rottype', -1, 'factorial';
    'addfirstnumber', {'NA'}, 'factorial';
    'addsecondnumber', {'NA'}, 'factorial';
    'addresult', 'N', 'factorial';
    'addcondition', -1, 'factorial';
    'adddifficulty', -1, '';
    'addtype', -1, 'factorial';
    'similarityword1', {'NA'}, 'factorial';
    'similarityword2', {'NA'}, 'factorial';
    'similarityword3', {'NA'}, 'factorial';
    'similaritycondition', -1, 'factorial';
    'similaritydifficulty', -1, '';
    'similaritytype', -1, 'factorial';
    ... % timing
    'starttrial_recorded', -1, '';
    'stimulus_on', -1, '';
    'stimulus_off', -1, '';
    ... % position 
    'pos', -1, '';
    'rot_pos', 'N', '';
    'sim_pos', 'N', '';
    'add_pos', 'N', '';
    ... % behavioural -- real trial task
    'buttonpress', 'N', 'factorial'; % pressed button
    ... %'KeyCode', -1*ones(1, 256), ''; % KeyCode: [1x256 double] % the a binary vector which keys were pressed during the response
	... %'buttondowntime', -1, ''; % time of button down (NOT reaction time) in s
    ...                       % subtract startrun_recorded for SPM
    'exp_response', 'N', 'factorial';
    'reactiontime', -1, ''; % reaction time in ms
    'accuracy', -1, '';
    ... % behavioural -- all potential tasks
    'rot_exp_response', 'N', 'factorial';
    'rot_accuracy', -1, '';
    'add_exp_response', 'N', 'factorial';
    'add_accuracy', -1, '';
    'sim_exp_response', 'N', 'factorial';
    'sim_accuracy', -1, '';
    };
% also change in get_all_confounds

%% set default
if ~exist('mode', 'var')
    mode = '';
end

%% automatic creation from above


% use all as curr and prev
decoding_measures = {};
dec_ind = 0;

for conf_ind = 1:size(confound_list, 1)
    for curr_prev = {'curr', 'prev'}
        curr_prev = curr_prev{1};
        if strcmp(mode, 'use_summary_measures')
            curr_prev = ['nanmean.' curr_prev];
        end
        
        confound = confound_list{conf_ind, 1};
        confound_default = confound_list{conf_ind, 2};
        confound_type = confound_list{conf_ind, 3};
        
        dec_ind = dec_ind + 1;
        if isempty(confound_type)
            decoding_measures{dec_ind} = [curr_prev '.' confound]; % e.g. curr.name
        elseif strcmp(confound_type, 'factorial') % create regexp from name
            decoding_measures{dec_ind} = ['regexp:^' curr_prev '.' confound '.']; % e.g. curr.name.
        end
        
        % in the first round, also add the same expression with nancount as
        % first list element
        if strcmp(mode, 'use_summary_measures') && dec_ind == 1
            decoding_measures{2} = decoding_measures{1};
            decoding_measures{1} = strrep(decoding_measures{1}, 'nanmean', 'nancount');
            dec_ind = dec_ind + 1;
        end
    end
end

% if you like, add further analyses, e.g. groups etc. below
% also add ONES regressor (simply each datapoint 1)
decoding_measures{end+1} = 'curr.ONES';
% add nansum % better would be nansum, that can replace count, but at the
% moment that should be identical
if strcmp(mode, 'use_summary_measures') % add nanmean infront if summary is used
    decoding_measures{end} = ['nanmean.' decoding_measures{end}];
end

% add random datasets
n_rand = 100;
% Change number of random sets in both:
% 1. get_all_confounds 2. standard_decoding_measures
for rand_ind = 1:n_rand
   decoding_measures{end+1} = ['curr.randn' sprintf('%05i', rand_ind)];
   if strcmp(mode, 'use_summary_measures')% add nanmean in front if summary is used
       decoding_measures{end} = ['nanmean.' decoding_measures{end}];
   end
end
