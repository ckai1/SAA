# coding: utf-8

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from sklearn.model_selection import cross_val_score
from sklearn.model_selection import LeaveOneGroupOut
from sklearn import svm

clf = svm.SVC(kernel='linear', C=1)
logo = LeaveOneGroupOut()



def plot_cv_indices(cv, X, y, group, n_splits, lw=10):
    """Create a sample plot for indices of a cross-validation object."""
    fig, ax = plt.subplots()
    # Generate the training/testing visualizations for each CV split
    for ii, (tr, tt) in enumerate(cv.split(X=X, y=y, groups=group)):
        # Fill in indices with the training/test groups
        indices = np.array([np.nan] * len(X))
        indices[tt] = 1
        indices[tr] = 0

        # Visualize the results
        ax.scatter(range(len(indices)), [ii + .5] * len(indices),
                   c=indices, marker='s',
                   vmin=-.2, vmax=1.2, s=2000)

    # Plot the data classes and groups at the end
    ax.scatter(range(len(X)), [ii + 1.5] * len(X),
               c=y, marker='s', s=2000)

    ax.scatter(range(len(X)), [ii + 2.5] * len(X),
               c=group, marker='s', s=2000)

    
    # Formatting
    yticklabels = list(range(n_splits)) + ['class', 'group']
    ax.set(yticks=np.arange(n_splits+2) + .5, yticklabels=yticklabels,
           xlabel='Sample index', ylabel="CV iteration",
           ylim=[n_splits+2.2, -.2], )
    ax.set_title('{}'.format(type(cv).__name__), fontsize=15)
    plt.show()
    return ax

def subject2DataFrame(files):
    """
    Transform the files that correspond to a subject data into a DataFrame
    """
    dframes = []
    for i, file in enumerate(files):
        df = pd.read_csv(file, sep='\t', index_col=False)
        df['sess_ind'] = [i + 1] * len(df.index)
        df['rand_n'] = np.random.random(len(df.index))
        # The preparation of data should take place here:
        #    Expansion of ordinals, replace defaults, apply functions
        dframes.append(df)
    return pd.concat(dframes).sort_values('name')
    

def process_subject(general_file, sub_ind, sessions, cv, plot_cv=False):
    """
    Main loop over subjects. Their information is parsed and decoded.
    """
    path = os.path.join(general_file, "sourcedata", "sub-{0:02d}", "ses-{1:02d}", "fmri", "data.tsv")
    
    # Instead of having a general file, here the script should loop over the BIDS folder
    files = [path.format(sub_ind, sess_ind) for sess_ind in sessions]
    result = subject2DataFrame(files)
    groups = result.sess_ind
    labels = result.name
    scores = []
    # Instead of looping over the variables that we have what could be done is to read
    # the decoding sets from a separate file
    for field in result:
        data = np.array([result[field]]).T
        score = np.mean(cross_val_score(clf, data, labels, cv=cv, groups=groups))
        scores.append(score)
   
    # Plot cross_validation design if requested: this should come from argument or config file
    if plot_cv:
        plot_cv_indices(cv, result, labels, groups, n_splits=len(sessions))
    return scores, list(result)

def simple_process(general_file, substodo, sessions, cv):
    """
    Initiate a simple decoding that requires no MATLAB.
    """
    accuracies = []
    columns = ['sub-{0:02d}'.format(i) for i in range(1, 1 + len(substodo))]
    for sub_ind in substodo:
        scores_subject, sets = process_subject(general_file, sub_ind, sessions, cv)
        accuracies.append(scores_subject)
    return 100 * np.array(accuracies).T, columns, sets

def run(general_file, n_subs, n_sess):
    """
    Wrapper function for the decoding process.
    """
    substodo, sessions = range(1, int(n_subs) + 1), range(1, int(n_sess) + 1)
    accuracy_arr, sets, columns = simple_process(general_file, substodo, sessions, logo)
    df = pd.DataFrame(accuracy_arr, index=columns, columns=sets)
    return accuracy_arr.T, df, columns , sets
