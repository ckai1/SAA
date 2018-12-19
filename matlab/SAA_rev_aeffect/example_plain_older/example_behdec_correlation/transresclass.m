% Classes for result transformations need to inherit from this abstract
% class
%
% See below which functions and properties need to be implemented, and
% which arguments they need to handle

classdef (Abstract) transresclass
    
    % Methods that need to be implemented
    methods (Abstract)
        % methods that need to be implemented
        output = apply(TOC, decoding_out, chancelevel, cfg, model)

        % return the name for this output
        outputname = char(TOC)
            
    end
    
end