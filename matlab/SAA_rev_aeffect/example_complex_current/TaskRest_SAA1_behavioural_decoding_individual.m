% [result, decoding_cfg] = TaskRest_SAA1_behavioural_decoding_individual(subj, beh_cfg)
%
% Individual SAA CV decoding for TaskRest Exp, between Conditions 
% [Summe, Kongruent, Ähnlich]
%
% Called by TaskRest_SAA1_behavioural_decoding_MAIN
%
% IN
%   subj: subject number
% OPTIONAL
%   beh_cfg: a config struct that contains optional input. This can be used
%       to pass additional information to the subfunctions. If a sanity
%       check should be performed, this can be passe as:
%   beh_cfg.sanity_check_func: Function to perform a sanity check. This 
%       should be assigned like
%           beh_cfg.sanity_check_func = @mysanitycheckfunction;
%       and will be called like
%           beh_cfg.sanity_check_func(data, subj, beh_cfg);


function [result, decoding_cfg] = TaskRest_SAA1_behavioural_decoding_individual(subj, beh_cfg)

% Init optional variables
if ~exist('beh_cfg', 'var'),
    beh_cfg = [];
end
    
%% Set paths, if not set
%TaskRest_SAA1_addpaths();
%!!change
beh_cfg.dirs = TaskRest_SAA1_addpaths();

%% 1. Get behavioural & design data

% In general, the following steps could be all combined in one function.
% Our experience however shows that the different steps below make sense
% when multiple decodings are setup, so we decided to have all of them
% here as an example.
%
% Of course you are free to load the data in whichever way you want.
%
% The final outcome should be something like
%
% data.Sess(s).U(u)
%   with s: session number
%        u: condition index
% containing the name of the current condition as
%   data.Sess(s).U(u).name{1} = 'condition_name'
% and all potentially confounding values as subfields or sub-subfields.
%
% Example for s=1 and u=1:
%   data.Sess(s).U(u).name = {'Left'}
%   data.Sess(s).U(u).design_target = [1 2 3 4 5]
%   data.Sess(s).U(u).current_trial.RT = [1 2 3 4 5]
%   data.Sess(s).U(u).prev_trial.RT = [1 2 3 4 5]
%   data.Sess(s).U(u).mean.current_trial.RT = 3
%   data.Sess(s).U(u).mean.prev_trial.RT = 3


%% 1.1 Load trial numbers used (analogue to fMRI 1st level analysis)

% In general, you will create 
%   condition_trial_data.Sess(s).U(u).trialnr
%   condition_trial_data.Sess(s).U(u).name{1}
% including the trial numbers for YOUR dataset sorted by YOUR conditions
% (as you use them e.g. for a 1st level SPM analysis)
if strcmp(beh_cfg.cv_type, 'CV')
    data = TaskRest_SAA1_get_conditions(subj, beh_cfg);
elseif strcmp(beh_cfg.cv_type, 'CV_xset_difficulty')
    data = TaskRest_SAA1_get_conditions_xset(subj, beh_cfg);
end

%% 1.2 Get values from design & behavioural data for these trials

% We now use all trial numbers to get all information that we want to use
% as potential confounding variables. Often these are distributed across
% different files, so we have this function to get all we potentially want.
data = TaskRest_SAA1_get_all_confounds(data, subj, beh_cfg);

%% 1.3 Create dummy variables for factorials
display('Creating dummy variables from .factorial')
data = create_dummies(data);

%% 1.4 Create count & mean & variance for all?/interesting? fields
% DONT FORGET TO CHANGE DEFINITION OF decoding_measures!
% Potential TODO: Pull code to change definition of decoding_measures from 
%       TaskRest_SAA1_standard_decoding_measuresm.m into
%       add_summary_measures.m and update them according to summaries

if strcmp(beh_cfg.use_summary, 'fe')
    display('Creating counts and means')
    data = add_summary_measures(data); 
elseif isempty(beh_cfg.use_summary)
    % nothing to do
else
    error('Unkown summary mode "%s" please implement', beh_cfg.use_summary)
end

% Note: You cannot use summaries and trialwise decoding in one call of
% decoding below, because they have a different number of elements. Perform
% two SAA runs for that
%% Do sanitycheck (optional)

% Just to be sure that you really use the same trials that you wanted, make
% a quick sanity check. E.g., if you use SPM to extract beta images, make
% sure the onsets that have been extract from using your functions are the
% same as the onsets you used for SPM.

if isfield(beh_cfg, 'sanity_check_func') && ~isempty(beh_cfg.sanity_check_func)
    display(['Performing sanity check using ' func2str(beh_cfg.sanity_check_func)])
    beh_cfg.sanity_check_func(data, subj, beh_cfg);
    display('Sanitycheck did not produce errors, assuming all is fine')
end

%% Save if desired

if 0
    % TODO: Maybe add option to simply save data here <-- another good
    % reason to split this function here
end

%% TODO: Should we put everything above in a new function?? <-- most likely yes

%% 2. Create / modify existing design

% In the remainder, all changes that are necessary for decoding_tutorial
% are marked with "CHANGE". For your function, these are most likely the
% same.

%% initialize TDT & cfg
cfg = decoding_defaults();

