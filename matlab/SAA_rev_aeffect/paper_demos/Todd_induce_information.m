% Potential caveats:
%
% Maybe we need to center regressors before regression??
% Question: Does center RT regressor help? (or all)
%   Answer: This ONLY "helps" for ONE specific case X below (works with 
%           rand and randn):
%       X: with_zeros = 0; RT_regressor_centred = 1; zscore_all_regressors = 0; zscore_data = 0; with_constant_regressor = 0; noise = rand
%  Alternative: Add Contant regressor
%       Carsten A believes it's the same as centering regressors
%   Answer: adding constant doesnt change anything
%       For the case X above it does not work, because of rank deficiencies
% Question: does removing 0 periods change anything
%   Answer: Most of the time it changes quite a lot, with 0 I could find no
%       case in which a RoNI did not induce information, without I found 1!
%
% Question: The betas in the current version are not always in the 
%   range [-1 1]. Is this because 
%       a) dependece of regressors
%       b) calculation of betas is wrong
%       c) anything else
%   and d) does it matter?
%
% Kai, 2015-09-30

%% Define basics
% Condition   A       B       A       V
with_zeros = 1;
RT_regressor_centred = 1; % only centres RT regressor, if not zscoring on below
zscore_all_regressors = 0; % done directly before each analysis (constant regressor is not zscored, guess why)
zscore_data = 0; % done directly before each analysis
% constant regressor only works if with_zeros = 1! otherwise rank deficiency
with_constant_regressor = 0; % 1: adds a  constant regressor, should center all regressors. DOES NOT WIRH WITH ZERO = 1 (rank deficiency)
noise = 'rand'; % randn, rand

if with_zeros
    Neuro = [0 0  1  0 0  1  0 0  1  0 0  1 ];
    Reg_A = [0 0  1  0 0  0  0 0  1  0 0  0 ];
    Reg_B = [0 0  0  0 0  1  0 0  0  0 0  1 ];
    %     Reg_RT= [0 0 1.5 0 0 0.5 0 0 1.5 0 0 0.5];
    Reg_RT= [0 0 1 0 0 2 0 0 1 0 0 2];
    if RT_regressor_centred
        % center RT regressor
        Reg_RT = zscore(Reg_RT);
    end
    
    if with_constant_regressor
        Reg_const = ones(size(Reg_RT)); % Constant regressor: does not seem to change something, needs minimal code changes below (search: beta & Reg_const)
    end
else % no zeros
    % same effect, but cant be used with constant if A & B are as they are
    % (because A & B trivially add up exactly to constant)
    Neuro = [ 1   1   1   1   1   1];
    Reg_A = [ 1   0   1   0   1   0];
    Reg_B = [ 0   1   0   1   0   1];
    % Reg_RT= [1.5 0.5 1.5 0.5];
    if RT_regressor_centred
         Reg_RT= [-1   1  -1   1  -1   1]; %centred 
    else
        Reg_RT= [ 1   2   1   2   1   2]; % not centered: 
    end
    if with_constant_regressor
       Reg_const = ones(size(Reg_RT)); % Constant regressor: does not seem to change something, needs minimal code changes below (search: beta & Reg_const)
    end
end
    

figure('name', 'Todd example', 'Position', [126          46        1099        1107])

c = subplot(6, 2, 1:2);

Neuro_plus_RT = 0; % Decide: Neurodata without effect (=0) and Neurodata with RT effect (=1)
if Neuro_plus_RT % does not really do what it should yet
    Neuro = Neuro + Reg_RT; % add RT to Neuro (idea is to remove RT contribution from Neuro, should result in no difference between betas and hopefully no systematic decoding
    if with_constant_regressor
        d = uitable('Data', [Neuro; Reg_A; Reg_B; Reg_RT; Reg_const], 'RowName', {'Neuro + RT + eps', 'Reg_A', 'Reg_B', 'Reg_RT + eps', 'Reg_const', ['eps=.1*' noise]});
    else
        d = uitable('Data', [Neuro; Reg_A; Reg_B; Reg_RT], 'RowName', {['Neuro + RT + eps (eps=.1*' noise ')'], 'Reg_A', 'Reg_B', 'Reg_RT + eps (Reg right col only)'}); % , 'eps=.1*randn'});
    end
else
    if with_constant_regressor
        d = uitable('Data', [Neuro; Reg_A; Reg_B; Reg_RT; Reg_const], 'RowName', {'Neuro + eps', 'Reg_A', 'Reg_B', 'Reg_RT + eps', 'Reg_const', ['eps=.1*' noise]});
    else
        d = uitable('Data', [Neuro; Reg_A; Reg_B; Reg_RT], 'RowName', {['Neuro + eps (eps=.1*' noise ')'], 'Reg_A', 'Reg_B', 'Reg_RT + eps (R right col only)'}); % , 'eps=.1*randn'}); 
    end
end

colwidth(1:length(Neuro)) = {35};
set(d, 'ColumnWidth', colwidth);
set(d, 'Unit', 'normalized');
set(d, 'Position', get(c, 'Position').*[1 .98 1 1.1]); % slighlty larger than subplot to fit possible extra row
set(d, 'FontSize', 7); % only changes data font size, not headers...
axis off

