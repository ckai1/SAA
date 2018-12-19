classdef transresclass_output_similarity < transresclass
    
    properties
        correlation_target_values = []; % individual values for the type
        correlate_against_method = 'accuracy_minus_chance'; % method name for transres method
        granularity = 'setwise'; % define which degree of granularity should be used, decoding_values only work with 'all'
        similarity_measure = 'correlation'; % input to pdist, correlation default. See there for arguments
    end
        
    methods
        % init
        function TOC = transresclass_output_similarity(correlation_target_values)
            TOC.correlation_target_values = correlation_target_values;
        end
        
        % the do function (first argument - the current instance - is not
        % in the parameterlist when calling)
        function output = apply(TOC, decoding_out, chancelevel, cfg, model)
            
            % get data for current measurement
            if strcmp(TOC.granularity, 'setwise')
                if strcmp(TOC.correlate_against_method, 'decision_values')
                    error('decision_values only work with transresclass_output_similarity.granularity = ''all''')
                end
                
                unique_sets = unique(cfg.design.set);
                % check if the design has the correct number of sets
                if length(unique_sets) ~= length(TOC.correlation_target_values)
                    error('Different number of sets in cfg.design.set and in correlation_target_values, aborting')
                % check if the current data in decoding_out has the same number
                elseif length(decoding_out) ~= length(TOC.correlation_target_values)
                    warningv('correlation:target_data_unequal_length', 'Correlation target and current data have different length. Returning nan and continuing. This might be because the function is called to calculate sets.')
                    output = nan;
                    return
                else
                    % everything seems ok, get data to compare to
                    correlate_against = nan(size(unique_sets));
                    for set_ind = 1:length(unique_sets)
                        curr_set_filter = cfg.design.set == unique_sets(set_ind);
                        correlate_against(set_ind) = decoding_transform_results(TOC.correlate_against_method, decoding_out(curr_set_filter), chancelevel, cfg, model);
                    end
                end

            % add more granularity methods here
            elseif strcmp(TOC.granularity, 'all')
                
                if ~strcmp(TOC.correlate_against_method, 'decision_values')
                    error('transresclass_output_similarity.granularity = ''all'' has not yet been tested for anything but granularity ''decision_values''')
                end

                % get all values
                decoding_values = [];
                for set_ind = 1:length(decoding_out)
                    decoding_values = [decoding_values; decoding_out(set_ind).decision_values];
                end
                correlate_against = decoding_values; % add all decision values to one list
                
            % add more granularity methods here
            elseif strcmp(TOC.granularity, 'all')                
                % new granularity method (i.e. how to get the data)
                
            else
                error('Granularity %s not implemented yet',  TOC.granularity)
            end

            
            if length(correlate_against) ~= length(TOC.correlation_target_values)
                warningv('correlation:target_data_unequal_length', 'Correlation target and current data have different length. Returning nan and continuing. This might be because the function is called to calculate sets.')
                output = nan;
                return
                end
            
            if strcmp(TOC.similarity_measure, 'correlation')
            % check if all data or target values are equal
               if all(correlate_against(1) == correlate_against) 
                    disp(correlate_against)
                    warningv('correlation:data_completely_equal', 'All entries of the data are equal, this will result in nan')
                elseif all(TOC.correlation_target_values(1) == TOC.correlation_target_values)
                    disp(TOC.correlation_target_values)
                    error('correlation:target_completely_equal', 'All entries of the correlation target are equal, will ALWAYS result in nans, thus aborting. Please care about the target before starting')
                end
            end


            % calculate distance
            output = pdist([correlate_against(:)'; TOC.correlation_target_values(:)'], TOC.similarity_measure);
            
            if numel(output) > 1
                error('Output should not have more than 1 element')
            end
            
            if isempty(output)
                error('Output should not be empty')
            end
            
        end
        
        function output_name = char(TOC)
            output_name = sprintf('Similarity_%s_%s_%s', TOC.similarity_measure, TOC.correlate_against_method, TOC.granularity);
        end
    end
    
end