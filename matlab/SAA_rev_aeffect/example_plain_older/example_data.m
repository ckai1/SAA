function data = example_data(subj, datatype)

% by default, return the 'trial' data
if ~exist('datatype', 'var')
    datatype = 'trial';
end

% check datatype

if strcmp(datatype, 'trial') || strcmp(datatype, 'firstleveldesign')
    % ok
else
    error('Unkown required datatype')
end
    

% The clearest example dataset you can imagine
display('Getting the minimal example dataset')
display('So far we ignore subj completely')

% Sess 1
data.Sess(1).trial(1).name{1} = 'Left';
data.Sess(1).trial(1).RT = 750;  % behaviour: reaction time in ms
data.Sess(1).trial(1).cue = 17;  % design: number of image used as cue

data.Sess(1).trial(2).name{1} = 'Right';
data.Sess(1).trial(2).RT = 700;
data.Sess(1).trial(2).cue = 4;

data.Sess(1).trial(3).name{1} = 'Left';
data.Sess(1).trial(3).RT = 730;
data.Sess(1).trial(3).cue = 17;

data.Sess(1).trial(4).name{1} = 'Right';
data.Sess(1).trial(4).RT = 690;
data.Sess(1).trial(4).cue = 4;


% Sess 2
data.Sess(2) = data.Sess(1);
% slightly change RTs
data.Sess(2).trial(1).RT = 720;
data.Sess(2).trial(2).RT = 710;
data.Sess(2).trial(3).RT = 780;
data.Sess(2).trial(4).RT = 800;

% Sess 3
data.Sess(3) = data.Sess(1);
% slightly change RTs
data.Sess(3).trial(1).RT = 720;
data.Sess(3).trial(2).RT = 710;
data.Sess(3).trial(3).RT = 780;
data.Sess(3).trial(4).RT = 690;

% Sess 4
data.Sess(4) = data.Sess(1);
% slightly change RTs
data.Sess(4).trial(1).RT = 740;
data.Sess(4).trial(2).RT = 700;
data.Sess(4).trial(3).RT = 760;
data.Sess(4).trial(4).RT = 650;

% add "onsets" to each session
for sess_ind = 1:length(data.Sess)
    for trial_ind = 1:length(data.Sess(sess_ind).trial)
        data.Sess(sess_ind).trial(trial_ind).onset = trial_ind*100 + sess_ind;
    end
end

%% check how we should return the data
    
if strcmp(datatype, 'firstleveldesign')
    trial_data = data;
    clear data
    % create a "first-level" design
    for sess_ind = 1:length(trial_data.Sess)
        data.Sess(sess_ind).U(1).name = {'Left'};
        data.Sess(sess_ind).U(1).ons = [];
        data.Sess(sess_ind).U(2).name = {'Right'};
        data.Sess(sess_ind).U(2).ons = [];
        
        for trial_ind = 1:length(trial_data.Sess(sess_ind).trial)
            % all left in regressor 1, all right in regressor 2
            if strcmp('Left', trial_data.Sess(sess_ind).trial(trial_ind).name{1})
                data.Sess(sess_ind).U(1).ons(end+1) = trial_data.Sess(sess_ind).trial(trial_ind).onset;
            elseif strcmp('Right', trial_data.Sess(sess_ind).trial(trial_ind).name{1})
                data.Sess(sess_ind).U(2).ons(end+1) = trial_data.Sess(sess_ind).trial(trial_ind).onset;
            else
                warning('Unkown condition name')
            end
        end
    end
elseif strcmp(datatype, 'trial')
   % return as is 
else
    error('Unkown datatype')
end