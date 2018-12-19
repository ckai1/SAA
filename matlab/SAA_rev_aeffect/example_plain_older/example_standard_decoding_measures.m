function decoding_measures = example_standard_decoding_measures()

% This function simply returns some standard decoding measures as list of
% cell strings (and lists of cell strings for groups).
%
% If you only want to use one measure, you can pass it as simple string (or
% as regular expression), e.g. 'nanmean.curr.RT'. 
%
% If you want to use multiple ones, add it as a cell inside the cell, e.g.
% 
% EXAMPLE:
% decoding_measures = {
%       'nancount.curr.RT_first';                               % count (if you use a summary measure)
%       'nanmean.curr.RT';                                      % use (the nanmean of the current) RT
%       'regexp:^nanmean.curr.cue[0-9]*$';                      % use any cue field with a number (good for factorial variables that contain numbers)
%       {'nanmean.curr.RT'; 'regexp:^nanmean.curr.cue[0-9]*$'}; % use both fields
%  }


decoding_measures = {
    'nancount.curr.RT';     % DEFINITIVELY include the number of datapoints used (if you use summary measures like the mean)
    'nanmean.curr.RT';      % Example for nanmean string
    'regexp:^nanmean.curr.cue[0-9]*$'; % Example for regular expression
    {
        'regexp:^nanmean.curr.cue[0-9]*$'; 'nanmean.curr.RT';
    };  % Example for a group                    
};