title_str = 'Example: Effect of Regressors of no Interest - Design & regressors (single run)';
if zscore_all_regressors
    title_str = [title_str ' zscoring regressors'];
end
if zscore_data
    title_str = [title_str ' zscoring data'];
end
title(title_str)

%%
for with_RT = 0:1

    %% Do simulation, with and without regressor
    diff_beta_A_vs_B = nan(10000, 1);
    RT_string = [];
    if with_RT
        RT_string = ' with RT regressor';
        if with_constant_regressor
            beta = nan(1000, 4);
            RT_string = [RT_string ' & constant'];
        else
            beta = nan(1000, 3);
        end
    else
        RT_string = ' no RT regressor';
        if with_constant_regressor
            beta = nan(1000, 3);
            RT_string = [RT_string ' & constant'];
        else
            beta = nan(1000, 2);
        end
    end
    
    if RT_regressor_centred
        RT_string = [RT_string ' RT regressor centred']
    end

    for rep = 1:10000
        if mod(rep, 1000) == 0
            rep
        end
        % add small noise to Neuro and RT

        % change all neurodata
        % add gaussian noise
        if strcmp(noise, 'randn')
            Neuro_Eps = Neuro + randn(size(Neuro)) *.1;
            if rep == 1
                RT_string = [RT_string ' randn'];
            end
        elseif strcmp(noise, 'rand')
            % add uniform noise (non-overlapping)
            Neuro_Eps = Neuro + rand(size(Neuro)) *.1;
            if rep == 1
                RT_string = [RT_string ' rand'];
            end
        else
            error('Unkown noise %s', noise)
        end


        % change only RT ~=0
        if with_RT
            Reg_RT_Eps = Reg_RT;
            Reg_RT_Eps(Reg_RT~=0)= Reg_RT(Reg_RT~=0) + randn(size(Reg_RT(Reg_RT~=0)))*.1;
        end

        % zscore if specified
        if zscore_all_regressors
            Reg_A = zscore(Reg_A);
            Reg_B = zscore(Reg_B);
            if with_RT
                Reg_RT_Eps = zscore(Reg_RT_Eps);
            end
