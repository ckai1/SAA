function [result, decoding_cfg, accuray] = process_subject(decoding_sets, Sess, cfg, beh_cfg)
% This is a wrapper function that chooses between two options for decoding.
% The faster option extracts data and masks from the decoding sets and
% performs a decoding procedure on the data. The slower option loops over
% each decoding set and applies a user specified decoding function to the
% data.
% IN:
%   decoding_sets: cell array where each element is a list of SAA variables
%   Sess: struct with the data of the sessions fom a specific user
%   cfg: struct with decoding default parameters
%   beh_cfg: user defined parameters

  if isfield(beh_cfg, 'use_own_decoding') && beh_cfg.use_own_decoding
     [result, decoding_cfg, accuray] = process_subject_slower(decoding_sets, Sess, cfg, beh_cfg);
 else 
     [result, decoding_cfg, accuray] = process_subject_faster(decoding_sets, Sess, cfg, beh_cfg);
 end
end % end of function


%%
function [result, decoding_cfg, accuracy] = process_subject_faster(decoding_sets, Sess, cfg, beh_cfg)

%extract data
[all_data, regressor_names] = data_extraction(Sess, decoding_sets);

% describe and create design
beta_dir = all_data.files.name;
labels = 1:length(beh_cfg.labelnames);
cfg = decoding_describe_data(cfg, beh_cfg.labelnames, labels, regressor_names, beta_dir);
cfg.design = make_design_cv(cfg);
if isfield(beh_cfg, 'unbalanced_data')
    cfg.design.unbalanced_data = beh_cfg.unbalanced_data;
end


[cfg, passed_data] = get_passed_data_incl_masks(cfg, all_data);
% decode
[result, decoding_cfg] = decoding(cfg, passed_data);
decoding_cfg.beh_cfg = beh_cfg;
accuracy = result.accuracy_minus_chance.output;

end % end of function

%% slower with loop ('intuitive' version)
function [collected_results, collected_cfgs, accuracy] = process_subject_slower(decoding_sets, Sess, cfg, beh_cfg)
decoding_analysis = eval(['@'  beh_cfg.decoding_function]);
for set_ind = 1:length(decoding_sets)

    [result, decoding_cfg] = decoding_analysis(decoding_sets(set_ind), Sess, cfg, beh_cfg);
    % post: manage & collect results
    collected_results{set_ind} = result;
    collected_cfgs{set_ind} = decoding_cfg;
    collected_cfgs{set_ind}.beh_cfg = beh_cfg;
end
all_results = [collected_results{:}];
accuracy_minus_chance = [all_results.accuracy_minus_chance];
accuracy = [accuracy_minus_chance.output]';

end % end of function