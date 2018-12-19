% function trialdata = bede_convert_sortedU_to_trial(sortedUdata)
%
% Converts sortedU data into trialdata (of course, only the trials that are
% in the Sess.U can be assigned.
% REMARK: No idea what happens with unassigned trials at the moment.
%
% SEE ALSO: bede_convert_sortedU_to_trial.m, bede_convert_table_to_trial.m,
%   sort_tabledata.m

function trialdata = bede_convert_sortedU_to_trial(sortedUdata)

%% precheck

% make sure sortedUdata has a Sess && Sess.U subfield

if ~isfield(sortedUdata, 'Sess')
    error('sortedUdata has no .Sess subfield as expected')
end

if ~isfield(sortedUdata.Sess(1), 'U')
    error('sortedUdata.Sess has no .U subfield as expected')
end

%% convert
n_sess = length(sortedUdata.Sess);

for sess_ind = 1:n_sess
    
    curr_sessU = sortedUdata.Sess(sess_ind);
    curr_sessTrial = [];
    
    for u_ind = 1:length(curr_sessU.U)
        subfields = get_subfield_tree(curr_sessU.U(u_ind));
        
        % get current trial number & remove from subfields
        if ~isfield(curr_sessU.U(u_ind), 'trialnr')
            error('Sess(%i).U(%i) does has no subfield .trialnr, aborting', sess_ind, u_ind);
        end
        trialnr = curr_sessU.U(u_ind).trialnr;
        subfields = subfields(~strcmp(subfields, 'trialnr'));
        
        % get current name & remove from subfields
        if ~isfield(curr_sessU.U(u_ind), 'name')
            error('Sess(%i).U(%i) does has no subfield .name, aborting', sess_ind, u_ind);
        end
        curr_name = curr_sessU.U(u_ind).name;
        subfields = subfields(~strcmp(subfields, 'name'));
        
        % copy info of remaining subfields, if they have the same length as
        % trialnr (warning if not)
        for curr_trialnr_ind = 1:length(trialnr)
            curr_trialnr = trialnr(curr_trialnr_ind);
            curr_trial_data = [];
            curr_trial_data.curr_trialnr = curr_trialnr;
            curr_trial_data.name = curr_name;
            
            for field_ind = 1:length(subfields)
                curr_field = subfields{field_ind};
                curr_data = eval(['curr_sessU.U(u_ind).' curr_field]);
                
                if length(curr_data) == length(trialnr)
                    % only take data from the current position in U
                    eval(['curr_trial_data.' curr_field ' = curr_data(curr_trialnr_ind)'])
                else
                    warning(sprintf('Skipping Sess(%i).U(%i).%s because it has not the same number of entries (%i) as trialnr (%i)', sess_ind, u_ind, curr_field, length(curr_data), length(trialnr)))
                end
            end
            
            curr_sessTrial.trial(curr_trialnr) = curr_trial_data;
        end
        
    end
    
    trialdata.Sess(sess_ind) = curr_sessTrial;
end