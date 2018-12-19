% function cfg = bede_plot_design(Sess, cfg)
%
% Plots a design given a structure of the type Sess(s).trial(t)
%
% IN
%   Sess: structure of the type Sess(s).trial(t)
%       data in all subfields is plotted.
%       Only single numbers & strings are supported at the moment.
%   For convinience, if the input contains a .Sess subfield, this will be
%   taken instead of the input.
%
% OPTIONAL
%   cfg.plotting_type: Either 'stairs' or 'imagesc'
%   cfg.fighandle: figure handle where the design should be plot to
%       (default: a new figure is created)




function cfg = bede_plot_design(Sess, cfg)

%% defaults
if ~exist('cfg', 'var')
    cfg = [];
end

if ~isfield(cfg, 'plotting_type')
    cfg.plotting_type = 'stairs';
    % cfg.plotting_type = 'imagesc';
end

if ~isfield(cfg, 'fighandle')
    cfg.fighandle = figure('name', 'design');
else
    figure(cfg.fighandle)
end

if ~isfield(cfg, 'scaleheight')
    cfg.scaleheight = .9;
end

%% Check that .trial subfield exists
if ~isfield(Sess, 'trial') && isfield(Sess, 'Sess')
    display('Input did not contain a .trial subfield, but a .Sess subfield. Using the .Sess subfield for your convinience')
    % use subfield Sess instead of the originally provided data
    Sess = Sess.Sess;
end

if ~isfield(Sess, 'trial')
    error('This function only plots designs for Sess structure that contain the data in .trial() subfields. Please modify it when you also want to use e.g. Sess.U structures')
end

%% plot
n_sess = length(Sess);
for sess_ind = 1:n_sess
    % create figure with as many rows as sessions
    subplot(n_sess, 1, sess_ind);
    
    curr_sess = Sess(sess_ind);
    
    data_label = {};
    clear datamat; % for imagesc only
    clear datamattext; % for imagesc only
    
    % plot info for each trial of each subfield
    curr_subfields = get_subfield_tree(curr_sess.trial(1));
    
    % plot each subfields data
    for field_ind = 1:length(curr_subfields)
        clear curr_data;
        % get data from all trials
        for trial_ind = 1:length(curr_sess.trial)
            curr_trial = curr_sess.trial(trial_ind);
            curr_data(trial_ind) = eval(['curr_trial.' curr_subfields{field_ind}]);
        end
        
        % only expect numerical / words
        if isnumeric(curr_data) || islogical(curr_data) % plot in current row
            % care about scaling and labeling
            if isnumeric(curr_data)
                % scale data so it fits from [0 1]
                scaled_data = curr_data - min(curr_data); % [0 ...]
                if max(scaled_data) > 0 % to avoid problems if all data is equal
                    scaled_data = scaled_data / max(scaled_data); % [0 1]
                    scaled_data = scaled_data * cfg.scaleheight; % e.g. [0 0.95]: change height to fit in 1 row
                end
                data_label{field_ind} = [curr_subfields{field_ind} ' [' num2str(min(curr_data)), '..' num2str(max(curr_data)) ']'];
            elseif islogical(curr_data)
                scaled_data = curr_data * cfg.scaleheight; % e.g. [0 0.95]: change height to fit in 1 row
                data_label{field_ind} = [curr_subfields{field_ind} ' [logic]'];
            end
                
            if strcmp(cfg.plotting_type, 'stairs')
                % plot data as stairs
                % repeat last datapoint so that it can be seen better)
                stairs([scaled_data scaled_data(end)]+ field_ind);
                hold all
            elseif strcmp(cfg.plotting_type, 'imagesc')
                % collect scaled data for imagesc later
                datamat(field_ind, :) = scaled_data;
            else
                error('unkown')
            end
            
        elseif iscellstr(curr_data)
            data_label{field_ind} = [curr_subfields{field_ind} ' [str]'];
            
            
            for trial_ind = 1:length(curr_data)
                if strcmp(cfg.plotting_type, 'stairs')
                    % simply write the value for each entry
                    % show text
                    text(trial_ind, field_ind, curr_data{trial_ind})
                    hold all
                elseif strcmp(cfg.plotting_type, 'imagesc')
                    % write later
                    datamattext{field_ind, trial_ind} = curr_data{trial_ind};
                    % on white background
                    datamat(field_ind, trial_ind) = 1;
                end
            end
        else
            data_label{field_ind} = [curr_subfields{field_ind} ' [UNKOWN]'];
            warning(['Don''t know how to process content in field ' curr_subfields{field_ind}])
        end
    end
    
    
    if strcmp(cfg.plotting_type, 'imagesc')
        imagesc(datamat);
        colormap gray
        
        for x = 1:size(datamattext, 2)
            for y = 1:size(datamattext, 1)
                if ~isempty(datamattext{y, x})
                    text(x, y, datamattext{y, x})
                    hold on
                end
            end
        end
        
    end
    
    % set range
    xlim([1 length(curr_sess.trial)+1]); % number of trials at x-axis
    xlabel('trial number')
    set(gca, 'xTick', [1:length(curr_sess.trial)])
    
    ylim([0 length(curr_subfields)+1]); % number of trials at x-axis
    ylabel('data')
    % name fields
    set(gca, 'yTick', [1:length(curr_subfields)])
    set(gca, 'yTickLabel', data_label)
    
end