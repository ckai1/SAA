% This file contains the function prepare_data, and the helper functions
% preprocess_struct and apply_functions
% prepare_data is called at the beginning of the process, to build a data
% structure with data from tsv files, that can be used for decoding.

function prepare_data (beh_cfg)
%%
% this function parses data from tsv files into a data structure that can
% be used for decoding. It obtains parameters by reading from beh_cfg which
% can be either a structure or the path to it. The data undergoes a
% preprocessing step in which non existing values are replaced by specified
% default values, and ordinal variables are expanded. Also, if the
% configuration file includes user specified functions, they are applied to
% the data. Finally the data is saved on the specified output path.
% IN: beh_cfg
%     struct with parameters necessary for the data processing, or 
%     path to this struct.
%%

% if beh_cfg it is the path to the beh_cfg mat file
% if not, it is already a struct
if ischar(beh_cfg)
    beh_cfg = load(beh_cfg);
end

%scan the BIDS folder structure to extract the data file names
files = dir(beh_cfg.path);
subfolders = files([files.isdir]); subfolders(1:2) = [];
paths=cell(1, length(subfolders));
subs_to_process = beh_cfg.substodo;

for subfolder_ind = 1:length(subfolders)
    name_split = strsplit(subfolders(subfolder_ind).name,'-');
    if ~strcmp(name_split{1}, 'sub') || length(name_split) ~= 2
        continue
    end
    curr_subjnr = str2double(name_split{2});
    if ~ismember(curr_subjnr, beh_cfg.substodo)
        warning('Not processing subject %d as it is not in substodo', curr_subjnr)
        continue
    end
    
    for sub_subfolder_ind=1:length(subfolders)
        subject_folder = fullfile(beh_cfg.path, subfolders(subfolder_ind).name);
        files_sub = dir(subject_folder);
        subj_folder = files_sub([files_sub.isdir]);
        subj_folder(1:2) = [];
        % no session folder (only one session)
        if length(subj_folder)== 1 && strcmp(subj_folder.name, 'fmri')
           paths{sub_folder_ind}{1} = fullfile(subject_folder, 'fmri', 'data.tsv');
        % multiple sessions
        else
            for session_idx=1:length(subj_folder)
                session_folder = fullfile(subject_folder, subj_folder(session_idx).name, 'fmri', 'data.tsv');
                paths{subfolder_ind}{session_idx} = session_folder;
            end
        end
    end
    subs_to_process(subs_to_process == curr_subjnr) =[];
end

%remove empty cells if any
paths = paths(~cellfun('isempty', paths));
if ~isempty(subs_to_process)
    warning('not processing subjects: %d, folder not found \n', subs_to_process(:))
end
% set variable to add previous values if desired
if isfield(beh_cfg, 'previous_on')
   previous_on =  beh_cfg.previous_on;
else
    previous_on = false;
end
% get the data from the tsv files sorted by condition
data = sort_tsv_files(paths, previous_on);
% replace default values
data = preprocess_struct(data, beh_cfg);
%apply functions from beh_cfg
data = apply_functions(data, beh_cfg);

%save in a mat file
if isfield(beh_cfg, 'output_data')
    save(beh_cfg.output_data, '-struct', 'data');
end
end %end of function


function data = preprocess_struct(data, beh_cfg)
%%
% This function loops over the data structure to replace the unspecified
% values ('n/a') with the value specified in beh_cfg.desprition_file. It
% should also handle the ordinal expansion.
% IN:  -data
%       struct of the form subject.Sess.U.SAAdata
%      -beh_cfg
%       struct with parameters necessary for preprocessing
% OUT: -data
%       struct with ordinal values expanded #TODO and non existing values
%       replaced
% note: the default values shoul be parsed. Right now they are replaced as chars.
%       this is problematic if the ordinal expansion is missing.
% ordinal expansion missing #TODO
%%
struct_defaults = {};
fid = fopen(beh_cfg.description_file, 'r', 'n', 'ISO-8859-1');
if fid == -1
    error('Description file could not be open, check configuration JSON file')
end
while true
    % read until EOF
   values = fgetl(fid);
   if values == -1
       fclose(fid);
       break;
   end
   % separate by tabs and remove empty values
   values = strsplit(values, '\t');
   values = values(~cellfun(@isempty, values));
   struct_defaults(end + 1, 1)= values(1);
   struct_defaults(end, 2) = values(2);
end

%replace every 'n/a' value for the correspondent default value
for sub_ind=1:length(data.subjects)
    for sess_ind=1:length(data.subjects(sub_ind).Sess)
        for u_ind=1:length(data.subjects(sub_ind).Sess(sess_ind).U)
            for var_ind=1:length(data.subjects(sub_ind).Sess(sess_ind).U(u_ind).SAAdata)
                entry = data.subjects(sub_ind).Sess(sess_ind).U(u_ind).SAAdata(var_ind);
                if startsWith(entry.variable, 'prev_')
                    variable = extractAfter(entry.variable, 'prev_');
                else
                    variable = entry.variable;    
                end
                
                default = struct_defaults((strcmp(struct_defaults(:, 1), variable)), 2);
                entry.data_points(strcmp(entry.data_points, 'n/a')) = default;
                data.subjects(sub_ind).Sess(sess_ind).U(u_ind).SAAdata(var_ind) = entry;
            end
        end
    end
end

end 
%%
function data = apply_functions(data, beh_cfg)
% if there are functions specified in the configutation file
% they are tried to be applied sequentially to the data
for f_ind=1:length(beh_cfg.functions)
    func = beh_cfg.functions(f_ind).func;
    args = beh_cfg.functions(f_ind).args;
    try
        if isempty(args)
            data = func(data);
        else
            data = func(data, args{:});
        end
    catch
        warning('could not execute %s', func2str(func));
        continue
    end

end
end % end of function