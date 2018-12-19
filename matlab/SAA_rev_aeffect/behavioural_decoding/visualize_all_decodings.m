% [fhl, decodingstr_p_values] = visualize_all_decodings(data_or_struct, subj_names, decoding_measures_str, beh_cfg, save_file)
%
% Use as
%
% (1a) function visualize_all_decodings(result_struct)
%       where result_struct might contain result_struct.beh_cfg
%       for other details of result_struct see under (1) below
%   or
% (1b)  function visualize_all_decodings(result_struct, beh_cfg)
%       where result_struct might does not contain result_struct.beh_cfg
%   or
% (2) function visualize_all_decodings(data, subj_names, decoding_measures_str, beh_cfg, save_file)
%       where all data is passed as different fields
%
% (1)
% function visualize_all_decodings(result_struct)
%   IN
%     data from behavioural_decoding, containing
%       result_struct: struct containing:
%           .subj_results().results.accuracy_minus_chance.output: integer
%              Will be used as data
%           .subj_results().subjnr: integer / char
%               Will be used to create name of subjects (row labels)
%               If input is an integer, s%02i will be used in sprintf.
%               If input is text, this text will be used
%           .decoding_measures_str: cellstr with names of decoding
%               measures (column labels)
%   OPTIONAL IN
%       result_struct.beh_cfg: See beh_cfg below
%   OUT
%       fhdl: Handle to figure
%       decodingstr_p_values: contains .p and corresponding .decoding_str
%           (2nd level results). Might e.g. be used to plot the results 
%           sorted by ascending p-values.
%       FIGURE: saved in beh_cfg.savedir as 'Visualize_all_decodings' (if
%           beh_cfg.savedir is provided)
%
% (2)
% function visualize_all_decodings(data, subj_names, decoding_measures_str, beh_cfg, save_file)
% IN
%   data: NxM matrix to be plotted + analysed
%   subj_names: Nx1 cellstr with labels for each row
%   decoding_measures_str: 1xM cellstr with labels for each column
% OPTIONAL
%   beh_cfg
%     INFO
%       .name: title for figure
%       .decoding_str: additional text at top of subj table (e.g. display rules)
%     SAVE
%       .savedir: (Only effective IF save_file is NOT provided)
%           Save figure as 'Visualize_all_decodings' in beh_cfg.savedir
%       .save_file: Exact name (without extension) to specify where to save 
%           the result figure. E.g. 'mydir/myfigure' (without .png)
%     DISPLAY
%       .show_subj_figure: set 1, if subject histograms should be shown
%           (default: 0 for more than 1 measure)
%       .show_detail_figure: 1 if detailed figure should be shown 
%           (default: 1)
%       REMARK: If neither subj_figure nore detail_figure is shown, a 2nd 
%           level randn summary is shown as well.
%       .plot_orientation: =0: Subjects on y-axis. 1 (default): Measures on 
%           y-axes  
%     SHORTEN NAMES
%       .shorten_names: Defines if names will  be shortened for display.
%           0: Keep original, 1: shorten. default (1)
%       .repl: 2xN cellstr, that defines what sorten_names replaces.The 
%           first entry of each row will be replaced by the second entry.
%     RANDN covariates
%       .show_randn: number of randn regressors to show (default: 10)
%     SUBSELECTION
%       .selected_decoding_measures: cellstr with names in
%           decoding_measures_str to show. The oder will of this variable
%           will be used to sort the figure. Empty rows can be added using
%           ' ' or [] as entry. By default, then empty row contains nans
%           for all subjects. You can provide your own empty row by adding
%           one row to the allsubj_accuracies(:, emptyrow_ind) that 
%           contains the data and add deocoding_measure_str{emptyrow}=' '.
%           You can also add empty rows with names (as "subheaders"), they 
%           need to start with '--' or '..'
%       .selected_decoding_measures_ind: Like above, but here the indices
%           of the entries in decoding_measure_str are are used to select 
%           which variables to show. Empty rows can be added using index 0.
%
% Author: Kai

function [fhl, decodingstr_p_values] = visualize_all_decodings(data_or_struct, subj_names, decoding_measures_str, beh_cfg, save_file)

