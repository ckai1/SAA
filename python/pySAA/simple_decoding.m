function [result, decoding_cfg] = simple_decoding(decoding_set, Sess, cfg, beh_cfg)
    % pre-call: select data
    [data_from_set, regressor_names] = data_extraction(Sess, decoding_set); % getting regressor names could be pulled out of the loop, but currently its in the same function
    
    % call: do processing with this data
    % describe and create desig (actually not necessary for different data)
    beta_dir = data_from_set.files.name;
	labels = 1:length(beh_cfg.labelnames)
    cfg = decoding_describe_data(cfg, beh_cfg.labelnames, labels, regressor_names, beta_dir);
    cfg.design = make_design_cv(cfg);
    if isfield(beh_cfg, 'unbalanced_data')
        cfg.design.unbalanced_data = beh_cfg.unbalanced_data;
    end
    
    [cfg, passed_set_data] = get_passed_data_incl_masks(cfg, data_from_set);
    % decode
    [result, decoding_cfg] = decoding(cfg, passed_set_data);
end % end of function