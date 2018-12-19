% function data = addcolumns(data, func, colname, ncols)
%
% This function is an example of a user defined function, which is useful
% to add new SAA variables to the data to be analysed. of this help.
%
% IN
%   data: struct with the format
%       data.subjects(sub_ind).Sess(sess_ind).U(condition_ind)
%
%   func: function handler that creates an array of data
%
%   colname: char array that specifies the name the new variable will have
% OPTIONAL
%   ncols: to have more than 1 column created with the same structure

% OUT 
%   data structure 
% 
% data.Sess(1).U(1).SAAvariables(1).variable = colname001
% data.Sess(1).U(1).SAAvariables(1).data_points = {x1 x2 x3.. xn}
function data = addcolumns(data, func, colname, ncols)
    if ~exist('ncols', 'var'), ncols = 1; end
    for coln=1:ncols
        for sub=1:length(data.subjects)
            for sess=1:length(data.subjects(sub).Sess)
                for u=1:length(data.subjects(sub).Sess(sess).U)
                    entries = num2cell(func(length(data.subjects(sub).Sess(sess).U(u).SAAdata(1).data_points), 1));
                    name = sprintf('%s%03i',colname, coln);
                    data.subjects(sub).Sess(sess).U(u).SAAdata(end + 1).variable = name;
                    data.subjects(sub).Sess(sess).U(u).SAAdata(end).data_points = entries;
                end
            end
        end
    end

end % end of function