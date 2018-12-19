% function data = add_summary_measures(data, subfields, measures)
%
% This function is useful to setup behavioural decodings, in which we want
% to get one summary measure (e.g. the mean, the variance, ...) for
% different trials of a condition in each run/session.
%
% The function calculates summary measures for each session for provided 
% fields (subfields) for provided measures (measures) of a SPM struct.
%
% Two important measure functions for this class are:
%   COUNT.m: Counts the number of columns (ignoring whether they contain
%       nans)
%   NANCOUNT.m: Counts the number of columns that do not contain nans
%
% An example of how to use this function is at the end of this help.
%
% IN
%   data: Standard SPM format, having the data in 
%       data.Sess(sess_ind).U(condition_ind)
% OPTIONAL
%   subfields: cellstr with fields of data.Sess(sess_ind).U(condition_ind)
%       that contain fields that should be summarized. Default: {'curr', 
%       'prev'}
%   measures: cell with functions that should be applied to the data.
%       Default: {@nancount, @nanmean, @nanvar, @nansum}
% OUT 
%   The output will be added to
% 
% data.Sess(1).U(1).(NAME OF MEASURE)
%
% EXAMPLE
% Data contains a number of sessions and conditions, that look like this:
%
% >> data.Sess(1).U(1)
% 
% ans = 
% 
%          name: {'R1-S1'}
%      trial_nr: [3 9 12 18 25]
%          curr: [1x1 struct]
%          prev: [1x1 struct]
%
% Within .curr, we e.g. have
% 
% data.Sess(1).U(1).curr
% 
% ans = 
% 
%            RT: [593 555 614 977 791]
%        cue_on: [18.0450 71.6410 97.3930 153.1230 211.3930]
%
% If we now apply the function, we get new fields nanmean, nanvar, nansum
%
% data.Sess(1).U(1)
% 
% ans = 
% 
%          name: {'R1-S1'}
%      trial_nr: [3 9 12 18 25]
%          curr: [1x1 struct]
%          prev: [1x1 struct]
%       nanmean: [1x1 struct]
%        nanvar: [1x1 struct]
%        nansum: [1x1 struct]
% 
% that contain the respective calculations inside:
% >> data.Sess(1).U(1).nanmean.curr
% 
% ans = 
% 
%     n_buttons: 1
%            RT: 706
%       correct: 1
%        cue_on: 110.3190
%
% Author: Kai, v2013-09-30

function data = add_summary_measures(data, subfields, measures)

%% defaults
if ~exist('subfields', 'var')
    display('Argument "subfield" not provided, using default values as displayed below')
    subfields = {'curr', 'prev'}
end

if isempty(subfields)
    error('No entries provided for argument "subfields". This function does not work on "data" directly, but only on subfields. Please provide the data in subfields, e.g. subfields = {''.curr'', ''.prev''} for data in data.curr and data.prev')
end

% convert subfields to single element cellstr, if it was provided as char
if ischar(subfields)
    subfields = cellstr(subfields);
end

if ~exist('measures', 'var') || isempty(measures)
    display('Argument "measures" not provided, using default values as displayed below')
    measures = {@nancount, @nanmean}; % potential other measures: @nanvar, @nansum
end

% create string representation
measure_str = cellfun(@func2str, measures, 'UniformOutput',false);

%% do it
display(['Adding: ' sprintf('%s ', measure_str{:}), ' for subfields: ' sprintf('%s ', subfields{:})])

for sess_ind = 1:length(data.Sess)

    for u_ind = 1:length(data.Sess(sess_ind).U)
        curr_U = data.Sess(sess_ind).U(u_ind);

        for sf_ind = 1:length(subfields)
            curr_subfield = subfields{sf_ind};
            % check if this subfield exists at all
            if ~isfield(curr_U, curr_subfield)
                error('add_summary_measures:subfield_not_existing', 'Subfield %s does not exist in session 1, condition 1, skip creating summary measure. By default, .curr and .prev are expected. If you like to use other subfields, pass them as second argument', curr_subfield);
            end
                
            
            sub_subfields = fieldnames(curr_U.(curr_subfield));
            for sub_sf_ind = 1:length(sub_subfields)
                curr_subsubfield = sub_subfields{sub_sf_ind};
                curr_values = curr_U.(curr_subfield).(curr_subsubfield);
                for m_ind = 1:length(measures)
                    try
                        curr_func = measures{m_ind};
                        % get the current target value
                        if isequal(@nanvar, curr_func) || isequal(@nanstd, curr_func)
                            % dimension argument is 3rd
                            curr_targetval = curr_func(curr_values, [], 2);
                        else
                            % dimension argument is 2nd
                            curr_targetval = curr_func(curr_values, 2);
                        end
                    catch            
                        curr_targetval = 'Error when calculating value';
                    end
                    % add to data
                    curr_U.(func2str(curr_func)).(curr_subfield).(curr_subsubfield) = curr_targetval;
                end
            end
            new_U(u_ind) = curr_U;
        end        
    end
    data.Sess(sess_ind).U = new_U;
    clear new_U;
end
end % END MAIN