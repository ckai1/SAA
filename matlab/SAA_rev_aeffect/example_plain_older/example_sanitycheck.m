% function example_sanitycheck(data, subj, beh_cfg)
% Example function to perform a sanity check between the created data and
% the "true" data.
%
% IN
%   data.Sess(s_ind).U(u_ind). at least containing the following fields:
%       .name{1}: Name of the session
%       + all the measures you added
%   subj: number of the current subj, e.g. if you need it to load the
%       "true" data
%   beh_cfg: the beh_cfg with all the fields it has
%
% Kai, 2013-10-14

function example_sanitycheck(data, subj, beh_cfg)

%% load the "original" data that should be checked against the passed data

% in our case it's again the example dataset, but this time as a first 
% level design that we created there. In your case it could e.g. be the 
% SPM.mat file from your SPM first level analysis
original_data = example_data(subj, 'firstleveldesign');

%% check that number of sessions agrees
if length(original_data.Sess) ~= length(data.Sess)
    error('Sanity check failed: Number of sessions different between original data and passed data')
end

for sess_ind = 1:length(data.Sess)
    for u_ind = 1:length(data.Sess(sess_ind).U)
        % compare values again values from passed data 
        if ~isequal(data.Sess(sess_ind).U(u_ind).curr.onset(:), data.Sess(sess_ind).U(u_ind).curr.onset(:))
            error('Sess(%i).U(%i): Sanity check failed. Data is not equal to original data', sess_ind, u_ind)
        end
    end
end

display('Sanitycheck successful')