if isstruct(data_or_struct)

    if nargin == 2
        % the second input is the beh_cfg, rename it
        beh_cfg = subj_names;
        clear subj_names % will be created below
    end
    
    % results in is a struct, get all infos from there
    if isfield(data_or_struct, 'subj_results')
        subj_results = data_or_struct.subj_results;

        % get infos from provided subj_results
        for subj_ind = 1:length(subj_results)
            allsubj_accuracies(subj_ind, :) = subj_results(subj_ind).results.accuracy_minus_chance.output;
            if isnumeric(subj_results(subj_ind).subjnr)
                subj_names{subj_ind} = sprintf('s%02i', subj_results(subj_ind).subjnr); % generate a cellstring with all subjects in it
            else
                subj_names{subj_ind} = subj_results(subj_ind).subjnr;
            end
        end
    elseif isfield(data_or_struct, 'allsubj_accuracies') % other format
        allsubj_accuracies = data_or_struct.allsubj_accuracies;
        subj_names = data_or_struct.subj_names;
    end

    decoding_measures_str = data_or_struct.decoding_measures_str;
    % map beh_cfg
    if isfield(data_or_struct, 'beh_cfg')
        beh_cfg = data_or_struct.beh_cfg;
    end
    
    if isfield(data_or_struct, 'save_file') % for compatibility reasons
        beh_cfg.save_file = data_or_struct.save_file;
    end
    
else
    % data for table provided directly, just map
    allsubj_accuracies = data_or_struct;
end
clear allsubj_accuracies_or_struct

%% set defaults
if ~exist('beh_cfg', 'var')
    beh_cfg = [];
end

if ~isfield(beh_cfg, 'name')
    beh_cfg.name = ['Behavioural decoding results ' datestr(now)];
    if isfield(beh_cfg, 'save_file')
        [d, fname, ext]  = fileparts(beh_cfg.save_file);
        beh_cfg.name = [beh_cfg.name ' ' fname];
    end
end

if isfield(beh_cfg, 'show_subj_figure')
    show_subj_figure = beh_cfg.show_subj_figure;
elseif isfield(data_or_struct, 'show_subj_figure')
    show_subj_figure = data_or_struct.show_subj_figure;
elseif length(decoding_measures_str) == 1
    show_subj_figure = 1; % show for each subject by default
else
    show_subj_figure = 0; % otherwise dont show
end

if isfield(beh_cfg, 'show_detail_figure')
    show_detail_figure = beh_cfg.show_detail_figure;
elseif isfield(data_or_struct, 'show_detail_figure')
    show_detail_figure = data_or_struct.show_detail_figure;
else
    show_detail_figure = 1; % show details by default
end

% Determine where to save
if ~exist('save_file', 'var') 
    if isfield(beh_cfg, 'save_file')
        save_file = beh_cfg.save_file;
    elseif isfield(beh_cfg, 'savedir')
        % get from beh_cfg, if this exist, but save_file not
        save_file = fullfile(beh_cfg.savedir, 'Visualize_all_decodings');
    end
end
    
%% Specify orientation of plots

if ~isfield(beh_cfg, 'plot_orientation')
    plot_orientation = 1; % 1: plot description on yaxis (new version) (default); 0: plot subjects on y-axis
else
    plot_orientation = beh_cfg.plot_orientation; 
end
% check that parameter is valid
if plot_orientation ~= 0 && plot_orientation ~= 1
    error('Unkown value for plot_orientation')
end

%% define colors
color_bf_low = [ 1  0  0];    % p < .05/bonf
color_low =    [ 0  0  0];    % p < .1
color_std =    [.6 .6 .6];    % p > .1 .. p < .9
color_up =     [ 0  0 .5]; % [.1 .6 .1];    % p > .9 .. p < .95/bonf
color_bf_up =  [ 0  0  1];    % p > .9 .. p < .95/bonf

% color_p has to be defined each time bonferonni values are calculated
% color_p = [     bonferroni_low      .05    .1        .9    .95     bonferroni_up        inf];
colors  = [color_bf_low;   color_low;    color_low; color_std;    color_up;     color_up;     color_bf_up];
txtmarker = {'**', '*', '^', '', '^', '*b', '**b'};
fontweights = {'bold', 'bold', 'normal', 'normal', 'normal', 'normal', 'bold'};

% the following two lines gets the color for each p value
%     % get text color
%     txt_color = colors(find(p < color_p, 1, 'first'), :);
%     txt_marker = txtmarker(find(p < color_p, 1, 'first'));
%     txt_weight = fontweights(find(p < color_p, 1, 'first'));
%     if isempty(txt_color), txt_color = color_std; end % e.g. if p = nan
%     if isempty(txt_marker), txt_marker = {''}; end
%     if isempty(txt_weight), txt_weight = {'normal'}; end % e.g. if p = nan
%     
%     % write text
%     text(xpos, ypos, sprintf(' p=%.03f%s', p, txt_marker{1}), 'Color', txt_color, 'Rotation', rot, 'FontWeight', txt_weight{1}, 'FontName','Arial');
    

