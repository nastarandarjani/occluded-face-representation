function eeglab_prepocess(i)
% eeglab_prepocess reads merged EEG data according to subject number 
% (input argument: i).
% At first, it removes reference channels (A1, A2) and cancels effect of
% reference A2 over all channels.
% Then, imports data to eeglab and selects events based on last channel
% (127) value.
% After that, channel locations imported from location_xyz.txt file.
% Preprocessing applied to signals (SEE BELOW) and the dataset save in 
% mvpa_preprocessing folder.
% 
% Preprocessing described as followed: 
%   1. Re-reference data to average
%   2. High-pass filter of 1 Hz to cancel drifts
%   3. Low-pass filter with 100 Hz cut-off
%   4. Re-reference data to average (again)
%
% Written by Nastaran Darjani 
% Developed in MATLAB R2017a
%

sub = ['sub', num2str(i)];

data = load(['../data/merged/', sub, '.mat']);
data = data.data;
trigger = data(129, :);
data = data - data(63, :);
data(63:64, :) = [];
data(127, :) = trigger;

eeglab
EEG.etc.eeglabvers = '2021.1';
% import data
EEG = pop_importdata('dataformat','array','nbchan',0,'data',data, ...
    'setname',sub,'srate',1200,'subject',num2str(i),'pnts',0,'xmin',0);
EEG = eeg_checkset( EEG );

% import data event
EEG = pop_chanevent(EEG, 127,'edge','leading','edgelen',0);
EEG = eeg_checkset( EEG );

% import channel locations
EEG=pop_chanedit(EEG, 'load', ...
    {'/home/nastaran/Desktop/codes/location_xyz.txt', ...
    'filetype','xyz'});
EEG = eeg_checkset( EEG );

% re-reference to average
EEG = pop_reref( EEG, [] );
EEG = eeg_checkset( EEG );

% high pass filter
EEG = pop_eegfiltnew(EEG, 1, []);
EEG = eeg_checkset( EEG );

% low pass filter
EEG = pop_eegfiltnew(EEG, [], 100);
EEG = eeg_checkset( EEG );

% re-reference to average
EEG = pop_reref( EEG, [] );
EEG = eeg_checkset( EEG );

% % downsample
% EEG = pop_resample(EEG, 250);
% EEG = eeg_checkset(EEG);

% save dataset
EEG = pop_saveset( EEG, 'filename',[sub, '.set'],'filepath', ...
    '/home/nastaran/Desktop/data/preprocessed/mvpa_preprocessing/');
EEG = eeg_checkset( EEG );
end
