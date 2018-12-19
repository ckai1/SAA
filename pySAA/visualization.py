"""
 Plotting API for SAA.
 Using bokeh, it produces interactive plots 
 of the decoding results of the SAA.
 author: Daniel Vargas
 supervisor: Kai Goergen
"""
import bokeh.palettes as plt
import numpy as np
import pandas as pd
from scipy.stats import ttest_ind as ttest

#from bokeh.embed import components
from bokeh.io import output_file, output_notebook, reset_output, save
from bokeh.layouts import column, row
from bokeh.models import BasicTicker, ColorBar, ColumnDataSource, LabelSet, LinearColorMapper 
from bokeh.plotting import figure, show

class Visualization:
    def __init__(self, accuracies, df, expected_df, output_name, **kwargs):
        """
        Render bokeh plots. right now a heatmap for the accuracies and a boxplot are plotted.
        Users can define new plots and append them to fit their needs.
        Input:  accuracies: numpy array with accuracies. shape: n_decoding_sets x n_subjects
                df: pandas DataFrame with the accuracies
                expected_df: pandas DataFrame with the expected values
                output_name: path to the file where the output figure will be saved
        """
        reset_output()
        output_file(output_name)
        self.accuracies = accuracies
        self.df = df
        self.expected_df = expected_df
        self.visualize(kwargs)
    
    def visualize(self, kwargs):
        """
        Render bokeh plots. right now a heatmap for the accuracies and a boxplot are plotted.
        Users can define new plots and append them to fit their needs.
        Input:  accuracies: numpy array with accuracies. shape: n_decoding_sets x n_subjects
                df: pandas DataFrame with the accuracies
                expected_df: pandas DataFrame with the expected values
        """
        p1 = self.heatmap(kwargs)
        p2, p_values_num = self.box_plot(kwargs)
        r1 = row(p1, p2, sizing_mode="fixed")
        # expected value plots
        results = dict(
            accuracies = pd.DataFrame(self.accuracies, index=kwargs["sets"], columns=kwargs["columns"]),
            p_values = pd.DataFrame(p_values_num, index=kwargs["sets"], columns=["p_values"])
        )
        if self.expected_df is not None:
            r2 = self.plot_expected(results)
            show(column(r1, r2))
        else:
            show(r1)


    def heatmap(self, params):
        """
        Plot a 2D array of accuracies as a heat map using bokeh.
        Input: 
                accuracies: numpy.array of dimensions n x m, n=number of decoding sets, m=number of subjects
                In params:
                columns: Iterable with labels for x axis, ideally it is a list of strings of subjects
                sets: Iterable with labels for y axis, ideally list of strings of each decoding set
        Returns:
                bokeh.figure object
        """
        #Get arguments
        accuracies, x_range, y_range = self.accuracies, params["columns"], params["sets"]
        # define color
        color_mapper = LinearColorMapper(palette="Greys256", low=accuracies.min(), high=accuracies.max())
        # List for hover tool
        TOOLTIPS = [("accuracy", "@image")]
        # initialise figure
        p = figure(plot_width=600, plot_height=400, x_range=x_range, y_range=y_range, tooltips=TOOLTIPS)
        p.xaxis.axis_label = "Subject id"
        p.yaxis.axis_label = "Decoding Variables"
        # plot image
        p.image(image=[accuracies], color_mapper=color_mapper, x=[0], y=[0], dw=[len(x_range)], dh=[len(y_range)])
        # plot color bar
        color_bar = ColorBar(color_mapper=color_mapper, ticker=BasicTicker(), location=(0,0))
        p.add_layout(color_bar, 'right')
        #show(p)
        # Embed plot into HTML via Flask Render
        # script, div = components(plot)
        return p

    def box_plot(self, params):
        """
        Show a box plot with bokeh from the information contained in df
        Input:
                In params:
                sets: Iterable with strings of each decoding set
        Returns:
                bokeh.figure object after running a 2nd level analysis
        """

        def get_quartiles(df):
            """
            Compute quartiles and mean from a DataFrame df
            """
            df = df.T
            q1   = df.quantile(q=0.25)
            q2   = df.quantile(q=0.50)
            q3   = df.quantile(q=0.75)

            iqr = q3 - q1
            upper = q3 + 1.5*iqr
            lower = q1 - 1.5*iqr

            qmin = df.quantile(q=0.00)
            qmax = df.quantile(q=1.00)

            upper.score = [min([x,y]) for (x,y) in zip(list(qmax),upper)]
            lower.score = [max([x,y]) for (x,y) in zip(list(qmin),lower)]
            mean = df.mean()
            return q1, q2, q3, qmin, qmax, upper, lower, mean

        def plot_boxes(p, sets, q1, q2, q3, p_values):
            """Plot boxes from plot box"""
            source1 = ColumnDataSource(data=dict(y=sets, right=q3, left=q2, p_values=p_values))
            source2 = ColumnDataSource(data=dict(y=sets, right=q2, left=q1, p_values=p_values))
            p.hbar('y', 0.1, 'right', 'left', fill_color="darkorchid", line_color="black", source=source1)
            p.hbar('y', 0.1, 'right', 'left', fill_color="darkcyan", line_color="black", source=source2)
            return p

        def plot_stems(p, upper, lower, q1, q2, q3, p_values):
            """Plot stems from box plot"""
            source1 = ColumnDataSource(data=dict(x0=upper, x1=q3, y=sets, p_values=p_values))
            source2 = ColumnDataSource(data=dict(x0=lower, x1=q1, y=sets, p_values=p_values))
            p.segment('x0', 'y', 'x1', 'y', source=source1, line_color="black")
            p.segment('x0', 'y', 'x1', 'y', source=source2, line_color="black")
            return p

        def plot_whiskers(p, upper, lower, p_values):
            """Plot whiskers from blox plot"""
            source1 = ColumnDataSource(data=dict(x=lower, y=sets, p_values=p_values))
            source2 = ColumnDataSource(data=dict(x=upper, y=sets, p_values=p_values))
            p.rect("x", "y", 0.01, 0.1, source=source1, line_color="black")
            p.rect("x", "y", 0.01, 0.1, source=source2, line_color="black")
            return p

        def plot_circles(p, n_subs, mean, sets, p_values_num):
            """Plot the mean of data as a circle (annulus)"""
            # circles
            if n_subs > 1:
                bonferroni_low  = 0.05 / len(sets)
                bonferroni_high = 1 - bonferroni_low
                intervals = (bonferroni_low, 0.05, 0.1, 0.9, 0.95, bonferroni_high)
                colors = ('red', 'black', 'black', 'grey', 'cyan', 'cyan', 'blue')
                txtmarker = ('**', '*', '^', '', '^', '*b', '**b')
                p_color = [colors[np.where(p <= intervals)[0][0]] for p in p_values_num]
                p_marker = [txtmarker[np.where(p <= intervals)[0][0]] for p in p_values_num]
                p_values = ["{0:0.3f}".format(p) for p in p_values_num]
                
            else:
                p_values = list(map(str, p_values_num))
            source = ColumnDataSource(data=dict(x=mean, y=sets, p_values=p_values, units_default=["screen"] * len(mean)))
            p.annulus("x", "y", 0.05, 0.3, source=source, fill_color="white", line_color="black")
            p.circle("x", "y", size=0., source=source, fill_color="red", line_color="black")
            # labels
            if n_subs > 1:
                p_values = list(map(lambda x, y: x+y, p_values, p_marker))
                source = ColumnDataSource(data=dict(x=mean, y=sets, p_values=p_values, color=p_color))
            else:
                source = ColumnDataSource(data=dict(x=mean, y=sets, p_values=p_values, color=['black']*len(sets)))
            labels = LabelSet(x='x', y='y', text='p_values', level='glyph', text_color="color", \
                              source=source, x_offset=1, y_offset=8, render_mode='canvas')
            p.add_layout(labels)
            return p

        # Get arguments
        df, sets = self.df, params["sets"]

        #Hover tool
        TOOLTIPS = [
            ("accuracy minus chance", "$x"),
            ("p_values", "@p_values")
        ]
        # Quartile information
        q1, q2, q3, qmin, qmax, upper, lower, mean = get_quartiles(df)
        # Compute t-test if there is more than one subject
        if len(df.T) > 1:
            t_statistic, p_values_num = ttest(df.T, np.zeros_like(df.T))
            p_values_num = np.nan_to_num(p_values_num)
            p_values = ["{0:0.3f}".format(p) for p in p_values_num]
        else:
            p_values_num = [float("nan")] * len(sets) 
            p_values = ["n/a"] * len(sets)
        p = figure(plot_width=600, plot_height=400, background_fill_color="#efefef", y_range=sets, tooltips=TOOLTIPS)

        # boxes
        p = plot_boxes(p, sets, q1, q2, q3, p_values)

        # stems
        p = plot_stems(p, upper.score, lower.score, q1, q2, q3, p_values)

        # whiskers
        p = plot_whiskers(p, upper.score, lower.score, p_values)
        # circles
        p = plot_circles(p, len(df.T), mean, sets, p_values_num)

        # grid
        p.xaxis.axis_label = "Accuracy minus chance"
        p.yaxis.axis_label = "Decoding variables"
        p.yaxis.major_label_text_font_size="8pt"
        p.ygrid.grid_line_color = None
        p.xgrid.grid_line_color = "white"
        p.grid.grid_line_width = 2

        return p, p_values_num

    def create_fig(self, data, expected_series, test_str):
        """
        Scatter plot of the data.get(test_str) and expected_series.
        Input:  data: dictionary of DataFrames of real data
                expected_series: DataSeries of expected values
                test_str: key of the data dictionary to select a dataframe

        """
        test = data.get(test_str)
        sizes = (15 + np.abs(test.T - expected_series)**1.5).T

        TOOLTIPS = [
                ("Decoding set", "@x"),
                (test_str, "@y"),
                ("expected", "@expected")
        ]

        p = figure(plot_width=600, plot_height=400, x_range=list(test.index), tooltips=TOOLTIPS)
        color = plt.viridis(len(test.T))
        for i, subj in enumerate(test):
            source=ColumnDataSource(data=dict(x=list(test.index),y=test[subj], size=sizes[subj], expected=expected_series))
            p.circle('x', 'y', legend = subj, color=color[i], source=source, size='size', alpha=0.75, \
                    muted_color=color[i], muted_alpha=0.2,)
        p.scatter('x', 'expected', source=source, color='red', marker='*', legend='expected_df',\
                 muted_color=color[i], muted_alpha=0.2, size=10)

        p.xaxis.axis_label = 'Decoding sets'
        p.yaxis.axis_label = test_str
        p.xaxis.major_label_orientation = np.pi/4
        p.legend.click_policy="mute"
        return p

    def plot_expected(self, results):
        """
        This function loops over the columns of expected_df to compare expected v. real values.
        Returns: bokeh row layout with one figure per data frame column.
        """
        plots = []
        for test_str in self.expected_df:
            p = self.create_fig(results, self.expected_df[test_str], test_str)
            plots.append(p)
        r = row(*plots, sizing_mode="fixed")
        return r