%% Avoid common error
if ~iscellstr(decoding_measures_str)
    try
        % maybe we have the input into get_passed_data_incl_masks and it
        % has not yet converted into a cellstr, so let's do it again
        % (indeed, the programming is bad at the moment, because what is
        % called decoding_measures_str can be easily confused with
        % decoding_measures, and the converted version is only contained in
        % cfg.mask.files)
        for dec_m_ind = 1:length(decoding_measures_str)
            decoding_measures_str{dec_m_ind} = sprintf('%s, ', decoding_measures_str{dec_m_ind}{:});
        end
        if ~iscellstr(decoding_measures_str)
            error('decoding_measures_str is not a cellstr, even trying to convert it did not work')
        end
    catch e
        e
        error('decoding_measures_str is not a cellstr, even trying to convert it did not work')
    end
end

% check that decoding_measures_str is 1xM, not Mx1
if size(decoding_measures_str, 1) > 1 
    if size(decoding_measures_str, 1) == 1
        decoding_measures_str = decoding_measures_str';
    else
        error('The passed decoding_measures_str is a matrix, but a Mx1 or 1xM vector is expected. Stop plotting')
    end
end

%% Select variables if only a selection should be plotted

if isfield(beh_cfg, 'selected_decoding_measures')
    % get indices to keep
    display('Selecting decoding measures by name using beh_cfg.selected_decoding_measures. This might take a bit')
    if ischar(beh_cfg.selected_decoding_measures)
        beh_cfg.selected_decoding_measures = {beh_cfg.selected_decoding_measures}; % make it a cell
    elseif ~iscellstr(beh_cfg.selected_decoding_measures)
        % check if any entries are empty
        empty_ind = cellfun(@isempty, beh_cfg.selected_decoding_measures);
        % put ' ' in empty fields and check again
        beh_cfg.selected_decoding_measures(empty_ind) = {' '};
        if ~iscellstr(beh_cfg.selected_decoding_measures)
            error('beh_cfg.selected_decoding_measures must be a cellstr')
        end
    end

    % add empty row string (check if an empty row exist, otherwise create
    % one
    if isempty(find(strcmp(decoding_measures_str, ' '))) %#ok<EFIND>
        display('Adding empty decoding_measures_str at end if empty rows are wanted in selection');
        decoding_measures_str{end + 1} = ' ';
    end
    
    % find index of each entry and use this to plot later
    trimed_decoding_measures_str = strtrim(decoding_measures_str);
    for sdm_ind = 1:length(beh_cfg.selected_decoding_measures);
        % get indices (empty fields have been replaced by ' ' above;
        curr_ind = find(strcmp(decoding_measures_str, beh_cfg.selected_decoding_measures{sdm_ind}));
        if isempty(curr_ind)
            % try strtrim
            curr_ind = find(strcmp(trimed_decoding_measures_str, strtrim(beh_cfg.selected_decoding_measures{sdm_ind})));
            if ~isempty(curr_ind)
                display(sprintf('Found string-trimmed version of %s instead of original', beh_cfg.selected_decoding_measures{sdm_ind}));
            end
        end
        if isempty(curr_ind)
            % check if starts with --, in this case add it as new measure
            if strncmp(beh_cfg.selected_decoding_measures{sdm_ind}, '--', 2) || strncmp(beh_cfg.selected_decoding_measures{sdm_ind}, '..', 2)
                display(sprintf('Found header-like string %s, adding it as new empty entry', beh_cfg.selected_decoding_measures{sdm_ind} ))
                decoding_measures_str{end+1} = beh_cfg.selected_decoding_measures{sdm_ind};
                allsubj_accuracies(:, end+1) = nan;
                curr_ind = length(decoding_measures_str);
            else
                error('Cant find %s in decoding_measures_str. If you still want to add this as empty line, please implement it here', beh_cfg.selected_decoding_measures{sdm_ind});
            end
        elseif length(curr_ind) > 2
            error('Found %s in decoding_measures_str multiple times, this case is not caught here. Please use beh_cfg.selected_decoding_measures_ind instead.', beh_cfg.selected_decoding_measures{sdm_ind})
        end
        selected_decoding_measures_ind(sdm_ind) = curr_ind;
    end
end

if isfield(beh_cfg, 'selected_decoding_measures_ind')
    if isfield(beh_cfg, 'selected_decoding_measures')
        error('You can only either pass names to select (.selected_decoding_measures) or indeces (.selected_decoding_measures_ind), but not both')
    end
    display('Selecting decoding measures by index using beh_cfg.selected_decoding_measures_ind')
    selected_decoding_measures_ind = beh_cfg.selected_decoding_measures_ind;
    % add empty row string
    display('Adding empty decoding_measures_str at end if empty rows are wanted in selection');
    decoding_measures_str{end + 1} = ' ';
    % copy indices
    selected_decoding_measures_ind(selected_decoding_measures_ind==0) = length(decoding_measures_str); % replace 0s by new empty row
end
    
if exist('selected_decoding_measures_ind', 'var')
    display('Only showing a subselection that was selected')
    
    display('Adding empty row at end of accuracies if empty rows are wanted in selection');
    allsubj_accuracies(:, end+1) = nan;
    
    % Only keeping the ones we want (sorted as we want)
    allsubj_accuracies = allsubj_accuracies(:, selected_decoding_measures_ind);
    decoding_measures_str = decoding_measures_str(selected_decoding_measures_ind);
end

%% Only plot some (default 10) randn regressors, if there are more
display('Checking if curr.randn predictors exist, if so, creating summary statistic')
randn_pos_ind = ~cellfun(@isempty, strfind(decoding_measures_str, 'curr.randn'));
randn_pos = find(randn_pos_ind);
n_randn = length(randn_pos);

if isfield(beh_cfg, 'show_randn')
    show_randn = beh_cfg.show_randn;
else
    show_randn = 10;
end

if n_randn > 3
    % calculating 2nd level for all randns before removing them
    display('calculating 2nd level for all randns before removing them')
    [randn_summary.H, randn_summary.p] = ttest(allsubj_accuracies(:, randn_pos_ind), [], .05, 'right');
    [randn_summary.pSig, randn_summary.binoCI95] = binofit(sum(randn_summary.H), length(randn_summary.H));
    randn_summary.text = sprintf(' %.2f%% CI95[%.2f,%.2f] of %i 2nd level tests sig, \\alpha=5%%', randn_summary.pSig*100, randn_summary.binoCI95*100, length(randn_summary.H));
    randn_summary.label = sprintf('..%i randn SUMMARY:', length(randn_pos));
    if randn_summary.binoCI95(2) < .05
        % most likely all fine, even CI is smaller than .05
        txt_color = color_std;
    elseif randn_summary.binoCI95(1) > .05 % even CI is larger than .05, warning
        txt_color = color_bf_low;
    elseif randn_summary.binoCI95(2) > .05
        txt_color = color_low; % maybe have a look, CI is above .05
    else
        % no idea if this can be reached, but all should be fine here
        txt_color = color_std;
    end
    randn_summary.color = txt_color;
end

% removing randns
if n_randn > show_randn
    remove_pos = randn_pos(show_randn+1:end);
    warning(['More than ' int2str(show_randn) ' randn predictors detected, reduce plotting to only ' int2str(show_randn)])
    % replace the first entry by info that it was removed
    summary_pos = remove_pos(1);
    decoding_measures_str{remove_pos(1)} = randn_summary.label;
    allsubj_accuracies(:, remove_pos(1)) = nan;
    % remove the rest
    decoding_measures_str(remove_pos(2:end)) = [];
    allsubj_accuracies(:, remove_pos(2:end)) = [];
elseif n_randn > 1
    % add summary behind the last entry
    summary_pos = randn_pos(end) + 1;
    decoding_measures_str = [decoding_measures_str(1:summary_pos-1) randn_summary.label decoding_measures_str(summary_pos:end)];
    allsubj_accuracies = [allsubj_accuracies(:, 1:summary_pos-1) nan(size(allsubj_accuracies, 1), 1) allsubj_accuracies(:, summary_pos:end)]; 
end

%% add empty lines every second line
% for publication figure to compare to sets

if isfield(beh_cfg, 'add_empty_lines_from')
    if ~any(beh_cfg.add_empty_lines_from == [1 2])
        error('beh_cfg.add_empty_lines_from must be 1 or 2')
    end
    % so we can overlay unequal and equal variance sets
    new_selected_measures = cell(length(decoding_measures_str)*2, 1);
    new_selected_measures(:) = {' '}; % init all as empty lines
    new_selected_measures(beh_cfg.add_empty_lines_from:2:end) = decoding_measures_str;
    decoding_measures_str = new_selected_measures;
    
    % also add same rows in subject accuracy data
    new_allsubj_accuracies = nan(size(allsubj_accuracies, 1), size(allsubj_accuracies, 2)*2); 
    new_allsubj_accuracies(:, beh_cfg.add_empty_lines_from:2:end) = allsubj_accuracies;
    allsubj_accuracies = new_allsubj_accuracies;
    
    save_file = [save_file '_emptyLns'];
    
    if exist('summary_pos', 'var')
        summary_pos = find(strcmp(randn_summary.label, decoding_measures_str));
        if length(summary_pos) ~= 1
            error('Could not redefine summary string position, please check')
        end
    end
end


%% Shorten names

if ~isfield(beh_cfg, 'shorten_names')
    shorten_names = 1; % by default, create shorter names
else
    shorten_names = beh_cfg.shorten_names;
end

if shorten_names
    display('Shortening names by replacing')
    % replace the first column by the second column
    if isfield(beh_cfg, 'repl')
        repl = beh_cfg.repl;
    else    
        repl = {
            'nan', '';
            'regexp:^', '';
            '$', '';
            '.*', '*';
            '*', ' x'; % regular expressions, x
            '[0-9]', '';
            '.curr.', ' ';
            ... % '.prev.', '(t-1)'; % below
            'condition', 'cnd';
            }
    end
    
    % replace all
    for r_ind = 1:size(repl, 1)
        decoding_measures_str = strrep(decoding_measures_str, repl{r_ind, 1}, repl{r_ind, 2});
    end
    
    % find all .prev. markers and replace by (t-1) at end
    prev_pos = find(~cellfun(@isempty, strfind(decoding_measures_str, '.prev.')));
    for p_ind = 1:length(prev_pos)
        pp = prev_pos(p_ind);
        decoding_measures_str{pp} = [decoding_measures_str{pp} '(t-1)'];
    end
    decoding_measures_str = strrep(decoding_measures_str, '.prev.', ' ');
    
    % remove outer spaces
    decoding_measures_str = strtrim(decoding_measures_str);  
end

%% Open figure
titlestr = beh_cfg.name;

if isfield(beh_cfg, 'position')
    fhl = figure('name', titlestr, 'Position', beh_cfg.position); % in pixel
else
    if ~show_subj_figure && ~show_detail_figure
        fhl = figure('name', titlestr, 'units', 'normalized', 'outerposition', [0 0 .75 1]); % create fullscreen figure
    else
        fhl = figure('name', titlestr, 'units', 'normalized', 'outerposition', [0 0 1 1]); % create fullscreen figure
    end
end
% title will again be added at the end

%% visualize all results

if show_detail_figure
    arh = subplot(2,2,[1 3]);
    % set & try to discretize colormap
    try
        % Get number of unique accuracy values to set number of levels
        unique_values = unique(allsubj_accuracies(:));
        % get minimum distance between nearest unique values and assume all are
        % equally spaced
        minimum_dist = min(diff(unique_values));
        quants = linspace(0, 1, round((max(unique_values) - min(unique_values)) / minimum_dist));
        colormap(discretise_colormap(gray, [], quants))
    catch e
        e
        display('discretising colormap failed, probably function does not exist. dont care')
        colormap('gray')
    end


    if plot_orientation == 0 % subjects on y-axis, old format
        imagesc(allsubj_accuracies);
        colorbar;
        % set(gca, 'FontSize', 9)
        set(gca, 'YTick', 1:length(subj_names))
        set(gca, 'YTickLabel', subj_names)
        if show_subj_figure
            set(gca, 'YTick', []); % dont show ytick labels, same as in plot on the right
        end
        set(gca, 'XTick', 1:length(decoding_measures_str)) % necessary for xticklabel to work properly
        set(gca, 'XTickLabel', decoding_measures_str) % necessary for xticklabel to work properly
        drawnow; % add drawnow before xticklabel_rotate - otherwise drawing might be to fast
        try xticklabel_rotate([], 90, decoding_measures_str, 'interpreter', 'none'); catch e, e, display('xticklable_rotate did not work, maybe not in path'), end
    else % subjects on x-axis
        imagesc(allsubj_accuracies');
        colorbar;
        % set(gca, 'FontSize', 9)
        set(gca, 'XTick', 1:length(subj_names))
        set(gca, 'XTickLabel', subj_names)
        % write all ticklabels manually, so we find and color them later
        % if show_subj_figure == 1 % only show names if the alignment to the main plot is not the same
        set(gca, 'YTick', 1:length(decoding_measures_str)) % necessary for xticklabel to work properly
        set(gca, 'YTickLabel', decoding_measures_str) % necessary for xticklabel to work properly
        set(gca, 'YTick', []); % remove tick labels
        xlims = get(gca, 'xlim');
        for dms_ind = 1:length(decoding_measures_str)
            text(xlims(1), dms_ind, decoding_measures_str{dms_ind}, 'HorizontalAlignment','right', 'Interpreter', 'none')
        end       
        % end
        drawnow; % add drawnow before xticklabel_rotate - otherwise drawing might be to fast
        try xticklabel_rotate([], 90, subj_names, 'interpreter', 'none'); catch e, e, display('xticklable_rotate did not work, maybe not in path'), end
    end
    
    
    % add description as text
    if isfield(beh_cfg, 'decoding_str')
        text(1, .5, beh_cfg.decoding_str, 'BackgroundColor',[.7 .9 .7], 'Interpreter', 'none')
    end
end

%% plot mean for each subject
if show_subj_figure

    if show_detail_figure
        subplot(3, 2, 2)
    else
        subplot(3, 1, 1)
    end

    if length(decoding_measures_str) == 1 || (isfield(beh_cfg, 'selected_decoding_measures') && length(beh_cfg.selected_decoding_measures) == 1)
        if plot_orientation == 0 % subjects on y-axis, old format
            % boxplot does not work as expected, use a horizontal bar instead
            barh(allsubj_accuracies')
        else % subjects on x-axis
            bar(allsubj_accuracies')
        end
    else
        if plot_orientation == 0 % subjects on y-axis, old format
            boxplot(allsubj_accuracies', 'orientation', 'horizontal', 'plotstyle', 'compact');
        else
            boxplot(allsubj_accuracies', 'plotstyle', 'compact');
        end
    end
    
    if plot_orientation == 0 % subjects on y-axis, old format
        if isfield(beh_cfg, 'da_lims')
            xlim(beh_cfg.da_lims);
        end
        
        set(gca, 'YTick', 1:length(subj_names))
        set(gca, 'YTickLabel', subj_names)
        % set(gca, 'FontSize', 7)
        set(gca,'YDir','reverse'); % make it same direction as imagesc
        % add 0 line
        hold on, plot([0, 0], get(gca, 'ylim'), ':k')
    else
        if isfield(beh_cfg, 'da_lims')
            ylim(beh_cfg.da_lims);
        end
        
        set(gca, 'XTick', 1:length(subj_names))
        set(gca, 'XTickLabel', subj_names)
        % set(gca, 'FontSize', 7)
        % add 0 line
        hold on, plot(get(gca, 'xlim'), [0, 0], ':k')
        drawnow
        try xticklabel_rotate([], 90, subj_names, 'interpreter', 'none'); catch e, e, display('xticklable_rotate did not work, maybe not in path. Rotation and colorchange of text will not work'), end
    end


    %% calculate ttest, add * <.1 and *MIN* > 0.9

    bonferroni_low = .05 / length(subj_names);
    bonferroni_up  = 1 - (.05 / length(subj_names));
    % set colors for bonferroni values
    color_p = [     bonferroni_low      .05    .1        .9    .95     bonferroni_up        inf];
    
    for bar_ind = 1:size(allsubj_accuracies, 1)
        [H, p] = ttest(allsubj_accuracies(bar_ind, :), [], .05, 'right');
        xlims = get(gca, 'xlim');
        ylims = get(gca, 'ylim');
        
        if plot_orientation == 0 % subjects on y-axis, old format
            xpos = xlims(2);
            ypos = bar_ind;
            rot = 0;
        else
            xpos = bar_ind;
            ypos = ylims(2);
            rot = 90;
        end
        
        % get text color
    txt_color = colors(find(p < color_p, 1, 'first'), :);
    txt_marker = txtmarker(find(p < color_p, 1, 'first'));
    txt_weight = fontweights(find(p < color_p, 1, 'first'));
    if isempty(txt_color), txt_color = color_std; end % e.g. if p = nan
    if isempty(txt_marker), txt_marker = {''}; end
    if isempty(txt_weight), txt_weight = {'normal'}; end % e.g. if p = nan
    
    % write text
    if p > 0.001
        p_text = sprintf(' p=%.03f%s', p, txt_marker{1});
    else
        % write smaller than 
        % p_text = sprintf(' p<0.001%s', p, txt_marker{1});
        % or scientific
        p_text = sprintf(' p=%f%s', p, txt_marker{1});
    end
    text(xpos, ypos, p_text, 'Color', txt_color, 'Rotation', rot, 'FontWeight', txt_weight{1}, 'FontName','Arial');
   
    end

    xlims = get(gca, 'xlim');
    ylims = get(gca, 'ylim');
    % report bonferroni value
    text(xlims(2)*1.05, ylims(2)*1.05, [' bonf. \alpha^-=' sprintf('%.03f', bonferroni_low) ...
        ', \alpha^+=' sprintf('%.03f', bonferroni_up)], 'HorizontalAlignment', 'right', 'FontSize', 8, 'Color', color_std);

end

%% plot boxplot per condition
if show_subj_figure
    if show_detail_figure
        subplot(3, 2, [4 6])
    else
        subplot(3, 1, [2 3])
    end
else
    if show_detail_figure
        subplot(2, 2, [2, 4])
    else
        if plot_orientation == 0 
            subplot(5, 1, 3) % enough space up and down
        else
            subplot(1, 5, 3) % enough space left and right
        end
    end
end

if plot_orientation == 0 % subjects on y-axis, old format
    if length(subj_names) == 1
        % boxplot does not what is expected for only 1 subj, use a bar instead
        bar(allsubj_accuracies);
    else
        boxplot(allsubj_accuracies, 'plotstyle', 'compact', 'colors',  'colors', .5*[1 1 1]);
    end
    
    if isfield(beh_cfg, 'da_lims')
        ylim(beh_cfg.da_lims);
    end
    
    % set(gca, 'FontSize', 8)
    set(gca, 'XTick', 1:length(decoding_measures_str)) % necessary for xticklabel to work properly
    set(gca, 'XTickLabel', decoding_measures_str) % necessary for xticklabel to work properly
    drawnow; % add drawnow before xticklabel_rotate - otherwise drawing might be to fast
    try xticklabel_rotate([], 90, decoding_measures_str, 'interpreter', 'none'); catch e, e, display('xticklable_rotate did not work, maybe not in path. Rotation and colorchange of text will not work'), end
    % add 0 line
    hold on, plot(get(gca, 'xlim'), [0, 0], ':k')
    ylabel('accuracy minus chance [%]');
    xlabel('');
    
    % add randn text, if it exist
    if exist('randn_summary', 'var')
        text(summary_pos, mean(get(gca, 'ylim')), randn_summary.text, 'Color', randn_summary.color, 'HorizontalAlignment', 'center', 'Rotation', 90);
    end
   
    
else % new orienation
     if length(subj_names) == 1
        % boxplot does not what is expected for only 1 subj, use a bar instead
        barh(allsubj_accuracies);
    else
        boxplot(allsubj_accuracies, 'Orientation', 'horizontal', 'plotstyle', 'compact', 'colors', .5*[1 1 1]);
    end
    % set(gca, 'FontSize', 8)
    % set ytick labels, but overwrite them later
    set(gca, 'YTick', 1:length(decoding_measures_str)) % necessary for xticklabel to work properly
    set(gca, 'YTickLabel', decoding_measures_str) % necessary for xticklabel to work properly
    % write all ticklabels manually, so we find and color them later
    set(gca, 'YTick', []) % remove original yticks
    ylabel(''); % remove ylabel
    xlabel({'accuracy minus chance [%]'})
    
    if isfield(beh_cfg, 'da_lims')
        xlim(beh_cfg.da_lims);
    end
    
    xlims = get(gca, 'xlim');
    for dms_ind = 1:length(decoding_measures_str)
        text(xlims(1), dms_ind, decoding_measures_str{dms_ind}, 'HorizontalAlignment','right', 'Interpreter', 'none')
    end        
    
    % add randn text, if it exist
    if exist('randn_summary', 'var')
        if show_detail_figure || show_subj_figure
            text(mean(get(gca, 'xlim')), summary_pos, randn_summary.text, 'Color', randn_summary.color, 'HorizontalAlignment', 'center');
        else
            text(xlims(2), summary_pos, randn_summary.text, 'Color', randn_summary.color);
        end
    end
    
    set(gca,'YDir','reverse'); % make it same direction as imagesc
    % add 0 line
    hold on, plot([0, 0],get(gca, 'ylim'), ':k')
end

if exist('randn_summary', 'var')
    % change color of randn summary text texts
    set(findobj(gca, 'String', randn_summary.label), 'Color', randn_summary.color)
    if exist('arh', 'var')
        set(findobj(arh, 'String', randn_summary.label), 'Color', randn_summary.color) % in all subject axis
    end
end

%% calculate ttest, add * <.1 and *MIN* > 0.9
bonferroni_low = .05 / length(decoding_measures_str);
bonferroni_up  = 1 -(.05 / length(decoding_measures_str));
% set colors for bonferroni values
color_p = [     bonferroni_low      .05    .1        .9    .95     bonferroni_up        inf];

for bar_ind = 1:size(allsubj_accuracies, 2)
    [H, p] = ttest(allsubj_accuracies(:, bar_ind), [], .05, 'right');
    % keep p-value to return it
    decodingstr_p_values.p(bar_ind) = p;
    decodingstr_p_values.decoding_measures_str{bar_ind} = decoding_measures_str{bar_ind};
    
    curr_text = decoding_measures_str{bar_ind};
    
    % do nothing if current text = ''
    if isempty(curr_text) || strcmp(curr_text, ' ') || strncmp(curr_text, '--', 2) || strncmp(curr_text, '..', 2)
        display(sprintf('  Omitting text for row %i because decoding_measures_str is empty', bar_ind))
        continue
    end

    xlims = get(gca, 'xlim');
    ylims = get(gca, 'ylim');

    if plot_orientation == 0 % subjects on y-axis, old format
        xpos = bar_ind;
        ypos = ylims(1);
        rot = 90;
    else
        xpos = xlims(2);
        ypos = bar_ind;
        rot = 0;
    end

        % get text color
    txt_color = colors(find(p < color_p, 1, 'first'), :);
    txt_marker = txtmarker(find(p < color_p, 1, 'first'));
    txt_weight = fontweights(find(p < color_p, 1, 'first'));
    if isempty(txt_color), txt_color = color_std; end % e.g. if p = nan
    if isempty(txt_marker), txt_marker = {''}; end
    if isempty(txt_weight), txt_weight = {'normal'}; end % e.g. if p = nan
    
    % write text
    if p > 0.001
        p_text = sprintf(' p=%.03f%s', p, txt_marker{1});
    else
        % p_text = sprintf(' p<0.001%s', p, txt_marker{1});
        % or scientific
        p_text = sprintf(' p=%f%s', p, txt_marker{1});
    end
    text(xpos, ypos, p_text, 'Color', txt_color, 'Rotation', rot, 'FontWeight', txt_weight{1}, 'FontName','Arial');
   
    % change color of all these texts
    set(findobj(gca, 'String', curr_text), 'Color', txt_color)
    if exist('arh', 'var')
        set(findobj(arh, 'String', curr_text), 'Color', txt_color) % in all subject axis
    end
end

xlims = get(gca, 'xlim');
ylims = get(gca, 'ylim');
% report bonferroni value
bonf_text = [' bonf. \alpha^-=' sprintf('%.03f', bonferroni_low) ...
        ', \alpha^+=' sprintf('%.03f', bonferroni_up)];
if plot_orientation == 0
    text(0, ylims(1), bonf_text, 'FontSize', 8, 'Color', color_std);
else
    text(xlims(2), 0, bonf_text, 'FontSize', 8, 'Color', color_std);
end

%% Show bar plot of randn above chance accuracy, if nothing else should be
%% shown

if exist('randn_summary', 'var')
    try
        if ~show_subj_figure && ~show_detail_figure
            if plot_orientation == 0 
                subplot(5, 2, 10) % enough space up and down
            else
                subplot(2, 5, 10) % enough space left and right
            end
            bar(randn_summary.pSig*100, 'Facecolor', 'white');
            hold on
            plot([.5 1.5], [.05 .05]*100, 'k');
            errorbar(1, randn_summary.pSig*100, (randn_summary.binoCI95(1)-randn_summary.pSig)*100, (randn_summary.binoCI95(2)-randn_summary.pSig)*100, 'k');
            set(gca, 'XTickLabel', 'randn summary')
            xlabel(['n=' int2str(length(randn_summary.H))])
            ylabel(['% 2nd level p<.05'])
            ylim([0 50])
        end
    catch
       display('Displaying randn summary barplot failed, dont care')
    end
end        
    
%% Add info about this figure

axes('Position', [0 0 1 1], 'Units', 'normalized', 'Visible','off');
% add titlestr, if it exists
if exist('titlestr', 'var')
    text(.5, .98, titlestr, 'Units', 'normalized', 'Interpreter', 'none', ...
        'HorizontalAlignment', 'center')
end
    
info_text = {};
info_text{end+1} = ['Plotted ' datestr(now)];
if exist('save_file', 'var')
    info_text{end+1} = strtrim(save_file);
end

text(.02, .04, info_text, 'color', [.5 .5 .5], ...
    'FontSize', 8, ...
    'Units', 'normalized', ...
    'Interpreter', 'none', ...
    'VerticalAlignment', 'Baseline')


%% Save figure
if exist('save_file', 'var') && ~isempty(save_file)
    display(['Saving figure to ' save_file])
    save_fig(save_file, beh_cfg)
else
    warning('save_file or beh_cfg.savedir not provided, dont know where to save result')
end
