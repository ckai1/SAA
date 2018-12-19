Please follow explanations in example_behavioural_decoding_MAIN.m on how to adapt the example
files for you.


Most likely, only these files need to be adapted (follow comments in _MAIN.m for a nice order)

  - example_behavioural_decoding_MAIN.m
    Main calling function that processes all individual subjects and summarizes the results

  - example_behavioural_decoding_individual.m
    Processes individual subjects

  - example_get_all_confounds.m
    Gets data you want sorted by labels in standard format

  - example_standard_decoding_measures.m
    Define once what you which measures (variable names) you want to decode.
    Each {x} contains one group of variables, can be more than one.


This file makes sense to adapt
  - example_sanitycheck.m
    Sanity checks that are done on the way. Makes sense.


Other files
  - example_data.m
    File that generates example data in different format for example purpose only.
    You wont need it. You have your own real data.

