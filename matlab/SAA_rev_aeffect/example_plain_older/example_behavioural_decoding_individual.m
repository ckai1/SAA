% [result, decoding_cfg] = example_behavioural_decoding_individual(subj, beh_cfg)
%
% This function is a template that leads you through the different steps of
% performing decoding using the Same Analysis Approach for one single
% subject. If multiple subjects should be analysed, this function will be
% called by example_behavioural_decoding_MAIN. We suggest to first make
% this function work for a given subject, and then adapt the main function.
%
% All important steps are described below, including details on what to do
% in each step.
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


function [result, decoding_cfg] = example_behavioural_decoding_individual(subj, beh_cfg)

% Init optional variables
if ~exist('beh_cfg', 'var'),
    beh_cfg = [];
end
    
%% Set paths, if not set
example_addpaths();

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

% In this example, example_get_condition gets
%   condition_trial_data.Sess(s).U(u).trialnr
%   condition_trial_data.Sess(s).U(u).name{1}
% for Conditions
%   1: (u==1): 'Left'
%   2: (u==2): 'Right'
% from the example_data() dataset

data = example_get_conditions(subj, beh_cfg);

% In general, you will create 
%   condition_trial_data.Sess(s).U(u).trialnr
%   condition_trial_data.Sess(s).U(u).name{1}
% including the trial numbers for YOUR dataset sorted by YOUR conditions
% (as you use them e.g. for a 1st level SPM analysis)


%% 1.2 Get values from design & behavioural data for these trials

% We now use all trial numbers to get all information that we want to use
% as potential confounding variables. Often these are distributed across
% different files, so we have this function to get all we potentially want.

data = example_get_all_confounds(data, subj, beh_cfg);

%% 1.3 Create dummy variables for factorials
display('Creating dummy variables from .factorial')
data = create_dummies(data);

%% 1.4 Create count & mean & variance for all?/interesting? fields
display('Creating counts, means, variance (when suitable)')
data = add_summary_measures(data, 'curr');

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
    beh_cfg.decoding_measures{1} = {'curr.RT'}; % you could also specify multiple sets of measures
    beh_cfg.decoding_measures{2} = {'regexp:^prev.cue[0-9]*$'}; % also using regular expressions (marked by initial 'regexp:')
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

% Label names
labelname1 = 'Left';
labelname2 = 'Right';

% decoding_describe_data now just works as before (this is why we exchanged
% design_from_spm and beta_dir above
cfg = decoding_describe_data(cfg,{labelname1 labelname2},[-1 1],regressor_names,beta_dir);

% create CV design
cfg.design = make_design_cv(cfg);

%% Set any additional parameters you like (and that make sense)
% You can most likely keep all the parameters you also had in your normal
% decoding script

% Maybe: save each cv step separately (if you did not do so
cfg.design.set = 1:length(cfg.design.set);
cfg.results.setwise = 1;

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