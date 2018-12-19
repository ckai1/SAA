% function [decoding_results, beh_cfg] = behavioural_decoding_batch(beh_cfg)
%
% This function mainly is a loop across subjects and collects results
%
% IN
%   beh_cfg: struct with following fields
%   beh_cfg.substodo: Subject numbers for which the decoding should be done
%   beh_cfg.individual_decoding_func: Function handle called for each subject
%           individual_decoding_func(subj, beh_cfg)
% OPTIONAL IN
%   beh_cfg.design_figure_hdl
%   beh_cfg.progress_figure_hdl
%   beh_cfg.savedir: Directory where output is saved (if empty or does not 
%       exist, output will not be saved)
% OUT
%   decoding_results(i): cell with results of each individual decoding for
%       substodo(i). ATTENTION: This is NOT the subject number as provided
%       in substodo, but the POSITION in substodo.
%   decoding_results(i).subjnr: nr of subject for substodo(i).
%   beh_cfg: cfg with all added fields

function [decoding_results, beh_cfg] = behavioural_decoding_batch(beh_cfg)

%% Set a default name

if ~isfield(beh_cfg, 'name')
    beh_cfg.name = 'Behavioural Decoding';
end

%% Initialize figures

if ~isfield(beh_cfg, 'progress_fighandle') || isempty(beh_cfg.progress_fighandle)
    beh_cfg.progress_fighandle = figure('name', 'Behavioural decoding - batch progress', 'units', 'normalized', 'outerposition', [.8 0 .2 .2]);
    axis off
end

if ~isfield(beh_cfg, 'design_fighandle') || isempty(beh_cfg.design_fighandle)
    beh_cfg.design_fighandle = figure('name', 'Design');
end

%% Initialize output file names

savefile_allsubj_accuracies = fullfile(beh_cfg.savedir, sprintf('behav_allsubj_accuracies_%s.mat', datestr(now, 'yyyymmdd_HHMM')));

%% loop across subjects

for subj_ind = 1:length(beh_cfg.substodo)
    curr_subjnr = beh_cfg.substodo(subj_ind); % current subject number

    % calculate estimated time to go for multiple subjects
    if subj_ind == 1
        start_time = now;
        message = ['Start: ' datestr(start_time, 'yyyy/mm/dd HH:MM:SS')];
    else
        t0 = now;
        el_time = t0 - start_time;
        el_time_str = datestr(el_time, 'dd HH:MM:SS');
        if str2double(el_time_str(1:2)) == 0, el_time_str = el_time_str(4:end); end
        est_time =  length(beh_cfg.substodo)/max(subj_ind-1, 1) * el_time;
        est_time_left = est_time - el_time; % how long we think it will still take
        est_time_left_str = datestr(est_time_left, 'dd HH:MM:SS');
        if str2double(est_time_left_str(1:2)) == 0, est_time_left_str = est_time_left_str(4:end); end    
        est_finish = start_time + est_time;
        est_finish_str = datestr(est_finish, 'yyyy/mm/dd HH:MM:SS');
        message = ['Start: ' datestr(start_time, 'yyyy/mm/dd HH:MM:SS') '\nTime to go: ' est_time_left_str '\nTime running: ' el_time_str '\nEst. end: ' est_finish_str];
    end
    
    % show progress as text & in figure
    prog_text = sprintf('Processing subjnr %i (%i/%i)', curr_subjnr, subj_ind, length(beh_cfg.substodo));
    display(prog_text);
    sprintf(message)
    try 
        set(0,'CurrentFigure',beh_cfg.progress_fighandle); plot(.5, .5); text(0.1,0.5,{prog_text, ' ', sprintf(message)}); xlim([0, 1]); ylim([0, 1]); box off; axis off; drawnow;
    catch
        display('Writing status report to figure was not successful, maybe it was closed')
    end
        
    % do decoding for current subject
    [results, decoding_cfg] = beh_cfg.individual_decoding_func(curr_subjnr, beh_cfg);
    
    % save everything to output variable
    decoding_results.subj_results(subj_ind).results = results;
    decoding_results.subj_results(subj_ind).decoding_cfg = decoding_cfg;
    decoding_results.subj_results(subj_ind).subjnr = curr_subjnr; % add current subject number
end

%% Add info for all subjects to results
% put all decoding measures that are strings (and not cells) in a cell to
% allow conversion
decoding_results.decoding_measures_str = {};
for d_ind = 1:length(decoding_cfg.beh_cfg.decoding_measures)
    if ischar(decoding_cfg.beh_cfg.decoding_measures{d_ind})
        % is already a string
        decoding_results.decoding_measures_str{d_ind} = decoding_cfg.beh_cfg.decoding_measures{d_ind};
    else %create string
        decoding_results.decoding_measures_str{d_ind} = sprintf('%s ', decoding_cfg.beh_cfg.decoding_measures{d_ind}{:});
    end
end
decoding_results.beh_cfg = beh_cfg;

%% Save data to file
dispv(1, 'Saving data to file %s', savefile_allsubj_accuracies)
if ~exist(fileparts(savefile_allsubj_accuracies), 'dir'), mkdir(fileparts(savefile_allsubj_accuracies)); end
save(savefile_allsubj_accuracies, 'decoding_results');
dispv(1, 'Saving data to file %s done', savefile_allsubj_accuracies)

close(beh_cfg.progress_fighandle); % close progress text figure
