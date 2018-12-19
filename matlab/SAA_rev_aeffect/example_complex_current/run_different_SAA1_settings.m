substodo = 1;

cfg.mode = ''; % real data

cfg.use_summary = ''; % no summary, trialwise
cfg.cv_type = 'CV'
results{1} = TaskRest_SAA1_behavioural_decoding_MAIN(substodo, cfg)

cfg.cv_type = 'CV_xset_difficulty'
results{2} = TaskRest_SAA1_behavioural_decoding_MAIN(substodo, cfg)


cfg.use_summary = 'runwise';
cfg.cv_type = 'CV'
results{3} = TaskRest_SAA1_behavioural_decoding_MAIN(substodo, cfg)

cfg.cv_type = 'CV_xset_difficulty'
results{4} = TaskRest_SAA1_behavioural_decoding_MAIN(substodo, cfg)
