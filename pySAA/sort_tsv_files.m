function data = sort_tsv_files(paths, previous_on)
% This function parses a set of tsv files into a structure of the form
% subject(subj_ind).Sess(sess_ind).U(u_ind).SAAdata(data_ind)
% IN: paths - is a cell array which rows are the paths to the sessions for
%             a specific subject
%     previous_on - Boolean that indicates whether previous values of the
%                   variables would be included as new fields

for i=1:length(paths)
    subjects(i) = sort_subject(paths{i}, previous_on);
end
data.subjects = subjects;
end % end of function
%%
function subject = sort_subject(paths, previous_on)
% wrapper function that loops over subject tsv file paths
for i=1:length(paths)
    Sess(i) = sort_session(paths{i}, previous_on);
end
subject.Sess = Sess;
end % end of function

%%
function curr_Sess = sort_session(path, previous_on)
% This function does the actual scanning of folders and parsing of tsv
% files into a structure.

source = tdfread(path, '\t');
fields = fieldnames(source);
for field_idx=1:length(fields)
   field = fields{field_idx};
   if ischar(source.(field))
       source.(field) = cellstr(source.(field));
   end
   if isnumeric(source.(field))
       source.(field) = num2cell(source.(field));
   end
end

if previous_on
    source = add_previous(source);
end

fid = fopen(path, 'r', 'n', 'ISO-8859-1');
%read column names
header = textscan(fid, repmat('%s',1, length(fields), 1), 1);
header = [header{:}];
fclose(fid);
conditions = sort(unique(source.name));

%group variables by condition
fields = fieldnames(source);
curr_Sess = [];
for cond_idx=1:length(conditions)
    cond = conditions{cond_idx};
    %get indices where the condition was presented
    trialnr = find(strcmp(source.name, cond));
    %assign values to structure
    curr_Sess.U(cond_idx).name = cond;
    curr_Sess.U(cond_idx).indices = trialnr;
    for field_idx=1:length(fields)
        %store name of variable and its content
        variable = fields{field_idx};
        data_points = source.(fields{field_idx})(trialnr);
        curr_Sess.U(cond_idx).SAAdata(field_idx).variable = {variable};
        curr_Sess.U(cond_idx).SAAdata(field_idx).data_points = data_points;
    end
    curr_Sess.U(cond_idx).SAAdata(end + 1).variable = {'indices'};
    curr_Sess.U(cond_idx).SAAdata(end).data_points = num2cell(trialnr);
end
end