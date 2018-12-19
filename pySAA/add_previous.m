function data = add_previous(data)
 % This function duplicates the existing columns with the data points
 % shifted to the previous trial.
 fields = fieldnames(data);
 for field_idx=1:length(fields)
     field = fields{field_idx};
     data.(['prev_' field]) = [{'n/a'}; data.(field)(1:end-1)];
 end
end % end of function