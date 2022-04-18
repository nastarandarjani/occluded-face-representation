function data = eeglab_to_fieldtrip(subject)
%
% eeglab_to_fieldtrip imports .set file (created by eeglab) of input 
% argument (subject) to fieldtrip.
% Trials obtained based on trialfun_ function (SEE BELOW). Also, baseline 
% removal and average re-referencing is applied to the dataset.
%
% trialfun_ function: epoch signal based on trigger into [-0.2, 0.6] trials.
%
% Written by Nastaran Darjani 
% Developed in MATLAB R2017a
%
% see also: trialfun_

    % epoching
    cfg = [];
    cfg.dataset = ['../data/preprocessed/mvpa_preprocessing/', subject, ...
        '.set'];
    cfg.trialfun = 'trialfun_';
    cfg = ft_definetrial(cfg);
    
    % remove baseline
    cfg.demean          = 'yes';
    cfg.baselinewindow  = [-0.2 0];
    
    % re-reference to average
    cfg.reref = 'yes';
    cfg.refchannel = 'all';
    
    data = ft_preprocessing(cfg);
    
    save(['../data/preprocessed/mvpa_preprocessing/', subject, '.mat'],...
        '-v7.3');
end