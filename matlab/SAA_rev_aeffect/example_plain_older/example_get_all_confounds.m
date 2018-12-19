% function data = example_get_all_confounds(data, subj, beh_cfg)
%
% Extract potential confounds from the trials numbers in data.Sess.U.
%
% IN
%   data: struct containing trial numbers and names for each codition in
%       data.Sess(sess_ind).U(u_ind) as fields
%       data.Sess(sess_ind).U(u_ind).name{1}: name of condition
%       data.Sess(sess_ind).U(u_ind).trialnr: numbers of current trial
%   subj: subj nr, in case it's needed (e.g. to load data)
%   beh_cfg: cfg struct, in case it's needed (e.g. to load data)
%
% OUT
%   data: augmented input by behavioural & design data as subfields of 
%       data.Sess(sess_ind).U(u_ind), that contain k (number of patterns) 
%       elements for the same class, e.g.
%
%           data.Sess(1).U(1).curr.RT = [1.4 3.0 2.7 2.0]
%
%       for 4 different examples. In general, each field contains d x k
%       examples (with d the dimension, see next).
%
% DATA TYPES and MULTI-DIMENSIONAL DATA
%   Some covarites might be multidimensional or have other types. You can
%   put these in data.Sess as follows:
%
%   HIGH(er) D:
%     data.Sess(1).U(1).curr.cue1(:, trial_ind) = [1; 3; 6]
%       i.e. cue1 needs to be a d x k matrix (d: dimension of each pattern, k: number of patterns)
%    
%   Datatypes:
%       Numerics: work
%       Single letters: should work, too, especially if you use dummy coding 
%           (see factorial variables below)
%       Other types are rather experimental, so they are not included here.
%       In general, I would highly recommend to simply recode other
%       variables before using them as data. This should avoid 
%       interpretation and analysis problems.
%   
%
% ADDITIONAL INFOS
%   FACTORIAL VARIABLES
%   all subfields of .factorial can be expanded using dummy variables using 
%       data = create_dummies(data);
%   Example:
%       data.Sess(1).U(1).factorial.curr.cue = [7 7 9 9]
%       data = create_dummies(data)
%   leads to
%       data.Sess(1).U(1).curr.cue7 = [1 1 0 0]
%       data.Sess(1).U(1).curr.cue9 = [0 0 1 1]
%
%   AUTOMATIC SUMMARY MEASURES
%   count, mean, var, etc of each session can be automatically added for all 
%   fields  using
%       data = add_summary_measures(data);
%
% Author: Kai, v2013-10-14

% potential additional confounds (just a random list):
%
% .curr & .prev
%   absolute timing (probably pretty hard to find out)
%   alternatively: timing in terms of images (for this, we need to know how
%   long each session is)
%
% .prev
%   relative time: timing relative to current event, e.g. minus current cue
%   onset

function data = example_get_all_confounds(data,  subj, beh_cfg)
%% 
display(sprintf('Getting potential confounds for subj %i', subj))

%% load design & behavioural data 

% in our example, everything is neatly organized in example_data
% you will most likely need to load different files. Put the information
% you need in beh_cfg.
input_data = example_data(subj);

%% all sessions, all conditions, all trials
for sess_ind = 1:length(data.Sess)
    for cond_ind = 1:length(data.Sess(sess_ind).U)
        ntrials = length(data.Sess(sess_ind).U(cond_ind).trialnr);
        display(sprintf('Sess(%i).U(%i).name{1}=''%s'': Adding data for %i trials', sess_ind, cond_ind, data.Sess(sess_ind).U(cond_ind).name{1}, ntrials))
        
        % go through all trials of current cell
        for trial_ind = 1:ntrials
            %% Map all the data you like from the input data to data.Sess
            
            % This part will probably become a long list in the end, but
            % therefore you can use it for as many decoding analyses as you
            % like.
            
            % gut trial nr
            % get current trial number
            % get number of current trial
            % warning! USE trial_ind and curr_trialnr INVERTED BELOW (to access the trial data)
            curr_trialnr = data.Sess(sess_ind).U(cond_ind).trialnr(trial_ind);
            % get current trial data
            curr_trial_data = input_data.Sess(sess_ind).trial(curr_trialnr);
            
            
            %% !!! USE as sorted_data...(trial_ind) = log...(curr_trialnr) !!!
            % (to access the trial data) e.g.
            %   data.Sess(sess_ind).U(cond_ind).measure(trial_ind) = log.measure(curr_trialnr)
            
            %% behaviour: current RT
            data.Sess(sess_ind).U(cond_ind).curr.RT(trial_ind) = curr_trial_data.RT; 
            % design: current cue ind (marked as factorial by U().factorial.)
            data.Sess(sess_ind).U(cond_ind).factorial.curr.cue(trial_ind) = curr_trial_data.cue;
            
            % example for MULTI-DIMENSIONAL data (e.g. two cue images)
            % this can only works if ALL examples have the same number of 
            % dimensions (for lists, consider factorial dummy coding)
            % data.Sess(sess_ind).U(cond_ind).factorial.curr.cue(:, trial_ind) = curr_trial_data.cue;
            
            % also get onsets (for sanity check, but can also be used to
            % find e.g. temporal confounds)
            data.Sess(sess_ind).U(cond_ind).curr.onset(trial_ind) = curr_trial_data.onset;
            
            
            %% PREVIOUS trial
            prev_trial_nr = curr_trialnr - 1;
            
            % again: USE indices inverted below (to access the trial data), e.g. 
%             data.Sess(sess_ind).U(cond_ind).prev.measure(trial_ind) = log.measure(prev_trial_nr)
            
            if prev_trial_nr > 0 % 
                % get previous trial data
                prev_trial_data = input_data.Sess(sess_ind).trial(prev_trial_nr);
                
                % behaviour: current RT
                data.Sess(sess_ind).U(cond_ind).prev.RT(trial_ind) = prev_trial_data.RT; 
                % design: current cue ind (marked as factorial by U().factorial.)
                data.Sess(sess_ind).U(cond_ind).factorial.prev.cue(trial_ind) = prev_trial_data.cue;
            else
                % think about what you want to do if the previous trial
                % does not exist. Doing nothing here can lead to problems
                % in later, so better go through the hazzle ones.
                
                % behaviour: current RT
                data.Sess(sess_ind).U(cond_ind).prev.RT(trial_ind) = nan; 
                % design: current cue ind (marked as factorial by U().fact )
                data.Sess(sess_ind).U(cond_ind).factorial.prev.cue(trial_ind) = 0; % not existing cue number
            end

            % and all the other data you like
            
            
            %% end all sessions, all conditions, all trials
        end        
    end
end