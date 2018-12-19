%% Get a correlation target

curr_subj = 1;
dispv(1, 'Doing demo for demosubject %i',  curr_subj)

% define which result transformations we want
% currently accuracy_minus_chance and decision_values defintively work
% most others should work as well (you'll see if there is an error)

% decoding_cfg_output = {'accuarcy_minus_chance'};
decoding_cfg_output = {'decision_values'};

% here we use the behavioural decoding demo to get one

dispv(1, 'Getting the behavioural decoding for subject %i', curr_subj);
results = example_behavioural_decoding_MAIN(curr_subj, decoding_cfg_output) % lets only get it for subject 1
close all

%% Initialize correlation function with this data

dispv('Initialize correlation function with retrieved data')

if length(results.subj_results) > 1, error('This demo only works for 1 subject at the moment'), end

% we take the first values, what ever these are
target_id = 1;

target_description = results.decoding_measures_str{target_id}; % get the name of the first target

if strcmp(decoding_cfg_output{1}, 'decision_values')
    
    decision_values = results.subj_results.results.(decoding_cfg_output{1}).output.decision_value;
    correlation_target_values = vertcat(decision_values{:}); % add all decision values to one list

else
    setdata = results.subj_results.results.(decoding_cfg_output{1}).set;
    correlation_target_values = nan(size(setdata));
    for set_ind = 1:length(setdata)
        correlation_target_values(set_ind) = setdata(set_ind).output(target_id);
    end
   
end

% use these to initialize a new transres object
dispv(1, 'Using this as correlation target in a new transres correlation object')
transres_correlation_obj = transresclass_output_similarity(correlation_target_values);

% set further details
% transres_correlation_obj.similarity_measure = 'euclidean'; % input to pdist, default here: 'correlation'
transres_correlation_obj.correlate_against_method = decoding_cfg_output{1}; % default: accuracy_minus_chance

if strcmp(decoding_cfg_output{1}, 'decision_values')
    transres_correlation_obj.granularity = 'all';
end

% redo everything, but add the generated function to the results
% transformations
dispv(1, 'Passing this object to be used as an entry in cfg.result.output')
new_output = results.subj_results.decoding_cfg.results.output; % old output
new_output{end+1} = transres_correlation_obj;

display(['Name for output: ' char(transres_correlation_obj)])

% This will be set to
%   cfg.results.output = new_output;
% later.

%% Do the decoding again, this time with the new output
dispv(1, 'Do the decoding again, this time with the new output. This could of course also be neuroimaging data instead.')
results = example_behavioural_decoding_MAIN(curr_subj, new_output);

%% Display result
display(['--- SIMILARITY RESULT ---'])
display(['Remark 1: nans in results.subj_results.results.' (char(transres_correlation_obj)) '.set are meaningless'])
display(['Remark 2: The result values are SIMILARITY values (e.g. 1-correlation, NOT e.g. direct correlation values. Thus, for correlation, 0 means perfect correlation, 1 means no correlation, 2 perfect anticorrelation'])
display('Similarity calculated for measures:')
results.decoding_measures_str
display('Resulting similarity for these measures:')
results.subj_results.results.(char(transres_correlation_obj)).output