%% Plot
% set handle to avoid having many figures open at the end
if isfield(beh_cfg, 'design_fighandle')
    cfg.fighandles.plot_design = beh_cfg.design_fighandle;
end

%% Data Scaling
% scale data equally (otherwise things might run really slowly and
% different dimensions might not be weighted equally)
cfg.scale.method = 'min0max1';
cfg.scale.estimation = 'all';

%% CHANGE cfg.result.dir 
%  Add e.g. a 'behavioural' subfolder to the result directory if you  like 
% to keep the individual results. All results will be saved as summary in
% the function above

% cfg.results.dir = ...  % your dir here
% cfg.results.dir = fullfile(cfg.results.dir, 'behavioural')
% write: Set 0 if you don't need the results written
cfg.results.write = 0;


%% Check that decoding measures are defined, otherwise ask if still in demo mode

if ~isfield(beh_cfg, 'decoding_measures')
    warning('No decoding measures are defined in beh_cfg.decoding_measures.')
    disp('Thats ok if you use the demo mode and you called the individual function. In this type "dbcont" to continue with some demo meaures.')
    disp('Otherwise type "dbquit" to quit or "dbstack" to debug and check why decoding_measure is not availble')
    keyboard
    % These are extracted in your version of example_get_all_confounds.m
    %beh_cfg.decoding_measures{1} = {'curr.RT'}; % you could also specify multiple sets of measures
    %beh_cfg.decoding_measures{2} = {'regexp:^prev.cue[0-9]*$'}; % also using regular expressions (marked by initial 'regexp:')
    beh_cfg.decoding_measures{1} = {'curr.reactiontime', 'curr.accuracy'}; % you could also specify multiple sets of measures
end

%% CHANGE design_from_spm --> extract_behavioural_data_and_masks

% exchange the line
% regressor_names = design_from_spm(beta_dir);
% by
[regressor_names, all_data] = extract_behavioural_data_and_masks(data.Sess, beh_cfg.decoding_measures);

% Remark: all_data already contains "masks" that will be retrieved after
% creating the design

%% CHANGE BETA_DIR
% set beta_dir as the entries of all_data.files.name
beta_dir = all_data.files.name;

%% Now, create the design / copy and paste the design creation

% Switch between different designs
if strcmp(beh_cfg.cv_type, 'CV') % standard CV design
    % Label names
    labelname1 = 'Summe';
    labelname2 = 'Kongruent';
    labelname3 = 'Ähnlich';

    % decoding_describe_data now just works as in TDT (this is why we 
    % exchanged design_from_spm and beta_dir above)
    cfg = decoding_describe_data(cfg,{labelname1 labelname2 labelname3},[1 2 3],regressor_names,beta_dir);

    % create CV design
    cfg.design = make_design_cv(cfg);

elseif strcmp(beh_cfg.cv_type, 'CV_xset_difficulty')
    display('Creating pairwise classification sets crossing simple/complex')
    
    for set_ind = 1:3
    
        if set_ind == 1
    
            labelinfo = {
                'Summe s', 1, 1;
                'Summe c', 1, 2;
                'Kongruent s', 2, 2;
                'Kongruent c', 2, 1;
                };
        elseif set_ind == 2
           labelinfo = {
            'Summe s', 1, 1;
            'Summe c', 1, 2;
            'Ähnlich s', 3, 2;
            'Ähnlich c', 3, 1;
            }; 
        elseif set_ind == 3
            labelinfo = {
            'Kongruent s', 2, 1;
            'Kongruent c', 2, 2;
            'Ähnlich s', 3, 2;
            'Ähnlich c', 3, 1;
            };
        end
        labelnames = labelinfo(:, 1);
        labels = [labelinfo{:, 2}];
        xclass = [labelinfo{:, 3}];

        % create design in new variable
        cfg1 = decoding_describe_data(cfg, labelnames, labels, regressor_names, beta_dir, xclass);
        % create xset design in both directions
        cfg1.files.twoway = 1;
        cfg1.design = make_design_xclass_cv(cfg1);
        
        % combine in original variable
        if ~isfield(cfg, 'design')
            cfg = cfg1;
        else
            cfg = combine_designs(cfg, cfg1);
        end
    end
else
    error('Unkown cv_type %s', beh_cfg.cv_type)
end
    
%% Set any additional parameters you like (and that make sense)
% You can most likely keep all the parameters you also had in your normal
% decoding script

% Maybe: save each cv step separately (if you did not do so
% cfg.design.set = 1:length(cfg.design.set);
% cfg.results.setwise = 1;

%% If decoding_cfg_output is passed, add it here
if isfield(beh_cfg, 'decoding_cfg_output')
    display('Using passed output')
    disp(beh_cfg.decoding_cfg_output)
    cfg.results.output = beh_cfg.decoding_cfg_output;
end

%% CHANGE: PUT THE FOLLOWING LINE DIRECTLY BEFORE DECOING 
% get passed data & incl. the mask for this design
% will change cfg.masks = 'ROI' so that the decoding measure masks can be
% used
[cfg, passed_data] = get_passed_data_incl_masks(cfg, all_data);

%% CHANGE: add "passed_data" to decoding(cfg)
[result, decoding_cfg] = decoding(cfg, passed_data);

% save decoding_cfg to return it to main
decoding_cfg.beh_cfg = beh_cfg;