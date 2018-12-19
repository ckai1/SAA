% Use as
%
% (1) function visualize_all_decodings(result_struct)
%   or
% (2) function visualize_all_decodings(data, subj_names, decoding_measures_str, beh_cfg, save_file)
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
%       .name: title for figure
%       .decoding_str: additional text at top of subj table (e.g. display rules)
%       .savedir: (Only effective IF save_file is NOT provided)
%           Save figure as 'Visualize_all_decodings' in beh_cfg.savedir
%       .show_subj_figure: set 1, if subject histograms should be shown
%       (default: 0 for more than 1 measure)
%   save_file: Exact name (without extension) to specify where to save the
%       the result figure. E.g. 'mydir/myfigure' (without .png)


function visualize_all_decodings(data_or_struct, subj_names, decoding_measures_str, beh_cfg, save_file)

if isstruct(data_or_struct)

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

else
    % data for table provided directly, just map
    allsubj_accuracies = data_or_struct;
end
clear allsubj_accuracies_or_struct

%% set defaults
if ~exist('beh_cfg', 'var')
    beh_cfg = [];
    if isfield(data_or_struct, 'save_file') % for compatibility reasons
        beh_cfg.save_file = data_or_struct.save_file;
    end
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

%% Only plot 10 randn regressors, if there are more
randn_pos_ind = ~cellfun(@isempty, strfind(decoding_measures_str, 'curr.randn'));
randn_pos = find(randn_pos_ind);
n_randn = sum(randn_pos_ind);

if n_randn > 10
    remove_pos = randn_pos(10:end-1);
    warning('More than 10 randn predictors detected, reduce plotting to only 10')
    allsubj_accuracies(:, remove_pos) = [];
    decoding_measures_str(remove_pos) = [];
end

%% Open figure
titlestr = beh_cfg.name;
figure('name', titlestr, 'Position', [0 0 1024 768]) % 'units', 'normalized', 'outerposition', [0 0 1 1]) % create fullscreen figure

%% visualize all results
arh = subplot(2,2,[1 3]);
title(titlestr)
% set & try to discretize colormap
try
    colormap(discretise_colormap(gray))
catch e
    e
    display('discretising colormap failed, probably function does not exist. dont care')
    colormap('gray')
end

imagesc(allsubj_accuracies);
colorbar;
% set(gca, 'FontSize', 9)
set(gca, 'YTick', 1:length(subj_names))
set(gca, 'YTickLabel', subj_names)
set(gca, 'XTick', 1:length(decoding_measures_str)) % necessary for xticklabel to work properly
set(gca, 'XTickLabel', decoding_measures_str) % necessary for xticklabel to work properly
drawnow; % add drawnow before xticklabel_rotate - otherwise drawing might be to fast
try xticklabel_rotate([], 90, decoding_measures_str, 'interpreter', 'none'); catch e, e, display('xticklable_rotate did not work, maybe not in path'), end

%% add description as text

if isfield(beh_cfg, 'decoding_str')
    text(1, .5, beh_cfg.decoding_str, 'BackgroundColor',[.7 .9 .7], 'Interpreter', 'none')
end

