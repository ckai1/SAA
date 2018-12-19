% Function to access log files.
% Implements caching. 
%
% USE 
%   clear get_log
% if data changes.
%
% example call 
% my_experiment = get_log(fullfile(beh_cfg.dirs.base_dir, 'TaskRestExp/logs/', sprintf('log_VP%i.mat', 1)))
%
% Kai, 25.6.2018

function my_experiment = get_log(datafile)

%% implement caching for speedup (only caching last file so far)
use_cache = 1;
persistent last_datafile cached_data
if use_cache && strcmp(datafile, last_datafile)
    display(['Cached ' datafile])
    loaded_data = cached_data;
else
    display(['Loading ' datafile]);
    loaded_data = load (datafile);
    if use_cache
        last_datafile = datafile;
        cached_data = loaded_data;
    end
end
my_experiment = loaded_data.my_experiment;