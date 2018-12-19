function [decoding_cfg, sorteddata, passed_data, result, behavioural_result] = easy_demo(sorteddata, demo_cfg)

% function [decoding_cfg, sorteddata, passed_data, result, behavioural_result] = easy_demo(sorteddata, demo_cfg)
%
% This functions does everything that is needed to do a simple demo.
%
% If FACTORIAL variables are used, please use 
%   sorteddata = create_dummies(sorteddata) 
% before calling this function (and care about demo_cfg.decoding_measures)
%
% IN
%   data: data sorted into classes of form Sess.U (see demos)
%   demo_cfg:
%      REQUIRED fields:    
%          demo_cfg.decoding_measures required (as taken by behavioural decoding
%               toolbox, see demos)
%          demo_cfg.use_summary_values: 0 or 1
% OPTIONAL
%   demo_cfg.plot: 0 to surpress plots, 1 [default]
%       
% OUT
%   [decoding_cfg, sorteddata, passed_data, result, behavioural_result]
%
% behavioural_result: can be used as directly to create behavioural display
%   for the current demo like
%       visualize_all_decodings(behavioural_result);
%% Required input

decoding_measures = demo_cfg.decoding_measures;
use_summary_values = demo_cfg.use_summary_values;

%% Add TDT & Confound Detection Plugin
display('Adding TDT')
% addpath('/Users/kai/Documents/!Projekte/Decoding_Toolbox/trunk/decoding_betaversion');
if isempty(which('decoding')), error('TDT seems not been added successfully'), end

display('Adding TDT Confound Detection Addon'); addpath(fullfile(fileparts(which('easy_demo')), '../behavioural_decoding')); if isempty(which('behavioural_decoding_batch')), error('Confound Detection Addon seems not been added successfully'), end
if isempty(which('behavioural_decoding_batch')), error('Confound Detection Addon seems not been added successfully'), end

%% optional input
if ~isfield(demo_cfg, 'plot')
    demo_cfg.plot = 1;
end

%% Plot design
if demo_cfg.plot
    try
        % convert sorted Sess.U into trial data for display
        bede_plot_design(bede_convert_sortedU_to_trial(sorteddata)); % this may fail
    catch e
        e
        display('Plotting the design failed, probably because converting the sorted Sess.U structure to a table did not work. Dont worry to much.')
    end
end

%% Step 1: Collect sorted data
% Not necessary here, because we already created it in the necessary form
% above

%% Step 2: Create summary measures (if desired)

if use_summary_values
    display('Creating counts (nancount), sum (nansum), means (nanvar), variance (nanvar)')
    sorteddata = add_summary_measures(sorteddata, {'curr'});
else
    % do nothing
end

%% Step 3: Do a standard CV analysis analysis

% get TDT defaults
cfg = decoding_defaults();

% use scaling (dont use for demo, because it changes the parameter
% estimation of the classifier)
cfg.scale.method = 'none';
% cfg.scale.method = 'min0max1';
% cfg.scale.estimation = 'all';

% dont write results
cfg.results.write = 0;

% Dont use the kernel method, so that we can display the result easier at 
% the end of this demo. The results are exactly the same.
cfg.decoding.method = 'classification';

% get decoding accuracy minus chance and the model
cfg.results.output = {'accuracy_minus_chance', 'primal_SVM_weights', 'sensitivity', 'specificity'};

% switch off plotting in decoding (if set)
cfg.plot_design = demo_cfg.plot;

% use newton svm if libsvm does not work (e.g. mexfiles dont work)
if isempty(which('svmtrain'))
    warning('Using newton SVM')
    cfg.decoding.software = 'newton';
    cfg.decoding.train.newton_nu = 1; % needs hard estimation (0), won't work with soft estimation (-1)
    display(sprintf('Using NewtonSVM nu: %f', cfg.decoding.train.newton_nu))
end
%% get the data so that it can be passed to decoding_describe_data
    
[regressor_names, all_data] = extract_behavioural_data_and_masks(sorteddata.Sess, decoding_measures);

% set beta_dir as the entries of all_data.files.name
beta_dir = all_data.files.name;

%% describe that data and create a CV design
% as you will do for your decoding analysis
cfg = decoding_describe_data(cfg,{'A', 'B'},[-1 1],regressor_names,beta_dir);
cfg.design = make_design_cv(cfg);

%% switch of unbalanced data check, if necessary
% switch off check for equal amount of data
if ~use_summary_values
    cfg.design.unbalanced_data = 'ok';
end

%% also return the data for each step (for better insight)
cfg.design.set = 1:length(cfg.design.set);
cfg.results.setwise = 1;

%% Do the decoding
%% PUT THE FOLLOWING LINE DIRECTLY BEFORE DECOING 
% get passed data & incl. the mask for this design
% will change cfg.masks = 'ROI' so that the decoding measure masks can be
% used
[cfg, passed_data] = get_passed_data_incl_masks(cfg, all_data);

%  add "passed_data" to decoding(cfg)
[result, decoding_cfg] = decoding(cfg, passed_data);


%% Show results

% Display all calculated measures
for measure_ind = 1:length(demo_cfg.decoding_measures)
    curr_measure = demo_cfg.decoding_measures{measure_ind};
    result_ind = find(strcmp(sprintf('%s, ', curr_measure{:}), cfg.files.mask));
    % display expectation, if provided
    if isfield(demo_cfg, 'decoding_measures_expected_result')
        display(demo_cfg.decoding_measures_expected_result{measure_ind})
    end
    % display final DA as text
    disp(result.accuracy_minus_chance.output(result_ind))
    % show stepwise plot
    if demo_cfg.plot
        plot_decoding_steps_1d(cfg, passed_data, result, result_ind)
    end
end


%% Show standard behavioural decoding display (for single 'subject')
behavioural_result.subj_results(1).decoding_cfg = decoding_cfg;
behavioural_result.subj_results(1).results = result;
behavioural_result.subj_results(1).subjnr = 1;

behavioural_result.decoding_measures_str = demo_cfg.decoding_measures;

if demo_cfg.plot
    visualize_all_decodings(behavioural_result);
end