%% plot mean for each subject
if show_subj_figure == 1

    subplot(3, 2, 2)

    if length(decoding_measures_str) == 1
        % boxplot does not work as expected, use a horizontal bar instead
        barh(allsubj_accuracies')
    else
        boxplot(allsubj_accuracies', 'orientation', 'horizontal');
    end
    set(gca, 'YTick', 1:length(subj_names))
    set(gca, 'YTickLabel', subj_names)
    % set(gca, 'FontSize', 7)
    set(gca,'YDir','reverse'); % make it same direction as imagesc
    % add 0 line
    hold on, plot([0, 0], get(gca, 'ylim'), ':k')


    %% calculate ttest, add * <.1 and *MIN* > 0.9

    bonferroni_low = .05 / length(subj_names);
    bonferroni_up  = 1 - (.05 / length(subj_names));

    for bar_ind = 1:size(allsubj_accuracies, 1)
        [H, p] = ttest(allsubj_accuracies(bar_ind, :), [], .05, 'right');
        xlims = get(gca, 'xlim');
        if p < .1
            if p < bonferroni_low
                text(xlims(2), bar_ind, sprintf('p=%.03f %s', p, subj_names{bar_ind}), 'Color', 'r');
            else
                text(xlims(2), bar_ind, sprintf('p=%.03f %s', p, subj_names{bar_ind}), 'Color', 'y');
            end
        end
        if p > .9
            if p > bonferroni_up
                text(xlims(2), bar_ind, sprintf('p=%.03f %s', p, subj_names{bar_ind}), 'Color', 'r');
            else
                text(xlims(2), bar_ind, sprintf('p=%.03f %s', p, subj_names{bar_ind}), 'Color', 'y');
            end
        end
    end

    xlims = get(gca, 'xlim');
    ylims = get(gca, 'ylim');
    % report bonferroni value
    text(xlims(2), ylims(2), {['\alpha^-_{bonferroni}=' sprintf('%.03f', bonferroni_low)];
        ['\alpha^+_{bonferroni}=' sprintf('%.03f', bonferroni_up)]});

end

%% plot boxplot per condition
if show_subj_figure == 1
    subplot(3, 2, [4 6])
else
    subplot(2, 2, [2, 4])
end

if length(subj_names) == 1
    % boxplot does not what is expected for only 1 subj, use a bar instead
    bar(allsubj_accuracies);
else
    boxplot(allsubj_accuracies);
end
% set(gca, 'FontSize', 8)
set(gca, 'XTick', 1:length(decoding_measures_str)) % necessary for xticklabel to work properly
set(gca, 'XTickLabel', decoding_measures_str) % necessary for xticklabel to work properly
drawnow; % add drawnow before xticklabel_rotate - otherwise drawing might be to fast
% try xticklabel_rotate([], 90, decoding_measures_str, 'interpreter', 'none'); catch e, e, display('xticklable_rotate did not work, maybe not in path'), end
% add 0 line
hold on, plot(get(gca, 'xlim'), [0, 0], ':k')

%% calculate ttest, add * <.1 and *MIN* > 0.9
bonferroni_low = .05 / length(decoding_measures_str);
bonferroni_up  = 1 -(.05 / length(decoding_measures_str));

ylims = get(gca, 'ylim');
for bar_ind = 1:size(allsubj_accuracies, 2)
    [H, p] = ttest(allsubj_accuracies(:, bar_ind), [], .05, 'right');
    curr_text = decoding_measures_str{bar_ind};

    if p < .1
        if p < bonferroni_low
            text(bar_ind+.5, ylims(2), sprintf('p=%.03f\n', p), 'Rotation', 90, 'Color', 'r')
            % also recolor the text
            set(findobj(gca, 'String', curr_text), 'Color', 'r') % in current axis
            set(findobj(arh, 'String', curr_text), 'Color', 'r') % in all subject axis

        else
            text(bar_ind+.5, ylims(2), sprintf('p=%.03f\n', p), 'Rotation', 90, 'Color', 'y')
            set(findobj(gca, 'String', curr_text), 'Color', 'y')
            set(findobj(arh, 'String', curr_text), 'Color', 'y') % in all subject axis
        end
    elseif p > .9
        if p > bonferroni_up
            text(bar_ind+.5, ylims(2), sprintf('p=%.03f\n', p), 'Rotation', 90, 'Color', 'm')
            set(findobj(gca, 'String', curr_text), 'Color', 'm')
            set(findobj(arh, 'String', curr_text), 'Color', 'm') % in all subject axis
        else
            text(bar_ind+.5, ylims(2), sprintf('p=%.03f\n', p), 'Rotation', 90, 'Color', 'g')
            set(findobj(gca, 'String', curr_text), 'Color', 'g')
            set(findobj(arh, 'String', curr_text), 'Color', 'g') % in all subject axis
        end
    else
        text(bar_ind+.5, ylims(2), sprintf('p=%.03f\n', p), 'Rotation', 90)
    end
end

xlims = get(gca, 'xlim');
ylims = get(gca, 'ylim');
% report bonferroni value
text(xlims(2), ylims(2), {['\alpha^-_{bonferroni}=' sprintf('%.03f', bonferroni_low)];
    ['\alpha^+_{bonferroni}=' sprintf('%.03f', bonferroni_up)]});

%% Add warning if fields were removed

if exist('remove_pos', 'var')
    axes('Position', [0 0 1 1], 'Units', 'normalized', 'Visible','off');
    text(.03, .97, ['Warning! ' int2str(length(remove_pos)) ' randn fields have been removed'], 'color', 'r', 'Units', 'normalized')
end
    

%% Save figure

if ~exist('save_file', 'var') 
    if isfield(beh_cfg, 'save_file')
        save_file = beh_cfg.save_file;
    elseif isfield(beh_cfg, 'savedir')
        save_file = fullfile(beh_cfg.savedir, 'Visualize_all_decodings');
    end
end

% get from beh_cfg, if this exist, but save_file not
if exist('save_file', 'var')
    display(['Saving figure to ' save_file])
    save_fig(save_file, beh_cfg)
else
    warning('save_file or beh_cfg.savedir not provided, dont know where to save result')
end
