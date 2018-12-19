% Show data + model output
function plot_decoding_steps_1d(cfg, passed_data, result, decoding_measure_ind)

%% Check input
% Verify that decoding_accuracy_minus chance is first output and primal_SVM_weights is second output
% In the future, this might be adapted to be more general, if desired
if ~isequal(cfg.results.output, {'accuracy_minus_chance', 'primal_SVM_weights'})
    warning('This function is at the moment explicitly written so that it can only works for cfg.results.output = {''accuracy_minus_chance'', ''primal_SVM_weights''} . Please adapt it for other usage')
    display('Returning')
    return
end

% verify that labels are -1 and 1
% if ~isequal(unique(cfg.design.label(:)), [-1; 1])
%     warning('Can currently only work if lables are -1 and 1, returning')
%     return
% end

%% Get number of sets
n_sets = size(cfg.design.train, 2);

%% Get mask name and data for this mask
% get current decoding measure
mask_name = cfg.files.mask{decoding_measure_ind};
curr_mask = passed_data.masks.mask_data{decoding_measure_ind};
curr_set_data = passed_data.data(:, curr_mask);

%% Check masked data
% verify that we have 1d data
if size(curr_set_data, 2) ~= 1
    warning('Can currently only plot 1d data, returning')
    return
end

%% Preprare figure
% get number of sets
figure('name', mask_name)
sub_x = ceil(sqrt(n_sets)); % n cols
sub_y = ceil(n_sets./sub_x); % n rows

%% get number of classes and associate symbols to classes

unique_labels = unique(cfg.design.label(:));
% scatter_symbols = ['do+xp'];
scatter_color = ['krygb'];

%% Do plotting

subplot_ind = 0; % init

for set_ind = 1:n_sets
    subplot_ind = subplot_ind + 1;
    subplot(sub_x, sub_y, subplot_ind);
    
    %% plot training data
    set_train_inds = logical(cfg.design.train(:, set_ind));
    set_train_data = curr_set_data(set_train_inds, :);
    set_train_data_chunks = cfg.files.chunk(set_train_inds, :);
    set_train_lables = cfg.design.label(set_train_inds, set_ind);
    
    set_legend = {};
    set_legend_plots = []; % handles to curves that should be included in legend
    
    if length(unique_labels) <= length(scatter_color)
        % use two different symbols
        for c_ind = 1:length(unique_labels)
            curr_label = unique_labels(c_ind);
            curr_data = set_train_data(set_train_lables == curr_label);
            if ~isempty(curr_data)
                % add estimated distribution
                [f,x] = ksdensity(curr_data);
                plot(x,f,scatter_color(c_ind))
                % set_legend{end+1} = ['Training class ' num2str(curr_label)];
                hold all
                % add exact points
                % cycling accross symbols
                % set_legend_plots(end+1) = scatter(curr_data, zeros(size(curr_data)), 50, 'k', scatter_symbols(c_ind));
                % cycling accross color
                set_legend_plots(end+1) = scatter(curr_data, zeros(size(curr_data)), 50, scatter_color(c_ind), 'd');
                set_legend{end+1} = ['Train ' num2str(curr_label) ' [ksdens above x]'];
            end
        end
    else
        % use different color
        
        % plotting each value at height of its run (meight be confusing if
        % assumed 2d data)
        % scatter(set_train_data, set_train_data_chunks, 50, set_train_lables);
        % ylabel('run # / precited class / decision value (NOT 2d data value)')
        
        % ALTERNATIVE: plotting each value at height 0
        set_legend_plots(end+1) = scatter(set_train_data, zeros(size(set_train_data)), 50, set_train_lables);
        set_legend{end+1} = ['Training data'];
        hold all
    end
    
    xlabel('data value (1d data)')
    hold on
    
    %% plot test data
    set_test_inds = logical(cfg.design.test(:, set_ind));
    set_test_data = curr_set_data(set_test_inds, 1);
    set_test_data_chunks = cfg.files.chunk(set_test_inds, :);
    set_test_lables = cfg.design.label(set_test_inds, set_ind);
    
    % plot test data
    if length(unique_labels) <= length(scatter_color)
        % use two different symbols
        for c_ind = 1:length(unique_labels)
            curr_label = unique_labels(c_ind);
            curr_data = set_test_data(set_test_lables == curr_label);
            if ~isempty(curr_data)
                [f,x] = ksdensity(curr_data);
                plot(x,-f, scatter_color(c_ind)); % plot test data below axis
                % cycling across symbols
                % set_legend_plots(end+1) = scatter(curr_data, zeros(size(curr_data)), 50, 'r', scatter_symbols(c_ind));
                % cycling accross color
                set_legend_plots(end+1) = scatter(curr_data, zeros(size(curr_data)), 120, scatter_color(c_ind), 'c');
                set_legend{end+1} = ['Test ' num2str(curr_label) ' [ksdens below x]'];
            end
        end
        
        % using height of each run
        %     scatter(set_test_data, set_test_data_chunks, 200, set_test_lables, '+')
    else
        % ALTERNATIVE: plot at height 0
        set_legend_plots(end+1) = scatter(set_test_data, zeros(sum(set_test_inds), 1), 200, set_test_lables, '+');
        set_legend{end+1} = ['Test data'];
    end
    
    % plot decision value output
    if length(result.primal_SVM_weights.set(set_ind).output{decoding_measure_ind}) == 1
        curr_primal_weights = result.primal_SVM_weights.set(set_ind).output{decoding_measure_ind}{1};
        
        % the else part is only if older versions of the toolbox are used
    elseif length(result.primal_SVM_weights.set(set_ind).output{decoding_measure_ind}) == n_sets
        display('Seems that BUG14 of the toolbox still in place (see known_bugs). That''s ok, so dont worry here')
        curr_primal_weights = result.primal_SVM_weights.set(set_ind).output{decoding_measure_ind}{set_ind};
    else
        warning('BUG14 seems to have been resolved or the number of sets does not equal the number of steps. Don''t know how to plot the weights at the moment. Please check comments in m-file below this warning')
        % if BUG14 has really been resolved, the classifiers for this set
        % can be accessed as
        % result.primal_SVM_weights.set(set_ind).output{decoding_measure_ind}{1}
        % (normally only 1, if indeed only one step is used for each set)
        return
    end
    
    % calculate the decision boundary
    % in 1d, its simply one number:
    boundary = -curr_primal_weights.b / curr_primal_weights.w;
    % if boundary display
    if min(curr_set_data)-1 < boundary && boundary < max(curr_set_data)+1
        x_curr_data = [min(curr_set_data)-1, boundary-10*eps, boundary+10*eps, max(curr_set_data)+1];
    else % dont plot the boundary (e.g. if boundary is at infinity)
        x_curr_data = [min(curr_set_data)-1, max(curr_set_data)+1];
    end
    % plot
    y_curr_data = (curr_primal_weights.w * x_curr_data) + curr_primal_weights.b;
    set_legend_plots(end+1) = plot(x_curr_data, 2*(y_curr_data>0)-1,'Color',[.5,.5,.5]);
    set_legend = [set_legend, {['boundary [' num2str(boundary) '] + predicted class']}];
    
    % General solution to get the y-values for all datapoints
    % x_curr_data = curr_set_data;
    %     y_curr_data = (curr_primal_weights.w * curr_set_data) + curr_primal_weights.b;
    
    % alternative: Because the problem is linear, we just need the smallest
    % and largest value. For better illustration, we increase both by one
