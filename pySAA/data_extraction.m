function [all_data, regressor_names] = data_extraction(Sess, decoding_sets)
% This function gets the data points corresponding to the decoding sets for
% all the session of a given subject. It uses this information to create
% the data masks, and an array of regressor names, used for decoding.
% IN:
%    Sess: data structure with all the sessions of a given subject
%    decoding_sets: cell array whose elements are lists of SAA variables
% OUTPUT:
%    all_data: A mystical struct, that needs to be plugged in into
%       get_passed_data_incl_masks(cfg, all_data) later.
%    regressor_names: a 3-by-n cell matrix.
%     regressor_names(1, :) -  shortened names of the regressors
%       If more than one basis function exists in the design matrix (e.g. as is
%       the case for FIR designs), each regressor name will be extended by a
%       string ' bin 1' to ' bin m' where m refers to the number of basis
%       functions.
%     regressor_names(2, :) - experimental run/session of each regressors
%     regressor_names(3, :) - full name of the SPM regressor

% get all SAA variables    
SAAvariables = variable_extraction(Sess);

% expand each decoding set
expanded_subfields = cell(length(decoding_sets), 1);
for set_ind = 1:length(decoding_sets)
    expanded_subfields{set_ind} = expand_measure_fields(SAAvariables, decoding_sets{set_ind});
end

% get unique values
expanded_subfields = unique([expanded_subfields{:}]);

% get data for all unique fields
disp('Collecting data for all sessions & conditions for all unique fields')
[all_data, regressor_names, col_condition_only] = collect_data(Sess, expanded_subfields);

% Generate masks
disp('Creating one mask for each decoding_measure_set')
all_data = create_mask(all_data, decoding_sets, col_condition_only);

end

%% subfunction to get all SAA variables
function SAAvariables = variable_extraction(Sess)

for sess_ind=1:length(Sess)
    for u_ind=1:length(Sess(sess_ind).U)
        if sess_ind == 1 && u_ind == 1
            SAAvariables = [Sess(sess_ind).U(u_ind).SAAdata.variable];
        else
            variables = [Sess(sess_ind).U(u_ind).SAAdata.variable];
            if ~all(strcmp(SAAvariables, variables))
                error('Differences between subfields of Sess(1).U(1) and Sess(%i).U(%i), please check', sess_ind, u_ind)
            end
        end
    end
end
end % end of function
%% subfunction: Expand decoding_measure_set
function expanded_subfields = expand_measure_fields(SAAvariables, decoding_measures)

expanded_subfields = {};
if ischar(decoding_measures)
    % decoding_measures is a single string (e.g. 'RT')
    % we convert it into a list to make the rest of the function work
    decoding_measures = {decoding_measures};
end

% add the decoding measures that exist in the SAAvariables
% if the measure is a regexp, add all matches
for decoding_measure_ind = 1:length(decoding_measures)
   curr_measure = decoding_measures{decoding_measure_ind};
   if length(curr_measure) > length('regexp:') && strcmp(curr_measure(1:length('regexp:')), 'regexp:')
       % get all subfields for the current expression
        regexppattern = curr_measure(length('regexp:')+1:end);
        occurrence = regexp(SAAvariables, regexppattern, 'once');
        subf_ind = find(~cellfun(@isempty, occurrence));
        if isempty(subf_ind)
            warning('collect_data:subfield_not_found', 'No subfield matched %s', curr_measure);
        else
            new_subfields = SAAvariables(subf_ind);
            display(sprintf('  Decoding_measure %s expanded to [ %s]', curr_measure, sprintf('%s ', new_subfields{:})))
            expanded_subfields = [expanded_subfields new_subfields];
        end
   else
        % check that the field indeed exists
        if any(strcmp(curr_measure, SAAvariables))
            display(sprintf('  Decoding_measure %s', curr_measure))
            expanded_subfields{end+1} = curr_measure;
        else
            warning('collect_data:subfield_not_found', 'Could not find subfield %s', curr_measure);
        end
   end
   
end
if isempty(expanded_subfields)
    warning('No subfields found for %s, please check', sprintf('%s ', decoding_measures{:}))
end
end % end of function
%% subfunction that extracts data from Sessions according to the expanded subfields
function [all_data, regressor_names, col_condition_only] = collect_data(Sess, expanded_subfields)

