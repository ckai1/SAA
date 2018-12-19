% function [regressor_names, all_data] = extract_behavioural_data_and_masks(Sess, decoding_measure_sets)
%
% This function prepares data for confound/behavioural decoding. It works 
% on sorted data from Sess and extracts the data for the decoding measures
% provided in decoding_measure_sets so that it can later be used with 
% 
%   [cfg, passed_data] = get_passed_data_incl_masks(cfg, all_data)
% to start
%   [result, decoding_cfg] = decoding(cfg, passed_data);
%
% IN
%   Sess(sess_ind).U(cond)
%       .name{1}: contains name of current condition
%       .(otherfields): Other fields & subfields contain the data specified 
%           in decoding_measure_sets
%   decoding_measure_sets{n_sets}{decoding_measure_ind}: Contains n_sets
%       of decodingmeausers. Each decoding_measure_sets{n_sets} itself is a
%       cellstr, where each string is one subfield below each
%       Sess(sess_ind).U(cond).
% 
% OUT
%     regressor_names: a 3-by-n cell matrix.
%     regressor_names(1, :) -  shortened names of the regressors
%       If more than one basis function exists in the design matrix (e.g. as is
%       the case for FIR designs), each regressor name will be extended by a
%       string ' bin 1' to ' bin m' where m refers to the number of basis
%       functions.
%     regressor_names(2, :) - experimental run/session of each regressors
%     regressor_names(3, :) - full name of the SPM regressor
%
%     all_data: A mystical struct, that needs to be plugged in into
%       get_passed_data_incl_masks(cfg, all_data) later.

% History
% 2014-Mar-31, Kai
%   Enabled single fields with multiple dimensions
%   Added header

function [regressor_names, all_data] = extract_behavioural_data_and_masks(Sess, decoding_measure_sets)

% get the full tree
U_subfield_tree = get_full_Sess_subfield_tree(Sess);

% get all fields of Sess decoding that fit to each decoding_measure_set
for decoding_measure_set_ind = 1:length(decoding_measure_sets)
    expanded_measure_fields{decoding_measure_set_ind} = get_expanded_measure_fields(U_subfield_tree, decoding_measure_sets{decoding_measure_set_ind});
end

% get unique fields
unique_expanded_measure_fields = unique([expanded_measure_fields{:}]);

% get data for all unique fields
dispv(1, 'Collecting data for all sessions & conditions for all unique fields')
[out.data, out.col_names, out.row_session, out.row_cond, out.row_name, col_condition_only] = collect_data(unique_expanded_measure_fields, Sess);

%% get regressor_names variable

% regressor_names(1, :) -  shortened names of the regressors

regressor_names(1, :) = out.row_cond;
% regressor_names(2, :) - experimental run/session of each regressors
regressor_names(2, :) = num2cell(out.row_session);
% regressor_names(3, :) - full name of the SPM regressor
regressor_names(3, :) = out.row_name;

% %% put data into cfg and passed_data
% cfg.files.name = out.row_name;
% cfg.files.descr(1:length(cfg.files.name), 1) = out.row_cond; % add condition as description
% cfg.files.step(1:length(cfg.files.name), 1) = out.row_session;
% % store names of data dimensions, too
% cfg.data_dimension_names = out.col_names;
%
% % passed_data
all_data.data = out.data;
all_data.mask_index = 1:size(all_data.data, 2); % use all voxels. These are NOT the ROI masks, only the indices of the voxels in the brain (which makes not much sense here)
all_data.files.name = out.row_name;
all_data.files.descr(1:length(all_data.files.name), 1) = out.row_cond; % add condition as description
all_data.files.step(1:length(all_data.files.name), 1) = out.row_session;
all_data.dimension_names = out.col_names; % detailed name for each dimension
all_data.hdr = ''; % we don't need a header, because we don't write img-files as output (but mat-files)
all_data.dim = [size(all_data.data, 2), 1, 1]; % add dimension information of the original data
%
%% create corresponding ROI masks and put into cfg and passed_data
%
% create one mask for each decoding_measure_set
dispv(1, 'Creating one mask for each decoding_measure_set')
for decoding_measure_set_ind = 1:length(decoding_measure_sets)
    curr_set = decoding_measure_sets{decoding_measure_set_ind};
    if ischar(curr_set)
        % for convinience, convert string to set with one entry
        curr_set = {curr_set};
    end
    all_data.masks.mask_data{decoding_measure_set_ind, 1} = get_mask(curr_set, out.col_names, col_condition_only);
    all_data.files.mask{decoding_measure_set_ind, 1} = sprintf('%s, ', curr_set{:});
end
% cfg.files.mask = all_data.files.mask;

