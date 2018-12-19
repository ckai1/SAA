% function data = create_dummies(data)
%
% Will create dummy variables for all factorials in
%   data.Sess(s).U(u).factorial.
% and move these to
%   data.Sess(1).U(1)
%
% REMARK: The function works but is slow. If you like, feel free to create
%         the same function in fast.
%
% Example:
%
% If field
%   data.Sess(1).U(1).factorial.curr.button
% containing lists with values 34 35 31 exist, new fields
%   data.Sess(1).U(1).curr.button31
%   data.Sess(1).U(1).curr.button34
%   data.Sess(1).U(1).curr.button35
% with values 0 or 1 will be created.
%
% These can be used for e.g. SVM/LDA etc. decoding.
%
% REMARK! BE AWARE THAT FOR E.G. REGRESSION, ONLY 2 OUT OF THESE 3 DUMMY
% REGRESSORS SHOULD BE USED! (or in general one less, because they are 
% collinear)

function data = create_dummies(data)

%%
if ~isfield(data.Sess(1).U(1), 'factorial')
    warning('create_dummies:factorial_not_found', 'Sess.U.factorial not found, skipping the function')
else % create dummies for .factorial
    display('create_dummies:Creating dummies for Sess.U.factorial')
    display('Getting Sess.U.factorial subtree and verifying that all Sess.U.factorial have the same entries')
    for sess_ind = 1:length(data.Sess)
        for u_ind = 1:length(data.Sess(sess_ind).U)
            % get current subtree
            curr_subtree = get_subfield_tree(data.Sess(sess_ind).U(u_ind).factorial);
            if sess_ind == 1 && u_ind == 1
                % store for later use
                factorial_subtree = curr_subtree;
            else
                % verify it's the same
                if ~isequal(factorial_subtree, curr_subtree)
                    % check if only the order differs, if so, warn the user
                    if isequal(sort(factorial_subtree), sort(curr_subtree))
                        warning('Sess(%i).U(%i).factorial and Sess(1).U(1).factorial has same entires but different order: This might lead to problems later. Trying to continue anyway', sess_ind, u_ind)
                    else
                        error('Sess(%i).U(%i).factorial and Sess(1).U(1).factorial mismatch', sess_ind, u_ind)
                    end
                end
            end
        end
    end
    
    %% collect
    for subtree_ind = 1:length(factorial_subtree)
        curr_subtree_entry = factorial_subtree{subtree_ind};
        
        display(['Creating the following dummies from the factorial entry ' curr_subtree_entry])
        
        % collect all values for the current entry
        all_curr_values = [];
        for sess_ind = 1:length(data.Sess)
            for u_ind = 1:length(data.Sess(sess_ind).U)
                curr_values = eval(['data.Sess(sess_ind).U(u_ind).factorial.' curr_subtree_entry]);
                
                % Check if multidimensional data
                if sess_ind == 1 && size(curr_values, 1) > 1 && size(curr_values, 2) > 1
                    warning('create_dummies:multidimensional_data', 'Factorial dummy conversion does ignore dimensions of multidimensional inputs. It will only show _which_ values the vectors contain, but not _in which dimension_. If you want to keep the dimensions, split them in different variables before (e.g. myvar_Dim1=myvar(1,:), myvar_Dim2=myvar(2,:), etc.) and call calling create_dummies then.')
                end

                % not sure what the intention was here at some point
%                 if iscell(curr_values)
%                     curr_values = [curr_values{:}];
%                     all_curr_values = [all_curr_values; curr_values(:)];
%                 else
                    all_curr_values = [all_curr_values; curr_values(:)];
%                 end
            end
        end
        % only keep unique current values
        unique_curr_values = unique(all_curr_values);
        
        % only keep one NAN as current entry, remove all others
        try
            nan_inds = find(isnan(unique_curr_values)); % might fail for e.g. a cell
        catch
            nan_inds = [];
        end
        unique_curr_values(nan_inds(2:end)) = [];
        
        % create new fields an go through all fields AGAIN and check
        % whether the values exist or not
        for u_val_ind = 1:length(unique_curr_values)
            curr_u_val = unique_curr_values(u_val_ind);
            % get string representation
            if isnumeric(curr_u_val)
                curr_uval_str = num2str(curr_u_val);
            elseif iscellstr(curr_u_val)
                curr_uval_str = [curr_u_val{:}];
            else
                curr_uval_str = curr_u_val;
            end
            % replace potential . by _
            curr_uval_str = strrep(curr_uval_str, '.', '_');
            % replace potential - by n (e.g. from negative numbers)
            curr_uval_str = strrep(curr_uval_str, '-', 'n');
            
            % add fieldname
            curr_dummy_fieldname = [curr_subtree_entry curr_uval_str];
            
            % make sure fieldname is a valid matlab fieldname
            % remove äöü etc
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, 'ä', 'ae');
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, 'ü', 'ue');
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, 'ö', 'oe');
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, 'Ä', 'Ae');
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, 'Ü', 'Ue');
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, 'Ö', 'Oe');
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, 'ß', 'ss'); 
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, ')', ''); 
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, '\', '');
            curr_dummy_fieldname = strrep(curr_dummy_fieldname, '-', '');
            
            
            display(['  Creating dummy field ' curr_dummy_fieldname])
            
            for sess_ind = 1:length(data.Sess)
                for u_ind = 1:length(data.Sess(sess_ind).U)
                    curr_values = eval(['data.Sess(sess_ind).U(u_ind).factorial.' curr_subtree_entry]);

                    if iscellstr(curr_values)
                        for curr_val_ind = 1:length(curr_values)
                            % if a list is the current entry (in the
                            % current list): % count number of occurences
                            % (can be larger 0 .. length of list)
                            eval(['data.Sess(sess_ind).U(u_ind).' curr_dummy_fieldname '(curr_val_ind) = sum(strcmp(curr_values{curr_val_ind}, curr_u_val));']); % count number of occurences of the current unique value, if the current entry is a list of things (can be larger than 1)
                        end
                    elseif iscell(curr_values)
                        for curr_val_ind = 1:length(curr_values)
                            % if a list is the current entry (in the
                            % current list): % count number of occurences
                            % (can be larger 0 .. length of list)
                            eval(['data.Sess(sess_ind).U(u_ind).' curr_dummy_fieldname '(curr_val_ind) = sum(curr_values{curr_val_ind} == curr_u_val);']); % count number of occurences of the current unique value, if the current entry is a list of things (can be larger than 1)
                        end
                    else
                        for curr_val_ind = 1:length(curr_values)
                            if isnan(curr_u_val)
                                % == nan does not work, so we need to use
                                % isnan() instead
                                eval(['data.Sess(sess_ind).U(u_ind).' curr_dummy_fieldname '(curr_val_ind) = isnan(curr_values(curr_val_ind));']); % will either be 1 or 0
                            else
                                % check if current entry equals the current
                                % unique value
                                eval(['data.Sess(sess_ind).U(u_ind).' curr_dummy_fieldname '(curr_val_ind) = curr_values(curr_val_ind) == curr_u_val;']); % will either be 1 or 0
                            end
                        end
                    end
                end
            end
        end
    end
end