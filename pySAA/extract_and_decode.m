function accuracies = extract_and_decode(beh_cfg, data)
% This function consists of a loop over the subject data, from which the
% data points that correspond to the decoding variables are extracted and
% decoded. It saves in a mat file the full information of the decoding
% process, and a float array with the output is returned.
% IN: beh_cfg: configuration file
%     data: If it does not exist, it is loaded fom beh_cfg

% if beh_cfg it is the path to the beh_cfg mat file
% if not, it is already a struct
if ischar(beh_cfg)
    beh_cfg = load(beh_cfg);
end

add_toolboxes_paths(beh_cfg)
if ~exist('data', 'var')
    data = load(beh_cfg.output_data);
end

%initialise cfg
cfg = decoding_defaults();
cfg.plot_design = 0;
cfg.scale.method = 'min0max1';
cfg.scale.estimation = 'all';
cfg.results.write = 0;

%get decoding variables sets
decoding_sets = read_decoding_sets(beh_cfg);
accuracies = zeros(length(decoding_sets), length(data.subjects));
% apply decoding function to every subject data
for subj_ind = 1:length(data.subjects)
    
    Sess = data.subjects(subj_ind).Sess;
    [results, decoding_cfg, accuracy] = process_subject(decoding_sets, Sess, cfg, beh_cfg);
    decoding_results.subj_results(subj_ind).results = results;
    decoding_results.subj_results(subj_ind).decoding_cfg = decoding_cfg;
    accuracies(:, subj_ind) = accuracy;
end

% create a desciption in decoding measure scripts
for d_ind = 1:length(decoding_sets)
    if ischar(decoding_sets{d_ind})
        % is already a string
        decoding_results.decoding_measures_str{d_ind} = decoding_sets{d_ind};
    else %create string
        decoding_results.decoding_measures_str{d_ind} = sprintf('%s ', decoding_sets{d_ind}{:});
    end
end

%save in a mat file
if isfield(beh_cfg, 'output_result')
    save(beh_cfg.output_result, '-struct', 'decoding_results');
end

end % end of function