%% subfunction to get full subfield tree
function U_subfield_tree = get_full_Sess_subfield_tree(Sess)
for sess_ind = 1:length(Sess)
    for u_ind = 1:length(Sess(sess_ind).U)
        % first, get all fields that are required
        curr_U_subfieldtree = get_subfield_tree(Sess(sess_ind).U(u_ind));
        if sess_ind == 1 && u_ind == 1
            U_subfield_tree = curr_U_subfieldtree;
        else
            if ~isequal(U_subfield_tree, curr_U_subfieldtree)
                % get something we can read
                s2h = [{'curr_U_subfieldtree '}, {'- Sess(1).U(1) - '}, curr_U_subfieldtree];
                s1h = [{'U_subfield_tree '}, {sprintf('- Sess(%i).U(%i) - ', sess_ind, u_ind)}, U_subfield_tree];
                % add empty elements to make equal length
                if length(s1h) < length(s2h)
                    s1h(end+1:length(s2h)) = {''};
                elseif length(s2h) < length(s1h)
                    s2h(end+1:length(s1h)) = {''};
                end
                % create character representation
                equal_strings(1:length(s1h), 1) = {''};
                equal_strings(~strcmp(s1h, s2h)) = {'DIFF --> '};
                equal_strings(1:2) = {''}; % dont set headers as different
                display(' ')
                display('Differences between subfields: ')
                display([char(equal_strings{:}) char(s1h{:}) char(s2h{:})])

                error('Differences between subfields of Sess(1).U(1) and Sess(%i).U(%i), please check', sess_ind, u_ind)
            end
        end
    end
end


%% subfunction: Expand current decoding_measure_set

