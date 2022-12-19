% Clear the workspace
close all;
clear;
sca;

% pararell port
ioObj = io64;
status = io64(ioObj);
address = hex2dec('0378');          %standard LPT1 output port address
data_out=0;                                 %sample data value
io64(ioObj,address,data_out);

Screen('Preference', 'SkipSyncTests', 0);
% Setup PTB with some default values
PsychDefaultSetup(2);

% Seed the random number generator. 
rng('shuffle');

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white * (101/256);
black = BlackIndex(screenNumber);

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], 32, 2,...
    [], [],  kPsychNeed32BPCFloat);

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set the text size
Screen('TextSize', window, 40);

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Here we load in an images from file.
dirlist = dir('images');

% Calculate the number of stimuli
numStimuli = length(dirlist) - 2;

stimuli = zeros(numStimuli, 1);
imageName = strings(numStimuli, 1);
for i = 3:length(dirlist)
    % get name of images
    imageName(i - 2) = dirlist(i).name;
    
    % read image
    theImageLocation = sprintf('images\\%s', imageName(i - 2));
    theImage = imread(theImageLocation);

    % Make the image into a texture
    stimuli(i - 2) = Screen('MakeTexture', window, theImage);
end

% Get the size of the image
[s1, s2, s3] = size(theImage);

% shuffle index of stimuli 15 times
index = repmat(1:numStimuli, 1, 15);
trialIndex = index(randperm(length(index)));
numTrials = length(trialIndex);

%----------------------------------------------------------------------
%                       Timing Information
%----------------------------------------------------------------------

% Presentation Time for the face images in seconds and frames
presTimeSecs = 0.25;
presTimeFrames = round(presTimeSecs / ifi);

% fixation time in seconds and frames
fixTimeSecs = 0.35;
fixTimeFrames = round(fixTimeSecs / ifi);

% Numer of frames to wait before re-drawing
waitframes = 1;

%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------

% Change the blend function to draw an antialiased fixation point
% in the centre of the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Get the size of the on screen window in pixels
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% hide cursor
HideCursor(window)

% In first trial we present a start screen and wait for a key-press
DrawFormattedText(window, 'Press Any Key To Begin', 'center', screenYpixels * 0.75, black);
DrawFormattedText(window, '+', 'center', 'center', black);
Screen('Flip', window);
KbStrokeWait;
   
% blink counter
blink = randi([7, 10]);

Priority(topPriorityLevel);
% Animation loop: we loop for the total number of trials
io64(ioObj,address, 100); % fixation
for trial = 1:20%numTrials    
    % Flip again to sync us to the vertical retrace at the same time as
    % drawing our fixation point
    DrawFormattedText(window, ' ', 'center', 'center', black);
    vbl = Screen('Flip', window);

    % Now we present the isi interval with fixation point minus one frame
    % because we presented the fixation point once already when getting a
    % time stamp
    for frame = 1:fixTimeFrames - 1
        % Draw the fixation point
        DrawFormattedText(window, ' ', 'center', 'center', black);

        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end

    io64(ioObj,address, 50); % stimuli

    % Now we draw the picture and the fixation point
    for frame = 1:presTimeFrames
        % Draw the image to the screen, unless otherwise specified PTB
        %  will draw the texture full size in the center of the screen.
        Screen('DrawTexture', window, stimuli(trialIndex(trial)), [], [], 0);

        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end

    blink = blink - 1;
    % blink every 10 trial
    if blink == 1
	io64(ioObj,address, 100); % fixation
    	for frame = 1:fixTimeFrames
        	% Draw the fixation point
	        DrawFormattedText(window, ' ', 'center', 'center', black);

	        % Flip to the screen
        	vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
	end

        io64(ioObj,address, 0); % blink
        DrawFormattedText(window, '+', 'center', 'center', black);
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        KbStrokeWait;
        
        blink = randi([7, 10]);
    end  

    % Flip to the screen
    vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    io64(ioObj,address, 100); % fixation
end
io64(ioObj,address, 0); % end
Priority(0);

imageseq = imageName(trialIndex);
save('imageSequence.mat', 'imageseq');

% Clean up
sca;