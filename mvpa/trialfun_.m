function [trl, event] = trialfun_(cfg)
% Written by Nastaran Darjani
% Developed in MATLAB R2017a
% see also: eeglab_to_fieldtrip
%
    event = cfg.event(~strcmp({cfg.event.value}, 'boundary'));
    
    EVsample = [event.sample]';

    PreTrig = round(0.2 * cfg.hdr.Fs);
    PostTrig = round(0.6 * cfg.hdr.Fs);

    begsample = EVsample - PreTrig;
    endsample = EVsample + PostTrig;

    offset = -PreTrig*ones(size(endsample));
    
    trl = [begsample endsample offset ones(size(EVsample))];