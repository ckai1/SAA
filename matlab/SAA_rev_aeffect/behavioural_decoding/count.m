% counts the number of columns, gives a warning if the data contains any
% nans

function c = count(curr_values)
    % get number of columns
    c = size(curr_values, 2);
    % throw a warning, if any value is nan
    if any(isnan(curr_values(:)))
        warning('The current values contain nans')
    end    
end