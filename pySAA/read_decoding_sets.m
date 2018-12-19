function decoding_sets = read_decoding_sets(beh_cfg)
% This script reads a tsv file specified in the beh_cfg.decoding_sets_file
% that has the information of which variables will be used as decoding
% measures. The rows of this tsv should have in each cell the name of the
% variable to be used, or a regular expression that could match one or more
% variables.
% IN: beh_cfg struct loaded from a JSON file.
% OUT: decoding sets cell array where each element is a decoding set of
%      variables. Example:
%      {{'name, 'trialnr'}, {'regexp:^r'}, {'accuracy'}}
%
fid = fopen(beh_cfg.decoding_sets_file, 'r', 'n', 'ISO-8859-1');
decoding_sets = {};
while true
    % read until EOF
   line = fgetl(fid);
   if line == -1
       fclose(fid);
       break;
   end
   % separate by tabs and remove empty values
   line = strsplit(line, '\t');
   line = line(~cellfun(@isempty, line));
   decoding_sets{end + 1} = line;
end
end % end of function