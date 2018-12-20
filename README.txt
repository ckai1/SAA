===================
VERSION INFORMATION
===================

Please note: This version of the SAA toolbox is work in progress. 
It has undergone only little testing and especially the documentation is in a 
very early stage.

Of course you are welcome to use what is there, but we suggest  to contact us
(e.g. create a new issue) if you like to use it.

========
CONTENTS
========

1. GENERAL
2. HOW TO CITE
3. FUNCTIONALITY OF THE SOFTWARE
4. INSTALLING THE PACKAGE

==========
1. GENERAL
==========
The use of novel statistical analysis methods, often employing complex data 
analysis pipelines (e.g. in the area of neuroimaging), has raised the question
how to validate if a given set of experimental design and statistical analysis
pipeline allows the expected statistical inference.
The Same Analysis Approach (SAA; Goergen et. al 2018 [neuroimage]) 
is a framework that tests experimental variables and simulated data
preserving the properties of the data analysis in order to achieve this.

Please report any bugs to https://github.com/ckai1/SAA/issues

==============
2. HOW TO CITE
==============

If you used the toolbox or any parts of it, the best favor you can do us 
is to cite it. Please use the following reference:

Goergen, K., Hebart, M. N., Allefeld, C., & Haynes, J.-D. (2018).
The Same Analysis Approach: Practical protection against the pitfalls of 
novel neuroimaging analysis methods. NeuroImage, 180, 19–30. 
https://doi.org/10.1016/j.neuroimage.2017.12.083

================================
3. FUNCTIONALITY OF THE SOFTWARE
================================

Typically, in brain image analyses you would like to know whether some 
regional brain activity pattern is significantly activated. In brain 
image classification you are searching for significant information about 
the classified samples.
As input, you typically have a number of brain images belonging to several 
categories which you would like to classify. As output you get for each 
subject one or several classification volumes (for searchlight analyses) 
or individual values (e.g. mean cross-validation accuracy in ROIs). In a 
second step the statistical significance can be tested easily using your 
brain image analysis toolbox (e.g. second-level analysis in SPM) or simple 
statistics (e.g. a one-sample t-test in Matlab). For simplicity, we set 
chance to 0 as a default and set all other values around 0 (i.e. for 2 
classes and chance level of 50%, values range from -50 to 50). You can 
of course also use the statistics utilities provided by the toolbox.

=========================
4. INSTALLING THE PACKAGE
=========================

1. Download the folder pySAA.
	1a. If you like to run the matlab example, install TDT (Hebart, Goergen,
		et al, see: bccn-berlin.de/tdt)

2. Prepare your data according to the specifications.

3. With a command line change to the pySAA folder.

4. Run the file interface.py with the selected options.
	[More extensive documentation will soon/might already be in the repository]
