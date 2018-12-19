function data = bede_convert_table_to_trial(tabledata)

% convert 
%   tabledata Sess(s).field(trial) 
% into 
%   data.Sess(s).trial(trial).field struct
% This can be useful to convert e.g. a csv file into a .trial structure.
%
% The trial structure can than be used to create a sorted Sess.U structure.
%
% Example INPUT
% tabledata.Sess(1).name           = {'A' 'A' 'B' 'B' 'B'};
% tabledata.Sess(1).RT             = [750 800 650 725 800];
% tabledata.Sess(1).factorial.cue  = [1   2   3   4   3];  % factorial
% 
%
% Example OUTPUT (sess 1, trial 1)
% data.Sess(1).trial(1).name{1} = 'A';
% data.Sess(1).trial(1).RT = 750;
% data.Sess(1).trial(1).factorial.cue = 1;  % factorial

% remark: EVAL command necessary, because we allow putting data in
% subfields (e.g. to mark factorial variables with .fact.)

for sess_ind = 1:length(tabledata.Sess)
    curr_sess = tabledata.Sess(sess_ind);
    curr_fieldnames = get_subfield_tree(curr_sess);

    % verify that fieldnames equal first session
    if ~isequal(curr_fieldnames, get_subfield_tree(tabledata.Sess(1)))
        error('Fieldnames in Session %i do not equal fieldnames of session 1', sess_ind)
    end
    
    % get number of trials for this session and verify that this is the
    % same for all fields
    n_trials = eval(['length(curr_sess.' curr_fieldnames{1} ')']);
    for field_ind = 1:length(curr_fieldnames)
        curr_fieldname = curr_fieldnames{field_ind};
        curr_fielddata = eval(['curr_sess.' curr_fieldname]);
        curr_field_n_trials = length(curr_fielddata);
        if  curr_field_n_trials ~= n_trials
            error('Field %s has %i trials, which is not the same as field %s (%i trials)', curr_fieldnames{field_ind}, curr_field_n_trials, curr_fieldnames{1}, n_trials)
        end            
    end
    
    % put data into trial structure
    for trial_ind = 1:n_trials
        curr_trial_data = [];
        for field_ind = 1:length(curr_fieldnames)
            curr_fieldname = curr_fieldnames{field_ind};
            curr_fielddata = eval(['curr_sess.' curr_fieldname]);
            eval(['curr_trial_data.' curr_fieldname ' = curr_fielddata(trial_ind);']);
        end
        data.Sess(sess_ind).trial(trial_ind) = curr_trial_data;
    end
end
