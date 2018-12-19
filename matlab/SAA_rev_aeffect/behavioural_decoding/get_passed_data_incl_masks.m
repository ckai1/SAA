% function [cfg, passed_data] = get_passed_data_incl_masks(cfg, all_data)
%
% A function to prepare a confound / behavioural decoding.
% Works only in combination with  
%
%   extract_behavioural_data_and_masks().
% 
% See there how to use (or better follow the examples).

function [cfg, passed_data] = get_passed_data_incl_masks(cfg, all_data)

%% Getting mapping from cfg.files.name to all_data.files.name
dispv(1, 'Getting mapping from cfg.files.name to all_data.files.name')
mapping = nan(length(cfg.files.name), 1);

for cfg_file_ind = 1:length(cfg.files.name)
    curr_cfg_name = cfg.files.name{cfg_file_ind};
    % find exact filename in all_data
    all_data_file_ind = find(strcmp(curr_cfg_name, all_data.files.name));
    % check that we found exactly 1 entry
    if isempty(all_data_file_ind)
        error('Could not find cfg.file.name{%i} = %s in all_data.files.name', cfg_file_ind, curr_cfg_name)
    elseif length(all_data_file_ind) > 1
        error('Found multiple entries for cfg.file.name{%i} = %s in all_data.files.name (in rows:%s)', cfg_file_ind, curr_cfg_name, sprintf(' %i', all_data_file_ind))
    else % everything fine, save
        mapping(cfg_file_ind) = all_data_file_ind;
    end
end

if any(isnan(mapping))
    error('Some entries in mapping are still none, please check why')
end

%% apply mapping to fields
dispv(1, 'Applying mapping to fields')
passed_data.data = all_data.data(mapping, :);
passed_data.files.name = all_data.files.name(mapping);
passed_data.files.step = all_data.files.step(mapping);
% copy general info (not mapped)
passed_data.mask_index = all_data.mask_index;
passed_data.hdr = all_data.hdr;
passed_data.dim = all_data.dim;

%% add mask info
cfg.files.mask = all_data.files.mask;
passed_data.files.mask = all_data.files.mask;
% add mask content
passed_data.masks = all_data.masks; % old version
% convert to new version (doesnt heart to have both
dispv(1, 'Filling passed_data.mask_index_each with data from passed_data.mask_data.masks');
passed_data.mask_index = 1:length(all_data.masks.mask_data{1});
for m_ind = 1:length(all_data.masks.mask_data)
    passed_data.mask_index_each{m_ind} = find(all_data.masks.mask_data{m_ind});
end

%% cfg.analysis = 'ROI'
if ~strcmp(cfg.analysis, 'ROI')
    warning('get_passed_data:Changing_to_ROI', 'Setting cfg.analysis = ''ROI'' so that the decoding measure masks can be used')
    cfg.analysis = 'ROI';
end

%% TODO: Update to new version (files.chunk instead of files.step)
% at the moment, use both, files.chunk & files.step

warning('For the transition to the new version only: Using BOTH, cfg.files.step (old) & cfg.files.chunk (new)')
if isfield(cfg.files, 'chunk')
    cfg.files.step = cfg.files.chunk;
else
    cfg.files.chunk = cfg.files.step;
end

warning('For the transition to the new version only: Using BOTH, passed_data.files.step (old) & passed_data.files.chunk (new)')
passed_data.files.chunk = passed_data.files.step;

%% Check that files in passed_data and cfg correspond
dispv(1, 'Checking cfg.files.name and .step against passed_data.files.name and .step')
if ~isequal(cfg.files.name, passed_data.files.name)
    error('cfg.files.name and passed_data.name do not agree, please check (maybe only the orientation is wrong somewhere)')
elseif ~isequal(cfg.files.step, passed_data.files.step) 
    error('cfg.files.step and passed_data.files.step do not agree, please check (maybe only the orientation is wrong somewhere)')
end
%% copy remaining entries from cfg.files to passed_data.files
dispv(1, 'Copying remaining entries of cfg.files to passed_data.files')
passed_data.files = cfg.files;