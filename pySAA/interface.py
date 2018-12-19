"""
 Interface for the generalizes implementation of the SAA framework.
 Using the MALTAB API it coordinates SAA decoding modules.
 author: Daniel Vargas
 supervisor: Kai Goergen
"""
# coding: utf-8

import argparse
import numpy as np
import matlab.engine
import os
import pandas as pd
import scipy.io as sio

class SAA_Interface:
    def __init__(self):
        # parse arguments
        parser = argparse.ArgumentParser()
        parser.add_argument("cfg_file", help="JSON file with the configuration information")
        parser.add_argument("--no_plot", help="Do not produce HTML output figure", action="store_true")
        parser.add_argument("--no_matlab", help="Do not use MATLAB", action="store_true")
        parser.add_argument("--n_subjects", help="Number of subjects to use. Works only if --no_matlab is used.")
        parser.add_argument("--n_sessions", help="Number of sessions to use. Works only if --no_matlab is used.")
        args = parser.parse_args()
        
        self.cfg_file = args.cfg_file
        self.no_plot = args.no_plot
        self.no_matlab = args.no_matlab
        if not self.no_matlab:
            self.eng = self._start_matlab()
        else:
            self.n_subs = args.n_subjects
            self.n_sess = args.n_sessions

    def _start_matlab(self):   
        """ Start matlab engine"""
        print("Starting loading MATLAB engine")
        eng = matlab.engine.start_matlab()
        print("Finished loading MATLAB engine")
        return eng

    def load_cfg_json(self):
        """Load cfg file (via MATLAB)"""
        print("Starting loading cfg file")
        # path to the configuration file
        self.cfg_file = os.path.abspath(self.cfg_file)
        # MATLAB function that reorganizes the content of the JSON into a structure to be used in latter stages
        cfg_mat = self.eng.read_cfg_json(self.cfg_file)
        # Load the saved structure
        cfg_content = sio.loadmat(cfg_mat, struct_as_record=False, squeeze_me=True)
        print("Finished loading cfg file")
        self.cfg_mat, self.cfg_content = cfg_mat, cfg_content

    def prepare_data(self):
        """Parsing of data to a more convenient format (via MATLAB)"""
        print("Starting preparing data")
        self.eng.prepare_data(self.cfg_mat, nargout=0)
        print("Finished preparing data")

    def decode_data(self):
        """"Decoding process (via MATLAB)"""
        print("Starting decoding")
        accuracies = np.asarray(self.eng.extract_and_decode(self.cfg_mat))
        print("Finished decoding")
        self.accuracies = accuracies

    def _concatenate_set(self, analysis):
        """Concatenate columns of non null pandas Data Series"""
        return ' '.join(filter(lambda x: not pd.isnull(x), analysis))

    def post_process(self):
        """
        Creates DataFrame from result and lists of subjects and decoding sets
        returns:
            df: DataFrame with the accuracies
            expected_df: DataFrame with the expected values
            columns: list with generated subject names
            sets: list with strings corresponding to each decoding set
            output_html: path to the file where the output figure will be displayed.
        """
        # load file with the sets of decoding variables
        analyses = pd.read_csv(self.cfg_content['decoding_sets_file'], sep='\t', header=-1).T
        # load file with the expected_values
        expected_file = self.cfg_content.get('expected_values')
        expected_df = pd.read_csv(expected_file, sep='\t', index_col=0) if expected_file else None
        # Save subject ids as strings
        columns = ['sub-{0:02d}'.format(i) for i in range(1, 1 + len(self.accuracies.T))]
        # Save the decoding variables
        sets = [self._concatenate_set(analyses[i]) for i, a in enumerate(analyses)]

        # Save as a data frame, it is more convenient for the box plot
        df = pd.DataFrame(self.accuracies, index=sets, columns=columns)

        # Save results in a tsv
        output_name, _ = os.path.splitext(self.cfg_content['output_result'])
        output_tsv = os.path.join(output_name + '.tsv')
        output_html = os.path.join(output_name + '.html')
        df.to_csv(output_tsv, sep='\t', index=True, header=False)
        print("******")
        print(self.cfg_content)
        
        return df, expected_df, columns, sets, output_html
    
    def visualize(self, df, expected_df, output_html, columns, sets):
        """Plots using bokeh if flag --no_plot was unset"""
        if not self.no_plot:    
            import visualization
            vis = visualization.Visualization(self.accuracies, df, expected_df,\
                                    output_html, columns=columns, sets=sets)

        print("SAA Finished successfully")
       
    def simple_example(self):
        """Execute a python based analysis using a minimal setup"""
        import simple_example
        accuracies, df, sets, columns = simple_example.run(self.cfg_file, self.n_subs, self.n_sess)
        self.accuracies = accuracies.T
        self.visualize(df, expected_df=None, output_html='output/result_simple.html', columns=columns, sets=sets)


if __name__ == '__main__':

    # create object that will manage processes
    saa = SAA_Interface()
    
    if saa.no_matlab:
        import simple_example
        saa.simple_example()
    else:
        # Load JSON file
        saa.load_cfg_json()

        # Prepare data
        saa.prepare_data()

        # Decode data and save it as a numpy array
        saa.decode_data()

        # Post-processing to plot
        df, expected_df, columns, sets, output_html = saa.post_process()

        # Plot
        saa.visualize(df, expected_df, output_html, columns, sets)

        #Quit MATLAB process
        saa.eng.quit()
