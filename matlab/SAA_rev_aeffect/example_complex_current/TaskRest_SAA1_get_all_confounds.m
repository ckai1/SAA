% function data = example_get_all_confounds(data, subj, beh_cfg)
%
% Extract potential confounds from the trials numbers in data.Sess.U.
%
% IN
%   data: struct containing trial numbers and names for each codition in
%       data.Sess(sess_ind).U(u_ind) as fields
%       data.Sess(sess_ind).U(u_ind).name{1}: name of condition
%       data.Sess(sess_ind).U(u_ind).trialnr: numbers of current trial
%   subj: subj nr, in case it's needed (e.g. to load data)
%   beh_cfg: cfg struct, in case it's needed (e.g. to load data)
%
% OUT
%   data: augmented input by behavioural & design data as subfields of
%       data.Sess(sess_ind).U(u_ind), that contain k (number of patterns)
%       elements for the same class, e.g.
%
%           data.Sess(1).U(1).curr.RT = [1.4 3.0 2.7 2.0]
%
%       for 4 different examples. In general, each field contains d x k
%       examples (with d the dimension, see next).
%
% DATA TYPES and MULTI-DIMENSIONAL DATA
%   Some covarites might be multidimensional or have other types. You can
%   put these in data.Sess as follows:
%
%   HIGH(er) D:
%     data.Sess(1).U(1).curr.cue1(:, trial_ind) = [1; 3; 6]
%       i.e. cue1 needs to be a d x k matrix (d: dimension of each pattern, k: number of patterns)
%
%   Datatypes:
%       Numerics: work
%       Single letters: should work, too, especially if you use dummy coding
%           (see factorial variables below)
%       Other types are rather experimental, so they are not included here.
%       In general, I would highly recommend to simply recode other
%       variables before using them as data. This should avoid
%       interpretation and analysis problems.
%
%
% ADDITIONAL INFOS
%   FACTORIAL VARIABLES
%   all subfields of .factorial can be expanded using dummy variables using
%       data = create_dummies(data);
%   Example:
%       data.Sess(1).U(1).factorial.curr.cue = [7 7 9 9]
%       data = create_dummies(data)
%   leads to
%       data.Sess(1).U(1).curr.cue7 = [1 1 0 0]
%       data.Sess(1).U(1).curr.cue9 = [0 0 1 1]
%
%   AUTOMATIC SUMMARY MEASURES
%   count, mean, var, etc of each session can be automatically added for all
%   fields  using
%       data = add_summary_measures(data);
%
% SEE ALSO XXX_standard_decoding_measures
% 
% Author: Kai, v2013-10-14
%   Update
%       Kai, v2018-06-07: Includes semi-automatic construction from list

% potential additional measures (just a random list):
%
% .curr & .prev
%   absolute timing (probably pretty hard to find out)
%   alternatively: timing in terms of images (for this, we need to know how
%   long each session is)
%
% .prev
%   relative time: timing relative to current event, e.g. -current cue
%   onset

function data = TaskRest_SAA1_get_all_confounds(data,  subj, beh_cfg)
%%
display(sprintf('Getting potential confounds for subj %i', subj))

%% load design & behavioural data

% Corina_WH: loads my_experiment variable with information in .run()
% switch between real data and simulation
% ON CHANGE: ALSO CHANGE IN extract_data_TaskRestExp.m
if isfield(beh_cfg, 'mode') && strcmp(beh_cfg.mode, 'SIMULATION')
    logfile_name = sprintf('log_VP%imode1.mat', subj);
else
    logfile_name = sprintf('log_VP%i.mat', subj);
end
%datafile = fullfile(beh_cfg.dirs.base_dir, 'TaskRestExp/logs/', logfile_name);
%!!change
datafile = fullfile(beh_cfg.dirs.base_dir, 'Example_data/', logfile_name);
my_experiment = get_log(datafile);

%% List of variables or variable groups to test incl. default
% you can implement how to deal with them below

% Maybe adapt standard_decoding_measures.m, too
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
    ... % 'buttonpress', 'N', 'factorial'; % pressed button
    ... %'KeyCode', -1*ones(1, 256), ''; % KeyCode: [1x256 double] % the a binary vector which keys were pressed during the response
	'buttondowntime', -1, ''; % abs. time of button down in s (NOT reaction time) 
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
% Maybe adapt standard_decoding_measures.m, too


