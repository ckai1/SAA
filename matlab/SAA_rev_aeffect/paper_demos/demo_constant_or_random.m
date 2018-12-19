% add libsvm
if ispc
    addpath('C:\tdt\decoding_toolbox_v3.04\decoding_software\libsvm3.17\matlab')
else
    addpath('/Users/kai/Documents/!Projekte/tm03/OLD_TOOLBOX/decodingtoolbox-code_old/decoding_betaversion/decoding_software/libsvm3.12/matlab/')
end
if isempty(which('svmtrain'))
    error('Please add libsvm to path')
end

%% start
modus = 'randn'; %'randn' or 'const'

rep = 10000 % number of replications

n1 = 10; % number of class -1 (first class). Libsvm will assign points to this class, if it cant decide (tiny bias for this class)
n2 = 5; % number of class 1 (second class)

acc = nan(rep, 1);

for ind = 1:rep
    label_train = [-ones(n1,1); ones(n2,1)];
    label_test = [-ones(n1,1); ones(n2,1)];
    
    %& training data
    if strcmp(modus, 'const')
         trainvec = [ones(n1,1); ones(n2,1)];
         testvec  = [ones(n1,1); ones(n2,1)];
    elseif strcmp(modus, 'randn')
        trainvec = [randn(n1,1); randn(n2,1)];
        testvec  = [randn(n1,1); randn(n2,1)];
    else
        error('Unkown modus')
    end
    

    
    model = svmtrain(label_train, trainvec, '-s 0 -t 0 -c 1 -b 0 -q');
    [pred_labels, curr_acc] = svmpredict(label_test, testvec, model, '-q');
    acc(ind) = curr_acc(1);
end

unique_acc = unique(acc);
if length(unique_acc) == 1
    % all elements have the same value
    n = length(acc);
    x = unique_acc;
else
    [n, x] = hist(acc, unique_acc);
end
%%
% display
[x'; n]
bar(x, n, 'hist')
set(gca, 'XTick', x)
title([modus sprintf('#-1: %i, #1: %i, nrep: %i', n1, n2, rep)])
mean_acc = mean(acc)
sem_acc = std(acc)/sqrt(length(acc))