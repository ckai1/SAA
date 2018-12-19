%% function subfield_tree = get_subfield_tree(base)
% This function gets recursively the full subfield tree of a given struct,
% and returns is as cellstr
function subfield_tree = get_subfield_tree(base)

if ~isstruct(base)
    % nothing to do, return an emtpy string
    subfield_tree = [];
else
    subfield_tree = {};
    fns = fieldnames(base);
    for fn_ind = 1:length(fns)
        curr_fn = fns{fn_ind};
        curr_subfieldtree = get_subfield_tree(base.(curr_fn));
        if isempty(curr_subfieldtree)
            % just add the current name
            subfield_tree{end+1} = curr_fn;
        else
            for subfn_ind = 1:length(curr_subfieldtree)
                subfield_tree{end+1} = [curr_fn '.' curr_subfieldtree{subfn_ind}];
            end
        end
    end
end