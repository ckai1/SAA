% This demo creates a design with 4 runs and 5 trials in each run.
% Runs 1 & 3 contain 3 trials of condition A and 2 trials of condition B.
% Runs 2 & 4 contain 2 trials of condition A and 3 trials of condition B.
%
% This does not make any difference for a t-test, because equally many
% trials of A and B are used in total. It does matter for cross-validation,
% because more of the other condition are present in each trial.

function [cfg, data, passed_data, result] = demo_unequal_data

%% Step 0: Specify data
% If you have real data, this step is obviously not necessary

% This demo creates a design with 4 runs and 5 trials in each run.
% Runs 1 & 3 contain 3 trials of condition A and 2 trials of condition B.
% Runs 2 & 4 contain 2 trials of condition A and 3 trials of condition B.

% it can either use the 'trial' data or a number of summary measures
use_summary_values = 1; % 0: trial data, 1: summary measures

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
if use_summary_values
    cfg.decoding_measures = {{'nancount.curr.cond'}, {'nansum.curr.cond'}}; % make sure to have double {{}} here
else % trialwise
    % use the normal values 
    % curr.cond will work 100% here, although the data is unbalanced, 
    % because the values are different enough
    cfg.decoding_measures = {{'curr.cond'}, {'curr.noclassdiff'}};
end

%% Do everthing
[cfg, data, passed_data, result] = easy_demo(data, cfg);

%% Again create plots with information about them
if cfg.use_summary_values

    %% Display the accuracy for count
    % get the index of count.curr.cond
    nancount_ind = find(strcmp('nancount.curr.cond, ', cfg.files.mask));
    display('Accuracy_minus_chance for nancount. Should be -50, meaning 0% correct, or 50% below chance):')
    disp(result.accuracy_minus_chance.output(nancount_ind))
    plot_decoding_steps_1d(cfg, passed_data, result, nancount_ind)
    
    %% Display the accuracy for nansum
    nansum_ind = find(strcmp('nansum.curr.cond, ', cfg.files.mask));
    display('Accuracy_minus_chance for nansum. Should be 50, meaning 100% correct, or 50% above chance, because SUMMING the condition numbers is always greater for class 2 (although summing condition numbers makes absolutely no sense):')
    disp(result.accuracy_minus_chance.output(nansum_ind))
    plot_decoding_steps_1d(cfg, passed_data, result, nansum_ind)

else
    % Display the accuracy for curr.cond
    currcond_ind = find(strcmp('curr.cond, ', cfg.files.mask));
    display('Accuracy_minus_chance for curr.cond single trial data. Should be 50, meaning 100% correct, or 50% above chance:')
    disp(result.accuracy_minus_chance.output(currcond_ind))
    
    plot_decoding_steps_1d(cfg, passed_data, result, currcond_ind)
    
    % Display the accuracy for curr.noclassdiff
    noclassdiff_ind = find(strcmp('curr.noclassdiff, ', cfg.files.mask));
    display('Accuracy_minus_chance for curr.noclassdiff single trial data. Should be less than 0, meaning <50% correct, or 50% above chance, because the training data is always more for the other class than the class in the training set (although the values of the data are exactly the same):')
    disp(result.accuracy_minus_chance.output(noclassdiff_ind))
    plot_decoding_steps_1d(cfg, passed_data, result, noclassdiff_ind)
end