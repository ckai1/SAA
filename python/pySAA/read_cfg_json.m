function cfg_mat_file = read_cfg_json(fname)
% wrapper function to parse_json
% It saves the output of this function on a mat file
    beh_cfg = parse_json(fname);
    cfg_mat_file = beh_cfg.cfg_mat_file;
    save(cfg_mat_file, '-struct', 'beh_cfg');
end %end of fucntion

function beh_cfg = parse_json(fname)
% script that reads a JSON file with the configuration information
% from the experiment pipeline, and places that information into a
% structure to be used in the course of the SAA flow.
%
% IN
%   fname: Path to the JSON file
%       Example of this file:
%       {
%        "field1": {"value": "field1_value, "type": "object"},
%        "field2": {"value": "field2_value, "type": "function"},
%        "field3": {"value": "field3_value, "type": "other"},
%    	}
%
%   The type determines if it is an object to be evaluated by matlab, a
%   function handler to be assigned, or other type p value that should be
%   assigned to the field.
%
% OUT
%   cfg structure
%

fid = fopen(fullfile(fname)); 
raw = fread(fid,inf); 
fclose(fid);

cfg = jsondecode(char(raw'));
beh_cfg = [];
beh_cfg.functions = [];
% decode json to a configuration object
fields = fieldnames(cfg);
% scan fields to apply functions and get object values
for field_ind=1:length(fields)
    field = fields{field_ind};
    switch cfg.(field).type
        case 'object'
           new_value = eval(cfg.(field).value);
           beh_cfg.(field) = new_value;
        case 'function'
            if ~isempty(cfg.(field).value)
                new_value = eval(['@'  cfg.(field).value]);
                beh_cfg.functions(end + 1).func = new_value;
                if isfield(cfg.(field), 'args')
                    beh_cfg.functions(end).args = eval([cfg.(field).args]);
                end
            end
        otherwise
            beh_cfg.(field) = cfg.(field).value;
    end
end
end % end of function