out.data = [];
for sess_ind = 1:length(Sess)
    for u_ind = 1:length(Sess(sess_ind).U)
        U = Sess(sess_ind).U(u_ind);
        % init values
        values = [];
        curr_col_names = {}; % init name for each dimension

        % go through the evaluated subfields (these should exist now)
        for exp_subfield_ind = 1:length(expanded_subfields)
            curr_subfield = expanded_subfields{exp_subfield_ind};
            data_points = {U.SAAdata.data_points};
            curr_values = data_points{strcmp([U.SAAdata.variable], curr_subfield)};
            
            % check dimensionality, should be 1 or 2
            if length(size(curr_values)) > 2
                error('Can only deal with 2d data here (1d vector for each pattern)')
            end
            
            % all measures for each U must have the same amount of values,
            % because each value is seen as one sample
            if exp_subfield_ind == 1
                n_samples = length(curr_values);
            else
                if n_samples ~= length(curr_values) 
                    error('Different number of entries in Sess(%i).U(%i) for measure %s and %s. Only same amount of values can be collected, because each value is one dimension in a pattern.', sess_ind, u_ind, expanded_subfields{1}, curr_subfield);
                end
            end
            
            if (isnumeric([curr_values{:}]) || islogical([curr_values{:}]) || ischar([curr_values{:}]))
                
                % PROGRAMMING: It's confusing that we call the rows in the
                % matrix below  'columns'. This is because below we switch 
                % orientation.
                % Sorry.
                
                % get indices of the columns where we put the current data
                current_columns = (1:size(curr_values', 1)) + size(values, 1);
                
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
                values(current_columns, :) = [curr_values{:}];
                % new should be: multiple rows should be added here and we can directly
                % provide labels for them
            else
                error('U.%s does not contain values, but might e.g. be a struct or a matrix. The subfunction here can only take vector entries.', curr_subfield)
            end
        end
        
        if isempty(out.data) % first time here
            out.col_names = curr_col_names;
        elseif ~isequal(out.col_names, curr_col_names)
            error('Somehow the columns have different names here. Maybe k patterns of n-dimensional data has been passed in the wrong orientation and is now interpreted as n patterns of k-dimensional data? Please check')
        end
        
        
        disp(sprintf('Sess(%i).U(%i): Adding %i pattern with %i dimension(s)', sess_ind, u_ind, size(values, 2), size(values, 1)));
        new_rows = (1:size(values, 2)) + size(out.data,1);
        
        out.data(new_rows, :) = values';
        out.row_session(new_rows, 1) = sess_ind;
        out.row_cond(new_rows, 1) = {U.name};
        for r_ind = 1:length(new_rows)
            curr_row = new_rows(r_ind);
            out.row_name(curr_row, 1) = {sprintf('Sess(%i).U(%i).p(%i):%s', sess_ind, u_ind, r_ind, U.name)};
        end
        
    end
end

% regressor_names(n, :) have the following information:
% 	n= 1 -  shortened names of the regressors
% 	n= 2 - experimental run/session of each regressors
% 	n= 3 - full name of the SPM regressor

regressor_names(1, :) = cellstr(out.row_cond);
regressor_names(2, :) = num2cell(out.row_session);
regressor_names(3, :) = out.row_name;

all_data.data = out.data;
all_data.dim = [size(all_data.data, 2), 1, 1]; % add dimension information of the original data
all_data.dimension_names = out.col_names; % detailed name for each dimension
all_data.files.descr(1:length(out.row_cond), 1) = out.row_cond; % add condition as description
all_data.files.name = out.row_name;
all_data.files.step(1:length(out.row_session), 1) = out.row_session;
all_data.hdr = ''; % we don't need a header, because we don't write img-files as output (but mat-files)
all_data.mask_index = 1:size(all_data.data, 2); % use all voxels. These are NOT the ROI masks, only the indices of the voxels in the brain (which makes not much sense here)
end % end of function
%% subfunction to create masks
function all_data = create_mask(all_data, decoding_measure_sets, col_condition_only)

for set_ind = 1:length(decoding_measure_sets)
    curr_set = decoding_measure_sets{set_ind};
    if ischar(curr_set), curr_set = {curr_set}; end
    
    %all_data.files.mask{decoding_measure_set_ind, 1} = sprintf('%s, ', curr_set{:});
    all_data.files.mask{set_ind, 1} = strjoin(curr_set, ',');
    all_data.masks.mask_data{set_ind, 1} = get_mask(curr_set, col_condition_only);
end
end % end of function
%%
function mask_ind = get_mask(decoding_measures, col_condition_only)

% init: empty mask
mask_ind = false(1, length(col_condition_only));
if ischar(decoding_measures), decoding_measures = {decoding_measures}; end

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
end % end of function