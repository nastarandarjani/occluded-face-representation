function [trl, event] = trialfun_(cfg)
% Written by Nastaran Darjani
% Developed in MATLAB R2017a
% see also: eeglab_to_fieldtrip
%

    hdr = ft_read_header(cfg.headerfile);
    event = ft_read_event(cfg.headerfile);

    EVsample   = [event.sample]';

    PreTrig   = round(0.2 * hdr.Fs);
    PostTrig  = round(0.6 * hdr.Fs);

    begsample = EVsample - PreTrig;
    endsample = EVsample + PostTrig;

    offset = -PreTrig*ones(size(endsample));
    
    trl = [begsample endsample offset ones(size(EVsample))];