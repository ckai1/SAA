function out_data = example_get_conditions(subj, cfg)

display(sprintf('Getting example conditions for subj %i', subj))
%% get the dataset for the current subject

input_data = example_data(subj); % input_data

%% Sort data by left / right

for sess_ind = 1:length(input_data.Sess)
    % init left and right condition for current session
    % Left: u=1
    U_LEFT = 1;
    out_data.Sess(sess_ind).U(U_LEFT).name{1} = 'Left';
    out_data.Sess(sess_ind).U(U_LEFT).trialnr = [];
    % Right: u=2
    U_RIGHT = 2;
    out_data.Sess(sess_ind).U(U_RIGHT).name{1} = 'Right';
    out_data.Sess(sess_ind).U(U_RIGHT).trialnr = [];
    
    % sort trials according to label    
    for trial_ind = 1:length(input_data.Sess(sess_ind).trial)
        curr_trial = input_data.Sess(sess_ind).trial(trial_ind);
        if strcmp(curr_trial.name{1}, 'Left')
            out_data.Sess(sess_ind).U(U_LEFT).trialnr(end+1) = trial_ind;
        elseif strcmp(curr_trial.name{1}, 'Right')
            out_data.Sess(sess_ind).U(U_RIGHT).trialnr(end+1) = trial_ind;
        else
            warning('example_get_conditions:unkown_condition', 'Unkown condition name for trial %i', trial_ind);
        end
    end
end
     
% also add subjnr
out_data.subjnr = subj;
            