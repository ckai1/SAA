% function c = nancount(curr_values, dim)
%
% counts the number of columns, in which no nan occurs
%
% By default, nancount will count along the 2nd dimension.
% THIS DIMENSION IS DIFFERENT FROM E.G MEAN, etc.

function c = nancount(curr_values, dim)
    % default for dimension: 2
    if ~exist('dim', 'var')
        dim = 2;
    end
    % get number of columns, for which no value is nan
    c = size(curr_values, dim);
    % subtract the number of colums in which a nan occurs
    c = c - sum(any(isnan(curr_values), 1)); % any(x, 1) ensures that any works along columns
end
