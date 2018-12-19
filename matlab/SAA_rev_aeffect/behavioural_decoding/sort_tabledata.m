function sorteddata = sort_tabledata(tabledata, classes)

% Function to quickly sort tabledata structure into sortedU structure.
% This only works for very easy sorting, i.e. only when all classes are
% present in one field (which at the moment must be .name)
%
% Hint: If you have a more complex sorting, simply create one new field
% that has the class labels, and then call it name... ;)
%
% IN
%   tabledata: Data in table form. 
%       Example:
%           tabledata.Sess(s_ind).name{1, n_samples data}: Condition of 
%               current sample
%           tabledata.Sess(s_ind).(anyname): [n_dim, n_samples data]
%   classes: Classes that the field .name should be sorted into, 
%       e.g. {'A', 'B'}
%
% OUT
%   sorted Sess.U struct (similar to SPM)
%
% SEE ALSO: bede_convert_sortedU_to_trial.m, bede_convert_table_to_trial.m,
%   sort_tabledata.m

sorteddata = [];

for sess_ind = 1:length(tabledata.Sess)
    for class_ind = 1:length(classes)
        % create U for current condition
        curr_U = [];
        
        % set name of current condition
        curr_condition = classes(class_ind);
        
        % get trial numbers of current trials
        curr_U.trialnr = find(strcmp(tabledata.Sess(sess_ind).name, curr_condition));
        
        % get all data from all other fields that have the same length as
        % name
        
        subfields = get_subfield_tree(tabledata.Sess(sess_ind));
        
        for field_ind = 1:length(subfields)
            % get data of current subfield (can also be a sub.subfield etc,
            % that's why we need eval)
            curr_subfield = subfields{field_ind};
            curr_data = eval(['tabledata.Sess(sess_ind).' curr_subfield]);
            % save only data of current trials to output
            if size(curr_data, 2) == size(tabledata.Sess(sess_ind).name, 2)
                % again we can have sub.subfields, thats why we need eval again
                eval(['curr_U.' curr_subfield ' = curr_data(:, curr_U.trialnr);']);
            else
                warning('sort_tabledata:wrong_number_of_entries', 'Field %s has a different number of entries than .name, thus it will not be added to sorteddata', curr_subfield);
            end
        end
        
        % as sanity check, make sure that all data in .name is exactly as
        % the condition, and then only keep the first entry here
        if ~all(strcmp(curr_U.name, curr_condition))
            error('Not all condition names are as the sorting criterion, something went wrong with sorting into classes. Please check')
        else
            % all fine, only keep the first entry
            curr_U.name = curr_U.name(1);
        end
       
        % put into session matrix
        sorteddata.Sess(sess_ind).U(class_ind) = curr_U;
    end
end