%     x_curr_data = [min(curr_set_data)-1, max(curr_set_data)+1];
%     y_curr_data = (curr_primal_weights.w * x_curr_data) + curr_primal_weights.b;
%     set_legend_plots(end+1) = plot(x_curr_data, y_curr_data);
%     set_legend = [set_legend, {'decision values'}];
    
    % if no chunks are used
    ylim([min([y_curr_data(:); -1])-.5, max([y_curr_data(:); 1])+.5])
    % if chunks are used for xaxis
    %     ylim([min([y_curr_data(:); cfg.files.chunk(:); -1])-.5, max([y_curr_data(:); cfg.files.chunk(:); 1])+.5])
    
    % add 0 line with color of predicted class
    boundary = -curr_primal_weights.b / curr_primal_weights.w;
    % if boundary display
    if min(curr_set_data)-1 < boundary && boundary < max(curr_set_data)+1
        x_curr_data = [min(curr_set_data)-1, boundary-10*eps, boundary+10*eps, max(curr_set_data)+1];
    else % dont plot the boundary (e.g. if boundary is at infinity)
        x_curr_data = [min(curr_set_data)-1, max(curr_set_data)+1];
    end
    y_curr_data = (curr_primal_weights.w * x_curr_data) + curr_primal_weights.b;
    
    % plot in colors
    % plot side that is predicted as class 1
    plot(x_curr_data(y_curr_data<0), zeros(sum(y_curr_data<0),1), scatter_color(1));
    % plot side that is predicted as class 2
    if ~isempty(x_curr_data(y_curr_data>0))
        set_legend_plots(end+1) = plot(x_curr_data(y_curr_data>0), zeros(sum(y_curr_data>0),1), scatter_color(2));
        set_legend = [set_legend, {['predicted class 2 (color)']}];
    end
    
%     plot(get(gca, 'XLim'), [0, 0], 'k') % create 0 line
    
    %     if set_ind == 1
    legend(set_legend_plots, set_legend, 'Location','SouthEast')
    %     end
    
    % get DA_min_chance for the current set
    step_da_min_chance = result.accuracy_minus_chance.set(set_ind).output(decoding_measure_ind);
    
    title(sprintf('%s, set %i/%i, DA-chance=%f', mask_name, set_ind, n_sets, step_da_min_chance))
end