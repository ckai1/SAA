% Conditions for xclassification between condtions using their difficulties 
% for SAA1
%
% Kai, 2018/10/01

function out_data = TaskRest_SAA1_get_conditions_xset(subj, beh_cfg)

display(sprintf('Getting conditions for subj %i', subj))
%% get the dataset for the current subject
% input_data = extract_data_TaskRestExp(subj, beh_cfg); % input_data

if isfield(beh_cfg, 'mode') && strcmp(beh_cfg.mode, 'SIMULATION')
    logfile_name = sprintf('log_VP%imode1.mat', subj);
else
    logfile_name = sprintf('log_VP%i.mat', subj);
end
%my_experiment = get_log(fullfile(beh_cfg.dirs.base_dir, 'TaskRestExp/logs/', logfile_name));
my_experiment = get_log(fullfile(beh_cfg.dirs.base_dir, 'Example_data/logs/', logfile_name));

%% Sort data by condition / condition + xset difficulty

for sess_ind = 1:length(my_experiment.run)
    % init conditions for current session
    
    % simple 1-3
    % Summe: u=1
    U_Summe_s = 1;
    out_data.Sess(sess_ind).U(U_Summe_s).name{1} = 'Summe s';
    out_data.Sess(sess_ind).U(U_Summe_s).trialnr = [];
    % Kongruent: u=2
    U_Kongruent_s = 2;
    out_data.Sess(sess_ind).U(U_Kongruent_s).name{1} = 'Kongruent s';
    out_data.Sess(sess_ind).U(U_Kongruent_s).trialnr = [];
    % Similarity: u=3
    U_Aehnlich_s = 3;
    out_data.Sess(sess_ind).U(U_Aehnlich_s).name{1} = 'Ähnlich s';
    out_data.Sess(sess_ind).U(U_Aehnlich_s).trialnr = [];
    
    % complex: 4-6
    % Summe: u=1
    U_Summe_c = 4;
    out_data.Sess(sess_ind).U(U_Summe_c).name{1} = 'Summe c';
    out_data.Sess(sess_ind).U(U_Summe_c).trialnr = [];
    % Kongruent: u=5
    U_Kongruent_c = 5;
    out_data.Sess(sess_ind).U(U_Kongruent_c).name{1} = 'Kongruent c';
    out_data.Sess(sess_ind).U(U_Kongruent_c).trialnr = [];
    % Similarity: u=6
    U_Aehnlich_c = 6;
    out_data.Sess(sess_ind).U(U_Aehnlich_c).name{1} = 'Ähnlich c';
    out_data.Sess(sess_ind).U(U_Aehnlich_c).trialnr = [];    
    
    
    % sort trials according to label    
    for trial_ind = 1:length(my_experiment.run(sess_ind).trial)
        curr_trial = my_experiment.run(sess_ind).trial(trial_ind);

        if strcmp(curr_trial.name, 'Summe') && strcmp(curr_trial.block_difficulty, 's')
            out_data.Sess(sess_ind).U(U_Summe_s).trialnr(end+1) = trial_ind;
        elseif strcmp(curr_trial.name, 'Summe') && strcmp(curr_trial.block_difficulty, 'c')
            out_data.Sess(sess_ind).U(U_Summe_c).trialnr(end+1) = trial_ind;
            
        elseif strcmp(curr_trial.name, 'Kongruent') && strcmp(curr_trial.block_difficulty, 's')
            out_data.Sess(sess_ind).U(U_Kongruent_s).trialnr(end+1) = trial_ind;
        elseif strcmp(curr_trial.name, 'Kongruent') && strcmp(curr_trial.block_difficulty, 'c')
            out_data.Sess(sess_ind).U(U_Kongruent_c).trialnr(end+1) = trial_ind;
            
        elseif strcmp(curr_trial.name, 'Ähnlich') && strcmp(curr_trial.block_difficulty, 's')
            out_data.Sess(sess_ind).U(U_Aehnlich_s).trialnr(end+1) = trial_ind;
        elseif strcmp(curr_trial.name, 'Ähnlich') && strcmp(curr_trial.block_difficulty, 'c')
            out_data.Sess(sess_ind).U(U_Aehnlich_c).trialnr(end+1) = trial_ind;
            
        else
            warning('example_get_conditions:unkown_condition', 'Unkown condition name or difficulty level for trial %i', trial_ind);
            keyboard
        end
    end
end
     
% also add subjnr
out_data.subjnr = subj;
            