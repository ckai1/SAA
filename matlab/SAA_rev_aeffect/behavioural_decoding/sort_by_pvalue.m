% function [class3, sorted_p, sort_ind] = sort_by_pvalue(class3, out_all_set)
%
% IN
%   class3: Names of class as cellstr or cell of cells containing the
%       trimmed names in out_all.decoding_measures_str
%   out_all_set.decoding_measures_str: cellstr with all decoding measures
%   out_all_set.allsubj_accuracies: n_subj x n_decodingstr matrix
% OUT
%   class3: orderd by one-sided ttest pvalues for each decodingstr in class3
%       (ttest mean > 0)
%   sorted_p: pvalues for each entry in sorted class3
%   sort_ind: new class3 = old class3(sort_ind)

function [class3, sorted_p, sort_ind] = sort_by_pvalue(class3, out_all_set)

%% trim measures (faster)
decoding_measures_str = strtrim(out_all_set.decoding_measures_str);

%% Get p-values for all these measures
% Find indices
class3_ind = zeros(size(class3));
for sdm_ind = 1:length(class3)
    % get indices (empty fields have been replaced by ' ' above;
    curr_ind = find(strcmp(decoding_measures_str, class3{sdm_ind}));
    if isempty(curr_ind)
        % check if starts with -- or ' ', if so ignore it
        if strncmp(class3{sdm_ind}, '--', 2) || strncmp(class3{sdm_ind}, ' ', 1)
            curr_ind = 0;
        else
            error('Cant find %s in class3. If you still want to add this as empty line, please implement it here', class3{sdm_ind});
        end
    elseif length(curr_ind) > 2
        error('Found %s in decoding_measures_str multiple times, this case is not caught here.', class3{sdm_ind})
    end
    class3_ind(sdm_ind) = curr_ind;
end

%% get p-values for those that are none-0
[H, p] = ttest(out_all_set.allsubj_accuracies(:, class3_ind(class3_ind~=0)), [], .05, 'right');
p(isnan(p)) = 0; % avoid nan problems
sort_ind = zeros(size(class3_ind));
sort_ind(class3_ind~=0) = p; % ps
% get sort indices for all values (0s will be first)
[sorted_p, sort_ind] = sort(sort_ind); % create indeces for sorting
class3 = class3(sort_ind); % Puh... done. Ugly. Works.