%% all sessions, all conditions, all trials
for sess_ind = 1:length(data.Sess)
    for cond_ind = 1:length(data.Sess(sess_ind).U)
        ntrials = length(data.Sess(sess_ind).U(cond_ind).trialnr);
        display(sprintf('Sess(%i).U(%i).name{1}=''%s'': Adding data for %i trials', sess_ind, cond_ind, data.Sess(sess_ind).U(cond_ind).name{1}, ntrials))
        
        % go through all trials of current cell
        for trial_ind = 1:ntrials
            %% Map all the data you like from the input data to data.Sess
            
            % do the same for current and previous
            for curr_prev = {'curr', 'prev'}
                curr_prev = curr_prev{1};
                
                if (strcmp(curr_prev, 'curr') && (trial_ind > 0)) || (strcmp(curr_prev, 'prev') && (trial_ind > 1))
                    % get number of current trial
                    % important: USE trial_ind and curr_trialnr INVERTED BELOW (to access the trial data)
                    if strcmp(curr_prev, 'curr')
                        trial_nr = data.Sess(sess_ind).U(cond_ind).trialnr(trial_ind);
                    elseif strcmp(curr_prev, 'prev')
                        % get current trial data
                        trial_nr = data.Sess(sess_ind).U(cond_ind).trialnr(trial_ind-1);
                    end
                    curr_trial_data = my_experiment.run(sess_ind).trial(trial_nr);
                else
                    trial_nr = 0;
                    curr_trial_data = [];
                end
                
                
                %% Go through confounds
                for conf_ind = 1:size(confound_list, 1)
                    confound = confound_list{conf_ind, 1};
                    confound_default = confound_list{conf_ind, 2};
                    confound_type = confound_list{conf_ind, 3};
                    
                    % GET DEFAULT AND INFO FOR CURRENT CONFOUND
                    % special: name (for old version)
                    if strcmp(confound, 'name') && ~isempty(curr_trial_data) && ~isfield(curr_trial_data, 'name')
                        warning('OldData:CueInfo', 'Old data, remove if not necessary anymore. Adding name cue info');
                        warning('off', 'OldData:CueInfo');
                        try
                            blocknumb = ceil(trial_nr/12);
                            curr_trial_data.name = my_experiment.run(sess_ind).cues{blocknumb}(1:end-1);
                        catch
                            % first trial or field not defined
                            curr_trial_data.name = ''; % replaced by default below
                        end
                    end
                    % special: trial number (for old version)
                    if strcmp(confound, 'trialnumb') && ~isempty(curr_trial_data) && ~isfield(curr_trial_data, 'trialnumb')
                        warning('OldData:TrialNr, remove if not necessary anymore. Adding trial number')
                        warning('off', 'OldData:TrialNr');
                        curr_trial_data.trialnumb = trial_nr;
                    end
                    % special: trial number (for old version)
                    if strcmp(confound, 'sessionnumb') && ~isempty(curr_trial_data) && ~isfield(curr_trial_data, 'sessionnumb')
                        warning('OldData:SessionInd', 'Old data, remove if not necessary anymore. Adding session index')
                        warning('off', 'OldData:SessionInd');
                        curr_trial_data.sessionnumb = sess_ind;
                    end
                    % special: block number (for old version)
                    if strcmp(confound, 'blocknumb') && ~isempty(curr_trial_data) && ~isfield(curr_trial_data, 'blocknumb')
                        warning('OldData:blocknumb', 'Old data, remove if not necessary anymore. Adding blocknumb')
                        warning('off', 'OldData:blocknumb');
                        blocknumb = ceil(trial_nr/12);
                        curr_trial_data.blocknumb = blocknumb;
                    end
                    
                    % if data exists, check if field exist, else throw
                    % error (alternative: put default value below
                    if ~isempty(curr_trial_data) && ~isfield(curr_trial_data, confound)
                        %error('Could not find field %s in current trial', confound)
                        %%!!change
                        warning('GetConfounds:FieldEmptyUsingDefault', 'Field %s is empty, using default value', confound)
                        curr_trial_data.(confound) = confound_default;
                    end
                    
                    % GET DATA FOR CURRENT CONFOUND or use default from above
                    % determine what to put in struct
                    if ~isempty(curr_trial_data) && ~isempty(curr_trial_data.(confound))
                        % trial data exists and has data, use it
                        % special treatments
                        if strcmp(confound, 'name')
                            curr_dat = curr_trial_data.(confound)(4); % use the forth letter of the name only
                        else
                            % the standard way: just use data from field
                            curr_dat = curr_trial_data.(confound);
                        end
                    elseif ~isempty(curr_trial_data) && isempty(curr_trial_data.(confound))
                        % field exists but is empty, use default
                        warning('GetConfounds:FieldEmptyUsingDefault', 'Field %s is empty, using default value', confound)
                        curr_dat = confound_default;
                    else
                        % no trial data exists, use default
                        curr_dat = confound_default;
                    end
                    
                    % check for buttonpress if multiple buttons where
                    % pressed, if so, change to X
                    if strcmp(confound, 'buttonpress') && length(curr_dat) > 1
                        curr_dat = {'X'}; % replace by X
                    end
                    dbstop if error
                    
                    % determine where to put data in struct
                    % examples for evaluation below:
                    %   factorial prev name:
                    %       data.Sess(sess_ind).U(cond_ind).factorial.prev.name(trial_ind)
                    %   standard curr trialnr
                    %       data.Sess(sess_ind).U(cond_ind).factorial.prev.trialnr(trial_ind)
                    if isempty(confound_type)
                        data.Sess(sess_ind).U(cond_ind).(curr_prev).(confound)(trial_ind) = curr_dat;
                    elseif strcmp(confound_type, 'factorial')
                        if ~ischar(curr_dat)
                            data.Sess(sess_ind).U(cond_ind).factorial.(curr_prev).(confound)(trial_ind) = curr_dat;
                        else % save char as list entry
                            data.Sess(sess_ind).U(cond_ind).factorial.(curr_prev).(confound)(trial_ind) = {curr_dat};
                        end
                    else
                        error(['Unkown confound type ' confound_type])
                    end
                    
                end
            end
            
            % also add ONES regressor (simply each datapoint 1)
            % suffices for curr only
            data.Sess(sess_ind).U(cond_ind).curr.ONES(trial_ind) = 1;
            
            % also add radomized Null data (Gaussian noise)
            % suffices for curr only
            n_rand = 100;
            sprintf('Adding %i random data sets (randn)', n_rand);
            % Change number of random sets in both:
            % 1. get_all_confounds 2. standard_decoding_measures
            rng('shuffle'); % random initialisation using the clock (see help rng)
            % rng('default'); % would always return the same random numbers
            for rand_ind = 1:n_rand
                data.Sess(sess_ind).U(cond_ind).curr.(['randn' sprintf('%05i', rand_ind)])(trial_ind) = randn;
            end
            %% end all sessions, all conditions, all trials
        end
    end
end