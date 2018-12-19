% function data = extract_data_TaskRestExp(subj, beh_cfg)
%
% Load data from logfiles for TaskRestExp as struct with a SPM coding style
%
% IN
%   subj          subject number
%   beh_cfg.mode  empty or not existing: load log_VP%i.mat
%                 'SIMULATION': load log_VP%imode1.mat (simulation data files)
%  OUT
%   data          struct with SPM coding style
%
% Marc & Kai, 2018/9/5

function data = extract_data_TaskRestExp(subj, beh_cfg)

warning('FUNCTION DEPRECATED, not really useful. Do not use in new implementations')

% Get a struct with a SPM coding style.

% ON CHANGE: ALSO CHANGE IN get_all_confounds.m
% switch between real data and simulation
if isfield(beh_cfg, 'mode') && strcmp(beh_cfg.mode, 'SIMULATION')
    logfile_name = sprintf('log_VP%imode1.mat', subj);
else
    logfile_name = sprintf('log_VP%i.mat', subj);
end
%my_experiment = get_log(fullfile(beh_cfg.dirs.base_dir, 'TaskRestExp/logs/', logfile_name));
%!!change
my_experiment = get_log(fullfile(beh_cfg.dirs.base_dir, 'Example_data/', logfile_name));
    
n_runs = length(my_experiment.run);
n_trials = length(my_experiment.run(1).trial);

for i = 1:n_runs
    for a = 1:n_trials
        data.Sess(i).trial(a).name{1} = my_experiment.run(i).trial(a).name;
        data.Sess(i).trial(a).reactiontime = [my_experiment.run(i).trial(a).reactiontime];
    end
end

