% This demo creates a design with 4 runs and 5 trials in each run.
% Runs 1 & 3 contain 3 trials of condition A and 2 trials of condition B.
% Runs 2 & 4 contain 2 trials of condition A and 3 trials of condition B.
%
% This does not make any difference for a t-test, because equally many
% trials of A and B are used in total. It does matter for cross-validation,
% because more of the other condition are present in each cross-validation 
% fold. This results in below-chance decoding accuracies.
%
% TODO: At the moment, it also demonstrate the bias if more data is
% available from one class than from another (here, this also leads to
% below-chance decoding accuracies).


function [cfg, data, passed_data, result] = demo_unequal_data

%% Step 0: Specify data
% If you have real data, this step is obviously not necessary

% This demo creates a design with 4 runs and 5 trials in each run.
% Runs 1 & 3 contain 3 trials of condition A and 2 trials of condition B.
% Runs 2 & 4 contain 2 trials of condition A and 3 trials of condition B.

% it can either use the 'trial' data or a number of summary measures
cfg.use_summary_values = 1; % 0: trial data, 1: summary measures

% Run 1
data.Sess(1).U(1).name = {'A'};
data.Sess(1).U(1).trialnr = [1 2 3];
data.Sess(1).U(1).curr.cond = [1 1 1];
data.Sess(1).U(1).curr.noclassdiff = [1 1 1];
data.Sess(1).U(2).name = {'B'};
data.Sess(1).U(2).trialnr = [4 5];
data.Sess(1).U(2).curr.cond = [2 2];
data.Sess(1).U(2).curr.noclassdiff = [1 1];

% Run 2
data.Sess(2).U(1).name = {'A'};
data.Sess(2).U(1).trialnr = [1 2];
data.Sess(2).U(1).curr.cond = [1 1];
data.Sess(2).U(1).curr.noclassdiff = [1 1];
data.Sess(2).U(2).name = {'B'};
data.Sess(2).U(2).trialnr = [3 4 5];
data.Sess(2).U(2).curr.cond = [2 2 2];
data.Sess(2).U(2).curr.noclassdiff = [1 1 1];

% Run 3
data.Sess(3).U(1).name = {'A'};
data.Sess(3).U(1).trialnr = [1 2 3];
data.Sess(3).U(1).curr.cond = [1 1 1];
data.Sess(3).U(1).curr.noclassdiff = [1 1 1];
data.Sess(3).U(2).name = {'B'};
data.Sess(3).U(2).trialnr = [4 5];
data.Sess(3).U(2).curr.cond = [2 2];
data.Sess(3).U(2).curr.noclassdiff = [1 1];

% Run 4
data.Sess(4).U(1).name = {'A'};
data.Sess(4).U(1).trialnr = [1 2];
data.Sess(4).U(1).curr.cond = [1 1];
data.Sess(4).U(1).curr.noclassdiff = [1 1];
data.Sess(4).U(2).name = {'B'};
data.Sess(4).U(2).trialnr = [3 4 5];
data.Sess(4).U(2).curr.cond = [2 2 2];
data.Sess(4).U(2).curr.noclassdiff = [1 1 1];

% The order is completely irrelevant to demonstrate below chance decoding 
% accuracies (although it would also be a confounding factor, too)

%% specify output measures
if cfg.use_summary_values 
    cfg.decoding_measures = {{'nancount.curr.cond'}, {'nansum.curr.cond'}}; % make sure to have double {{}} here
else % trialwise
    % use the normal values 
    % curr.cond will work 100% here, although the data is unbalanced, 
    % because the values are different enough
    cfg.decoding_measures = {{'curr.cond'}, {'curr.noclassdiff'}};
end

%% Do everthing
[cfg, data, passed_data, result] = easy_demo(data, cfg);