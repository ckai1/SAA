% Function to set pathes for behavioural decoding analyses for aeffect 218

function dirs = TaskRest_SAA1_addpaths()

% find path to base directory (svn root folder "Corinna_WH")
% add your path here if its not included yet
% if you like you can set the path to TDT below
poss_base_dirs = {
    '/Users/admin/Desktop/svn_rep/Corina_WH/';
    'H:\projects\aeffect_218\Corina_WH';
    'C:\Users\lea\Desktop\aeffect_218\Corina_WH';
    'C:\Users\danielv\Dropbox\labroation_SAA\';
    };


% check base directory
for pdb_ind = 1:length(poss_base_dirs)
    curr_dir = poss_base_dirs{pdb_ind};
    if exist(curr_dir, 'dir')
        base_dir = curr_dir;
        display(sprintf('Basedir detected: %s', base_dir));
        dirs.base_dir = base_dir; % return
        break; % use this directory
    end
end
if ~exist('base_dir','var')
    error('Could not detect directory to base directory, please add it to list in this file')
end

%addpath(fullfile(base_dir, '..', 'Analysis', 'behavioural_decoding')) % add behavioural_decoding to path
%addpath(fullfile(base_dir, '..', 'Analysis', 'SAA1')); % Path to this analysis
addpath(fullfile(base_dir, 'SAA_rev_aeffect', 'behavioural_decoding')) % add behavioural_decoding to path
addpath(fullfile(base_dir, 'Example_data')); % Path to this analysis
%% Add TDT

% find path to TDT directory
% add your path here if its not included yet
poss_TDT_dirs = {
    'H:\projects\decoding_tool\trunk\decoding_toolbox';
    'C:\Users\danielv\Documents\LabRotation\decoding_toolbox_v3.994';
    };

for pdb_ind = 1:length(poss_TDT_dirs)
    curr_dir = poss_TDT_dirs{pdb_ind};
    if exist(curr_dir, 'dir')
        display(sprintf('TDT directory detected: %s', base_dir));
        addpath(curr_dir);
        break; % use this directory
    end
end
% check that TDT is in path
if isempty(which('decoding_defaults'))
    error('decoding_defaults.m (TDT Decoding Toolbox) not found in path, please add')
else
    % return path
    dirs.TDT = fileparts(which('decoding_defaults')); % return TDT dir
end

% Probably not necessary
% % check that SPM is in path
% if isempty(which('spm'))
%     error('SPM.m (SPM) not found in path, please add')
% end

