function example_addpaths()
% check that behavioural_decoding is in path
if isempty(which('behavioural_decoding_batch'))
    if exist('../behavioural_decoding/behavioural_decoding_batch.m', 'file')
        addpath('../behavioural_decoding')
    else
        error('Please add behavioural decoding')
    end
end

% check that TDT is in path
if isempty(which('decoding_defaults'))
    error('decoding_defaults.m (TDT Decoding Toolbox) not found in path, please add')
end

% check that SPM is in path
if isempty(which('spm'))
    error('SPM.m (SPM) not found in path, please add')
end