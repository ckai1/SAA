function out_data = TaskRest_SAA1_get_conditions(subj, beh_cfg)

display(sprintf('Getting conditions for subj %i', subj))
%% get the dataset for the current subject
input_data = extract_data_TaskRestExp(subj, beh_cfg); % input_data

%% Sort data by left / right

for sess_ind = 1:length(input_data.Sess)
    % init left and right condition for current session
    % Summe: u=1
    U_Summe = 1;
    out_data.Sess(sess_ind).U(U_Summe).name{1} = 'Summe';
    out_data.Sess(sess_ind).U(U_Summe).trialnr = [];
    % Kongruent: u=2
    U_Kongruent = 2;
    out_data.Sess(sess_ind).U(U_Kongruent).name{1} = 'Kongruent';
    out_data.Sess(sess_ind).U(U_Kongruent).trialnr = [];
    % Konkrete: u=3
    U_Aehnlich = 3;
    out_data.Sess(sess_ind).U(U_Aehnlich).name{1} = 'Ähnlich';
    out_data.Sess(sess_ind).U(U_Aehnlich).trialnr = [];
    
    % sort trials according to label    
    for trial_ind = 1:length(input_data.Sess(sess_ind).trial)
        curr_trial = input_data.Sess(sess_ind).trial(trial_ind);
        if strcmp(curr_trial.name{1}, 'Summe')
            out_data.Sess(sess_ind).U(U_Summe).trialnr(end+1) = trial_ind;
        elseif strcmp(curr_trial.name{1}, 'Kongruent')
            out_data.Sess(sess_ind).U(U_Kongruent).trialnr(end+1) = trial_ind;
        elseif strcmp(curr_trial.name{1}, 'Ähnlich')
            out_data.Sess(sess_ind).U(U_Aehnlich).trialnr(end+1) = trial_ind;
        else
            warning('example_get_conditions:unkown_condition', 'Unkown condition name for trial %i', trial_ind);
            keyboard
        end
    end
end
     
% also add subjnr
out_data.subjnr = subj;
            