%             if with_constant_regressor % zscoring the constant regressor
%             makes no sense, this one is left were it is
%                 Reg_const = zscore(Reg_const);
%             end
        end
        if zscore_data
            Neuro_Eps = zscore(Neuro_Eps);
        end
                
        
        % calculate beta
        if with_RT
            if with_constant_regressor
                beta(rep, :) = Neuro_Eps / [Reg_A; Reg_B; Reg_RT_Eps; Reg_const];
            else
                beta(rep, :) = Neuro_Eps / [Reg_A; Reg_B; Reg_RT_Eps];
            end
        else
            if with_constant_regressor
                beta(rep, :) = Neuro_Eps / [Reg_A; Reg_B; Reg_const];
            else
                beta(rep, :) = Neuro_Eps / [Reg_A; Reg_B];
            end
        end
    end

    diff_beta_A_vs_B = beta(:, 1) - beta(:, 2);

    subplot(6, 2, 3+with_RT)
    ksdensity(diff_beta_A_vs_B)
    mean_diff = mean(diff_beta_A_vs_B)
    sem_diff = std(diff_beta_A_vs_B)/sqrt(length(diff_beta_A_vs_B))
    disp('Average 0 for classical test -- what about decoding?')
    title({'ksdensity for betaA - betaB', RT_string, sprintf('m=%f, SEM=%f', mean_diff, sem_diff)})

    %% Plot A vs B directly
    subplot(6, 2, 5+with_RT)
    try
        % plot cool 2d histogram (saves file size and shows more info)
        opt.scatter = 0;
        plot_cool_hist3([beta(:, 1), beta(:, 2)], '', opt);
        % ignore 0 (+ very small entries)
        cm = colormap;
        cm(1, :) = [1 1 1];
        colormap(cm)
    catch
        warning('plotting cool histogram failed, using normal plot. This increases the filesize of eps and fig files')
        plot(beta(:, 1), beta(:, 2), '.')
    end
    
    xlabel('betaA')
    ylabel('betaB')
    axis equal
    xlim([min(beta(:)), max(beta(:))])
    ylim([min(beta(:)), max(beta(:))])
    
    %% Decoding

    % add libsvm
    if ispc
        addpath('C:\tdt\decoding_toolbox_v3.04\decoding_software\libsvm3.17\matlab')
    else
        addpath('/Users/kai/Documents/!Projekte/tm03/OLD_TOOLBOX/decodingtoolbox-code_old/decoding_betaversion/decoding_software/libsvm3.12/matlab/')
    end
    if isempty(which('svmtrain'))
        error('Please add libsvm to path')
    end
    labels_train = [-1*ones(5,1); ones(5,1)];
    labels_test = [-1; 1];

    ind_train = ~eye(6);

    acc = nan(10000, 1);
    all_p_1 = nan(10000, 1); % stores number of patterns predicted as -1
    all_p_m1 = nan(10000, 1); % stores number of patterns predicted as -1
    d_set_diff_AB = nan(10000, 1); % stores mean difference between betas in each random set (to compare same data with CV)
    
    for rep = 1:10000
        if mod(rep, 1000) == 0
            rep
        end
        % randomly draw 6 indeces and get betas for A and 6 for B from above,
        % then do CV on these
        ind = ceil(rand(6, 1)*length(beta));
        if ind == 0, ind = 1; end; % just in cas
        A = beta(ind, 1);
        B = beta(ind, 2);

        % calculate mean difference of this dataset
        d_set_diff_AB(rep) = mean(A-B);
        
        % do cv
        for cv = 1:6
            data_train = [A( ind_train(:, cv)); B( ind_train(:, cv))];
            data_test =  [A(~ind_train(:, cv)); B(~ind_train(:, cv))];

            % train
            model = svmtrain(labels_train, data_train, '-s 0 -t 0 -c 1 -b 0 -q');
            % test
            [pred_labels, curr_acc, decision_values] = svmpredict(labels_test, data_test, model, '-q'); % libsvm BUG resolved: some versions of svmpredict return no result, if only 2 arguments are returned, so decision_values needs to be returned here
            
            cv_accs(cv) = curr_acc(1);
            p_1(cv) = sum(pred_labels==1);
            p_m1(cv) = sum(pred_labels==-1);
        end
        acc(rep) = mean(cv_accs);
        all_p_1(rep) = sum(p_1);
        all_p_m1(rep) = sum(p_m1);
    end

    % plot CV
    subplot(6, 2, 9+with_RT)
    [n, x] = hist(acc, unique(acc));
    try
        bar(x, n, 'hist', 'b');
    catch
        bar(x, n, 'b'); % unkown error, no idea why it sometimes occurs, somtimes not
    end
        
    % add existing unique values to baseline
    hold on
    plot(unique(acc), zeros(size(unique(acc))), 'rx');
    mean_acc = mean(acc)
    sem_acc = std(acc)/sqrt(length(acc))
    title({'Histogram of accuracies for 6-fold leave-one-pair-out CV on betas for A and B', RT_string, sprintf('m=%f, SEM=%f', mean_acc, sem_acc)})

    % save for end
    if with_RT
        acc_withRT = acc;
    else
        acc_noRT = acc;
    end
    
    sum_p_1 = sum(all_p_1)
    sum_p_m1 = sum(all_p_m1)
    xlabel(sprintf('Decoding Accuracy (%%); Total count predicted as -1: %i, as +1: %i', sum_p_m1, sum_p_1))
    xlim([-5 105]);
    
    
    % plot conventional diff
    subplot(6, 2, 7+with_RT)
    ksdensity(d_set_diff_AB)
    mean_diff_set = mean(d_set_diff_AB)
    sem_diff_set = std(d_set_diff_AB)/sqrt(length(d_set_diff_AB))
    title({'ksdensity for 6x(betaA - betaB)', RT_string, sprintf('m=%f, SEM=%f', mean_diff_set, sem_diff_set)})
    
end

% Plot difference between with and without RT
subplot(7, 4, 26:27)
hold off
[h_acc_withRT, X] = hist(acc_withRT, unique([acc_withRT, acc_noRT]));
h_acc_noRT = hist(acc_noRT, unique([acc_withRT, acc_noRT]));
h_diff_acc = h_acc_withRT-h_acc_noRT;
try
    bar(X, h_diff_acc, 'hist', 'b');
catch
    bar(X, h_diff_acc, 'b'); % unkown error, no idea why it sometimes occurs, sometimes not
end
% add existing unique values to baseline
hold on
plot(X, zeros(size(X)), 'rx');
% mean_diff_acc = mean(diff_acc);
% sem_diff_acc = std(diff_acc)/sqrt(length(diff_acc));
title({'Histogram of accuracy differences (withRT-noRT) from above'})
xlim([-5 105])

display('All done')
display('If added TDT, you can use: save_fig(''Todd_induce_information figure/ToddExample_induce_confound_XX'')')

% Try to save figure (we probably save all paramters in figure, too)
str = ['with_zeros = ' num2str(with_zeros) '; ' ...
       'RT_regressor_centred = ' num2str(RT_regressor_centred) '; ' ...
        'zscore_all_regressors = ' num2str(zscore_all_regressors) '; ' ...
        'zscore_data = ' num2str(zscore_data) '; ' ...
        'with_constant_regressor = ' num2str(with_constant_regressor) '; ' ...;
        'noise = ' noise];
% add parameters to figure
text(-.5, -.5, {str, datestr(now)}, 'Interpreter', 'none', 'Units', 'normalized')

% generate file name
short_str = strrep(str, ' ', '');
short_str = strrep(short_str, '=', '_');
short_str = strrep(short_str, ';', '_');
cfg.plot_design_formats = {'-dpng'}; % ingore eps, getting too large, too
save_fig(['ToddExample_induce_confound_' short_str], cfg)