% recursive function to find all required fields
% 
% IN
%    U_subfield_tree: tree to search for the specified measure
%    decoding_measures: defines what to look for. Can be either 
%       a string (e.g. 'nanmean.curr.RT')
%       or a list of strings (e.g. {'nanmean.curr.RT'; 'regexp:nanmean.curr.cue[0-9]*})


function expanded_subfields = get_expanded_measure_fields(U_subfield_tree, decoding_measures)

%%
expanded_subfields = {}; % init

if ischar(decoding_measures)
    % decoding_measures is a single string (e.g. 'RT')
    % we convert it into a list to make the rest of the function work
    decoding_measures = {decoding_measures};
end

for decoding_measure_ind = 1:length(decoding_measures)
    curr_measure = decoding_measures{decoding_measure_ind};
    % check if curr_measure starts with regexp:
    if length(curr_measure) > length('regexp:') && strcmp(curr_measure(1:length('regexp:')), 'regexp:')
        % get all subfields for the current expression
        regexppattern = curr_measure(length('regexp:')+1:end);
        subf_ind = find(~cellfun(@isempty, regexp(U_subfield_tree, regexppattern, 'once')));
        if isempty(subf_ind)
            warning('collect_data:U_subfield_not_found', 'No subfield matched %s', curr_measure);
        else
            new_subfields = U_subfield_tree(subf_ind);
            display(sprintf('  Decoding_measure %s expanded to [ %s]', curr_measure, sprintf('%s ', new_subfields{:})))
            expanded_subfields = [expanded_subfields; new_subfields];
        end
    else
        % check that the field indeed exists
        if any(strcmp(curr_measure, U_subfield_tree))
            display(sprintf('  Decoding_measure %s', curr_measure))
            expanded_subfields{end+1} = curr_measure;
        else
            warning('collect_data:U_subfield_not_found', 'Could not find subfield %s', curr_measure);
        end
    end
end

if isempty(expanded_subfields)
    error('No subfields found for %s, please check', sprintf('%s ', decoding_measures{:}))
end


function [data, col_names, row_session, row_cond, row_name, col_condition_only] = collect_data(expanded_subfields, Sess)

data = [];

for sess_ind = 1:length(Sess)
    for u_ind = 1:length(Sess(sess_ind).U)

        %% get data for a single U
        U = Sess(sess_ind).U(u_ind);
        % init values
        values = [];
        curr_col_names = {}; % init name for each dimension

        % go through the evaluated subfields (these should exist now)
        for exp_subfield_ind = 1:length(expanded_subfields)

            curr_subfield = expanded_subfields{exp_subfield_ind};

            % use the name directly
            eval(['curr_values = U.' curr_subfield ';']);

            % check dimensionality, should be 1 or 2
            if length(size(curr_values)) > 2
                error('Can only deal with 2d data here (1d vector for each pattern)')
            end

            % all measures for each U must have the same amount of values,
            % because each value is seen as one sample
            if exp_subfield_ind == 1
                n_samples = size(curr_values, 2); % was: length(curr_values);
            else
                if n_samples ~= size(curr_values, 2); % was: length(curr_values);
                    error('Different number of entries in Sess(%i).U(%i) for measure %s and %s. Only same amount of values can be collected, because each value is one dimension in a pattern.', sess_ind, u_ind, expanded_subfields{1}, curr_subfield);
                end
            end

            % was: isvector(curr_values) && in the beginning
            if (isnumeric(curr_values) || islogical(curr_values) || ischar(curr_values))
                
                % PROGRAMMING: It's confusing that we call the rows in the
                % matrix below  'columns'. This is because below we switch 
                % orientation.
                % Sorry.
                
                % get indices of the columns where we put the current data
                current_columns = [1:size(curr_values, 1)] + size(values, 1);
                
                % save with dimension indices
                for dim_ind = 1:length(current_columns)
                    % store names for values
                    curr_col_names{current_columns(dim_ind), 1} = [curr_subfield, sprintf('.d(%i)', dim_ind)]; % must be equal for all U & all sessions
                end
                
                % also save current column numbers in a struct with the
                % name of the current subfield, so that we can easily
                % retrieve them when we get the mask later
                col_condition_only(current_columns) = {curr_subfield};

                % add to values
                values(current_columns, :) = curr_values;
                % new should be: multiple rows should be added here and we can directly
                % provide labels for them
            else
                error('U.%s does not contain values, but might e.g. be a struct or a matrix. The subfunction here can only take vector entries.', curr_subfield)
            end
        end
        %% check that columns have the same name
        if isempty(data) % first time here
            col_names = curr_col_names;
        elseif ~isequal(col_names, curr_col_names)
            error('Somehow the columns have different names here. Maybe k patterns of n-dimensional data has been passed in the wrong orientation and is now interpreted as n patterns of k-dimensional data? Please check')
        end

        %% add it to data matrix
        dispv(1, '  Sess(%i).U(%i): Adding %i pattern with %i dimension(s)', sess_ind, u_ind, size(values, 2), size(values, 1));
        % was
        % dispv(1, '  Sess(%i).U(%i): Adding %i pattern with %i dimension(s)', sess_ind, u_ind, size(values, 1), size(values, 2));

        new_rows = (1:size(values, 2)) + size(data,1);

        % PROGRAMMING REMARK
        % ORIENTATION CHANGE
        % changing direction of pattern: From here on, a pattern is one
        % row, no longer one column :(

        data(new_rows, :) = values';
        row_session(new_rows, 1) = sess_ind;
        row_cond(new_rows, 1) = U.name(1);
        for r_ind = 1:length(new_rows)
            curr_row = new_rows(r_ind);
            row_name(curr_row, 1) = {sprintf('Sess(%i).U(%i).p(%i):%s', sess_ind, u_ind, r_ind, U.name{1})};
        end

        % would be a nicer way, but does not fit to decoding passed_data at
        % the moment
        %         data.Sess(sess_ind).U(u_ind).data = values;
        %         data.Sess(sess_ind).U(u_ind).col_names = expanded_subfields;
    end
end

%% Function to get a number of masks to that the data of each decoding 
% measure (combination/regexp) will be analysed as one "ROI" analysis
% (making computation much much faster)
%
% IN
%    decoding_measures: defines what to look for. Can be either 
%       a string (e.g. 'nanmean.curr.RT')
%       or a list of strings (e.g. {'nanmean.curr.RT'; 'regexp:nanmean.curr.cue[0-9]*})
%   col_names: Names of all columnes (i.e. measures + dimensions) as cellstr
%   col_condition_only: Names of all columnes without dimension

function mask_ind = get_mask(decoding_measures, col_names, col_condition_only)

%%
% init: empty mask
mask_ind = false(1, length(col_names));

if ischar(decoding_measures)
    % decoding_measures is a single string (e.g. 'RT')
    % we convert it into a list to make the rest of the function work
    decoding_measures = {decoding_measures};
end

for decoding_measure_ind = 1:length(decoding_measures)
    curr_measure = decoding_measures{decoding_measure_ind};
    % check if curr_measure starts with regexp:
    if length(curr_measure) > length('regexp:') && strcmp(curr_measure(1:length('regexp:')), 'regexp:')
        % get all subfields for the current expression
        regexppattern = curr_measure(length('regexp:')+1:end);
        subf_ind = ~cellfun(@isempty, regexp(col_condition_only, regexppattern, 'once'));
    else
        % check that the field indeed exists
        subf_ind = strcmp(curr_measure, col_condition_only);
    end
    if ~any(subf_ind)
        warning('get_mask:decoding_measure_not_found', 'Could not find any entry for %s', curr_measure);
    end
    mask_ind = mask_ind | subf_ind;
end

if ~any(mask_ind)
    error('No single entry selected in mask for measures %s, please check (All expanded fields: %s)', sprintf('%s ', decoding_measures{:}),  sprintf('%s ', col_condition_only{:}))
end