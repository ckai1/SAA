function add_toolboxes_paths(beh_cfg)
% add path of SAA and TDT toolboxes and their subfolders
    addpath(genpath(beh_cfg.saa_path))
    addpath(genpath(beh_cfg.tdt_path))
end