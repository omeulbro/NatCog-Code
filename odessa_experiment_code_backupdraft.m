function main()
%Odessa's experiment!
%Code involves:
    %Code to segment a video using the space bar
    %Only counts a space bar press if it is not within the past 500 ms to
    %the previous space bar press
    % Demo video that loops if the participant doesn't press the space bar
    % a certain amount of times 
    %Main trial where 6 videos are played
    %Randomization code to randomize which videos are played (from
    %randomization matrices that are in the generate_genres_matrices.m
    %file)
    %Code to segment each of the videos played using the space bar that is
    %stored in a file called merged_events.txt
    %Code to record a free recall of all stimuli after all of the 6 videos
    %have been played
    %Code to record cued recall of all stimuli by presenting the title of
    %each video then recording a response
    %Code to take participants to a google chrome page with a qualtrics
    %survey that assesses their experience with theatre and film

%Event segmentation is adapted from Niki's movie_reaction.m code
%Audio recording is adapted from Claire's code

    % Set preferences and file paths
    Screen('Preference', 'SkipSyncTests', 1); % Skip sync tests for smoother operation
    demo_filepath = 'C:\Users\dessa\Demo Video Hilda.mov';

    % Define key names
    KbName('UnifyKeyNames');
    esc = KbName('ESCAPE');
    space = KbName('space');
    f = KbName('f');

    %Hide cursor
    HideCursor;
    % Initialize variables
    playing_movie = 1;


    %Establishing a counter to determine the number of participants run
    counting_file = 'counter.txt'; %make a file to store the number of participants
    if exist(counting_file, 'file') %checking if the file exists at all
        fileName = fopen(counting_file, 'r'); 
        counter = fscanf(fileName, '%d'); %checking if the counter number is in the file yet
        fclose(fileName);
    else
        counter = 0; %if there is no line with the number of participants, make it 0
    end
    counter = counter + 1; %every time this experiment is run, the counter will go up once
    fprintf('Number of participants run: %d\n', counter);

    fileName = fopen(counting_file, 'w');
    fprintf(fileName, '%d', counter); %print the updated number of the counter into the file
    fclose(fileName);
    

    %Part 1: The Demo
    %Bare bones version of Niki's code
    try
        AssertOpenGL;
        % Open window
        %Keep this window open for the entirety of the experiment! We will
        %just be flipping it from here on out to flush it
        background = [128, 128, 128];
        screen = max(Screen('Screens'));
        win = Screen('OpenWindow', screen, background);
        Screen('TextSize', win, 50);
        Screen('TextFont', win, 'Arial');

        % Display initial instruction text
        instruction_text = ['Thank you for participating in this experiment!' ...
                            '\n                                                           ' ...
                            '\nIn this experiment, you will be segmenting video clips from different narratives into distinct events. ' ...
                            '\nUpon watching all of the clips, you will be asked to recall the contents of each clip. ' ...
                            '\nFinally, you will be asked to complete a questionnaire assessing your watching habits and knowledge of different types of narratives.' ...
                            '\nPlease complete each task to the best of your ability.' ...
                            '\nYou are welcome to take breaks in between tasks, but please limit these breaks to a couple of minutes.' ...
                            '\n                                                      ' ...
                            '\nPress space to start the experiment.'];

        DrawFormattedText(win, instruction_text, 'center', 'center', [255 255 255], 70);
        Screen('Flip', win);
        KbStrokeWait; %Wait for a key press to flip the screen
        % Clear the screen
        Screen('Flip', win);

        % Show demo instructions
        demo_text = ['You will now be watching a short video to practice segmenting videos. ' ...
                     '\nFor the following clip, please press the space button whenever you feel like one meaningful event has ended and another is starting; ' ...
                     'these will be points in the clip when there is a change in topic, location, or time. ' ...
                     '\nThese events should be the most distinct units of action that seem natural and meaningful to you. ' ...
                     '\nThere should be multiple events per clip, and each event should be between 10 seconds and 2 minutes long. ' ...
                     '\n                                                                '...
                     '\nPress space to begin.'];

        DrawFormattedText(win, demo_text, 'center', 'center', [255 255 255], 70);
        Screen('Flip', win);
        KbStrokeWait;
    
        %Main loop for the demo
        %Learn to segment the video by tracking the number of events (as
        %indicated by space bar presses) that the participant does
        %They must get in a specific range to continue on to the experiment
        attempt = 1;
        while playing_movie
            fprintf('Demo take: %d\n', attempt);
            demo_num_events = 0;

            % Open the movie
            [output.movie, output.movieduration, output.fps] = Screen('OpenMovie', win, demo_filepath);
            output.framecount = output.movieduration * output.fps;

            % Set up full-screen display
            [screenWidth, screenHeight] = Screen('WindowSize', win);
            movRect = [0 0 screenWidth screenHeight];
            dstRect = CenterRect(movRect, Screen('Rect', win));

            % Play movie in full-screen
            Screen('PlayMovie', output.movie, 1, 0, 1.0);

            % Set up timers
            startTime = GetSecs;

            % Video playback and key response loop
            % This loop repeats until either the subject responded with a
            % keypress to indicate they detected the event in the video, or
            % until the end of the movie is reached.
            events = []; %log the timing  of events
            frames = []; %log the frames
            duration = []; %log the duration of the overall stimulus throughout event changes
            lastEventTime = -Inf; %setting the last event time to not existing so that it can be set later
            
            %Create a queue for the keyboard presses so they can be logged
            %properly/without logging multiple for one press
            KbQueueCreate();
            KbQueueStart();
         
            while true %video playing loop
                [movietexture, ~] = Screen('GetMovieImage', win, output.movie, 1);
                %If no movie texture appears (movie is done or doesn't
                %exist) = break out of the loop and move on to next part
                if movietexture <= 0
                    break;
                end

                Screen('DrawTexture', win, movietexture);
                Screen('Flip', win);
                Screen('Close', movietexture);


                %Loop for checking the presses of the keyboard
                %If a certain key is pressed, a certain action will occur
                %Esc = break out of this loop
                %f = close the entire experiment
                %space = log an event
                [pressed, firstPress] = KbQueueCheck;
                [~, secs, ~] = KbCheck;
                       if pressed
                            if firstPress(space)
                                currentTime = GetSecs; %get the current computer clock time
                                if currentTime - lastEventTime > .5 %if the current time is more than 2 s away from the last time the space bar was pressed, count it as a distinct event
                                    demo_num_events = demo_num_events + 1; %increase the number of events
                                    event_length = currentTime - lastEventTime; %get the length of that specific event
                                    total_duration = secs - startTime; %get the duration of the stimulus so far
                                    frameTime = Screen('GetMovieTimeIndex', output.movie); %get the time of the frame we've stopped on
                                    frame = round(frameTime * output.fps); %multiply that by the fps of the video to determine the frame number 
                                    events = [events, event_length]; 
                                    frames = [frames, frame];
                                    duration = [duration, total_duration];
              
                                    fprintf('Event time: %f\n', event_length);
                                    fprintf('Event frame: %f\n', frame);
                                    fprintf('Total duration elapsed: %f\n', total_duration);
                                    fprintf('----------------------\n');
                                    lastEventTime = currentTime; %set the last time the space bar was pressed as the current time
                                end
                            end
                        
                            if firstPress(esc)
                                break; %break out of loop
                            end
                        
                            if firstPress(f)
                                sca; %end entire experiment early, use for debugging purposes only or in emergency
                                Screen('CloseAll');
                                break;
                            end
                        end
   
                        end
                        KbQueueStop; %stop the keyboard queue
                        KbQueueFlush; %flush out the keyboard queue so it can be empty for real trials
   

   
            %Screen('Close'); Flush out extra textures, just in case...
            Screen('PlayMovie', output.movie, 0, 0, 0);
            Screen('CloseMovie', output.movie);

        
            %Print overall results of the demo
            fprintf('Number of events: %f\n', demo_num_events);
            fprintf('Demo is over... Check if number of events is accurate? \n');
            fprintf('----------------------------\n');

            %Check the number of events to see if the participant needs to
            %segment the video again
            Screen('TextSize', win, 50);
            Screen('TextFont', win, 'Arial');
            if demo_num_events < 8
                warning_text = ['Most people identify more events for this clip than you have. ' ...
                                'Press space to segment it again.'];
                DrawFormattedText(win, warning_text, 'center', 'center', [255 255 255], 70);
                Screen('Flip', win);
                KbStrokeWait;
                Screen('Flip', win);
                attempt = attempt + 1;
            elseif demo_num_events >= 16
                warning_text = ['Most people identify fewer events for this clip than you have. ' ...
                                'Press space to segment it again.'];
                DrawFormattedText(win, warning_text, 'center', 'center', [255 255 255], 70);
                Screen('Flip', win);
                KbStrokeWait;
                Screen('Flip', win);
                attempt = attempt + 1;
            else
                playing_movie = 0; %tells us that we don't have to play the movie again and can move on to the main trials
                %if playing_movie stays as 1, the while playing_movie loop
                %will repeat until it equals 0
            end

            KbReleaseWait;
        end
        %Demo is over... Moving on!


%Part 2: The trials
% Write to a file with all the information for each participant separated
% by the participant's number 
%This file will have all the information for each video clip as well 
%Excludes event segmentation from the demo video
fileID = fopen('pilot_data.txt', 'a');
fprintf(fileID, 'Last trial is over. Next trial...\n');
fprintf(fileID, '|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|\n');
fprintf(fileID, 'Participant number: %d\n', counter); %Keeps track of which participant is going and what randomized list of stimuli they will watch
fprintf(fileID, 'Number of attempts for demo: %d\n', attempt);
fprintf(fileID, 'Number of events from final demo run: %d\n', demo_num_events); %Track the number of events from the demo to act as calibration for future segmentation choices

% Display instructions after the demo
Screen('TextSize', win, 50);
Screen('TextFont', win, 'Arial');
experiment_instruction_text = ['You will now be watching 6 video clips from different movies and theatre productions. Each clip will be around 7 minutes long.' ...
    '\nBefore each clip, the title of the video will be presented. Please try and remember the titles of these videos..' ...
    '\nFor each of the following videos, please press the space button whenever you feel like one meaningful event has ended and another is starting; ' ...
    'these will be points in the clip when there is a change in topic, location, or time. ' ...
    '\nThese events should be the most distinct units of action that seem natural and meaningful to you. ' ...
    '\nThere should be multiple events per clip, and each event should be between 10 seconds and 2 minutes long. ' ...
    '\nYou are welcome to take breaks after watching each video, but please limit these breaks to a couple of minutes.' ...
    '\n                                      ' ...
    '\nPress space to begin.'];
DrawFormattedText(win, experiment_instruction_text, 'center', 'center', [255 255 255], 70);
Screen('Flip', win);
KbStrokeWait; %wait for space press to move onto the trial

%[finalgenresorder, binaryorder] = generate_genres_matrices();
%Load the matrices from the other file - generate_genres_matrices() 
%One matrix is made from random permutations of 1 -> 3 for theatre vs.
%film genres (theatre is randperm(1:3) + 3, so it's considered 3 -> 6)
%Resulting in a 72 x 6 matrix of numbers 1 -> 6 in a random order
%The other matrix is made from random permutations of 0/1
%Resulting in a 64 x 6 matrix of 0/1 in a random order
%These two matrices are then compared to each other
finalgenres = load('genres_matrix'); % Matrix for genres
finalgenreorder = finalgenres.finalgenresorder;
finalbinary = load('binary_matrix'); % Matrix for 0/1 [binary]
finalbinaryorder = finalbinary.binaryorder;


genres = {
    '1', 'SciFi';
    '2', 'Thriller';
    '3', 'Romance';
    '4', 'Shakespeare';
    '5', 'Musical';
    '6', 'Americana'
};

SciFi = {'0', 'Edge of Tomorrow'; '1', 'Demolition Man'};
Thriller = {'0', 'Secret in Their Eyes'; '1', 'The Fugitive'};
Romance = {'0', 'Marry Me'; '1', 'The Proposal'};
Shakespeare = {'0', 'Macbeth'; '1', 'Othello'};
Musical = {'0', 'Les Miserables'; '1', 'Phantom of the Opera'};
Americana = {'0', 'Almost, Maine'; '1', 'Our Town'};
genres_list = {SciFi, Thriller, Romance, Shakespeare, Musical, Americana};

% Define video paths
videos = {'The Fugitive', 'C:\Users\dessa\Downloads\The Fugitive CUT 2.0.mp4';
    'Edge of Tomorrow', 'C:\Users\dessa\Downloads\Edge of Tomorrow CUT 2.0.mp4';
    'Secret in Their Eyes', 'C:\Users\dessa\Downloads\Secret in Their Eyes CUT 2.0.mp4';
    'Demolition Man', 'C:\Users\dessa\Downloads\Demolition Man CUT.mp4';
    'Phantom of the Opera', 'C:\Users\dessa\OneDrive\Documents\Phantom of the Opera CUT.mp4';
    'Macbeth', 'C:\Users\dessa\Downloads\Macbeth CUT.mp4';
    'Marry Me', 'C:\Users\dessa\Downloads\Marry Me CUT.mp4';
    'Our Town', 'C:\Users\dessa\Downloads\Our Town CUT.mp4';
    'Almost, Maine', 'C:\Users\dessa\Downloads\Almost Maine CUT.mp4';
    'Othello', 'C:\Users\dessa\Downloads\Othello CUT.mp4';
    'Les Miserables', 'C:\Users\dessa\Downloads\Les Miserables CUT.mp4';
    'The Proposal', 'C:\Users\dessa\Downloads\The Proposal CUT.mp4'
};

% Ensure the counter value is within the bounds of both matrices
num_rows = min(size(finalgenreorder, 1), size(finalbinaryorder, 1));
if counter <= num_rows
    genre_values = finalgenreorder(counter, :);
    binary_values = finalbinaryorder(counter, :);

    selected_stimuli = [];

    for k = 1:length(genre_values)
        genre_index = genre_values(k);
        binary_value = num2str(binary_values(k));

        % Find the corresponding genre list
        genre_list = genres_list{genre_index};

        % Find the video name
        for j = 1:size(genre_list, 1)
            if strcmp(genre_list{j, 1}, binary_value)
                video_name = genre_list{j, 2};
                selected_stimuli = [selected_stimuli, {video_name}];
                break;
            end
        end 
    end
else
    error('Row to process exceeds the number of rows in the matrices.');
end

% Initialize trial counter
i = 0; 
KbQueueStart;

for j = 1:length(selected_stimuli)
    selected_stimulus = selected_stimuli{j};
    selected_stimulus_path = '';
    fprintf(fileID, 'Stimulus: %s\n', selected_stimulus);
    fprintf('Stimulus: %s\n', selected_stimulus);

    % Find selected stimulus path
    for k = 1:size(videos, 1)
        if strcmp(videos{k, 1}, selected_stimulus)
            selected_stimulus_path = videos{k, 2};
            break;
        end
    end

    try
        % Open the movie file and initialize variables
        moviename = selected_stimulus_path;

        % Display Instructions
        Screen('TextSize', win, 50);
        Screen('TextFont', win, 'Arial');
        DrawFormattedText(win, [selected_stimulus, '\nPress space to play.'], 'center', 'center', [255 255 255], 70);
        Screen('Flip', win);

        % Start processing the stimulus
        i = i + 1; % Increment trial counter
        fprintf(fileID, 'Trial number %f\n', i);

        % Open the movie file and query movie info
        [output.movie, output.movieduration, output.fps] = Screen('OpenMovie', win, moviename);
        output.framecount = output.movieduration * output.fps;

        % Wait for key press to start the video
        KbStrokeWait;
        Screen('PlayMovie', output.movie, 1, 0, 1.0);

        % Video playback and key response loop
        movietexture = 0; % Texture handle for the current movie frame.
        reactiontime = -1; % Variable to store reaction time.
        lastpts = 0; % Presentation timestamp of last frame.
        onsettime = -1; % Realtime at which the event was shown to the subject.
        rejecttrial = 0; % Flag which is set to 1 to reject an invalid trial.
        num_events = 0; %Logs the number of events identified in the stimulus
        skipped = 0; %Logs the number of frames skipped
        events = []; %List that stores the specific time at which the space bar is pressed 
        frames = []; %List that stores the frame that the movie was on when the space bar was pressed
        duration = []; %List that stores the overall duration of the movie and when it was specifically stopped

        % Set up timers
        startTime = GetSecs;
        lastEventTime = -Inf;

        % Initialize the keyboard queue and start it
        KbQueueStart();
        
        %Video and tracking space bar presses loop
        %At the end of each movie texture being shown, the texture will be
        %flushed to save memory
        while true
          
                [movietexture, pts] = Screen('GetMovieImage', win, output.movie, 1);
                output.movietexture(i) = movietexture;

                if movietexture <= 0
                    break;
                end

                Screen('DrawTexture', win, movietexture);
                [vblTimeStamp(i), stimulusOnsetTime(i), flipTimeStamp(i), Missed(i)] = Screen('Flip', win);
                output.presentation = vblTimeStamp(i) - stimulusOnsetTime(i);

                 if (onsettime == -1 && pts >= 1) %if the onset time of the frame is different than anticipated, indicates that we've skipped a frame
                    if pts - lastpts > 1.5 * (1 / output.fps) %If the presentation time of the most recent frame - presentation time of last frame is greater than 1.5x the fps, skipped frame!
                         skipped = skipped + 1;
                    end
                 end

                lastpts = pts; %make the most recent frame the last frame
                Screen('Close', movietexture); %Close each texture to save memory
                movietexture = 0;
          
            %Check the keyboard responses of the participant
                        %secs will give us the time of keypress as returned
                        %by GetSecs
                        %pressed will give us that a key has been pressed
                        %firstPress gives us the time that each key was
                        %first released since the most recent call to
                        %KbQueueCheck

            [keyIsDown, secs, keyCode] = KbCheck;
            [pressed, firstPress] = KbQueueCheck;

            if pressed
                if firstPress(space)
                    %This loop tells us the length of the
                    %current event, the duration of the
                    %stimulus (using secs), and the frame the
                    %movie was on when the space button was
                    %pressed 
                    currentTime = GetSecs;
                    if currentTime - lastEventTime > .5
                         num_events = num_events + 1; %increase the number of events
                         event_length = currentTime - lastEventTime; %get the length of that specific event
                         total_duration = secs - startTime; %get the duration of the stimulus so far
                         frameTime = Screen('GetMovieTimeIndex', output.movie); %get the time of the frame we've stopped on
                         frame = round(frameTime * output.fps); %multiply that by the fps of the video to determine the frame number 
                         events = [events, event_length]; 
                         frames = [frames, frame];
                         duration = [duration, total_duration];

                        %print out results after each space
                        %press
                        fprintf('Event time: %f\n', event_length);
                        fprintf('Event frame: %d\n', frame);
                        fprintf('Total duration elapsed: %f\n', total_duration);
                        fprintf('       \n');
                       fprintf(fileID, 'Event #%d:\n Event time = %f\n Total duration = %f\n Frame number = %f\n', num_events, event_length, total_duration, frame);
                       %set the last time the space bar was pressed as the current time 
                       lastEventTime = currentTime; 
                    end
                end

                if firstPress(esc)
                    break; % Skip to the next stimulus
                end

                if firstPress(f)
                    sca;
                    Screen('CloseAll');
                    break;
                end
            end
        end

        % Stop playback and close the movie file
        Screen('PlayMovie', output.movie, 0);
        Screen('CloseMovie', output.movie);f

       %Print total number of events for that stimulus once
        %the video playing loop is over
       fprintf('Total number of events: %f\n', num_events);
       fprintf('------------------------\n');
       %save to file
       fprintf(fileID, 'Total number of events: %f\n', num_events);
       fprintf(fileID, 'Total duration of stimuli: %f\n', output.movieduration);
       fprintf(fileID, '--------------------------------------------\n');
       

        % Print out trials result if it was a valid trial
        if rejecttrial == 0
            fprintf('Trial %i valid.', i);
        end

        if rejecttrial == -1
            fprintf('Trial %i rejected: Left the experiment early.', i);
        end

        if rejecttrial == 4
            fprintf('Trial %i rejected. Way too many skips in movie playback!!!\n', i);
        end

    catch ME
        fprintf('Error processing stimulus %s: %s\n', selected_stimulus, ME.message);
    end
end

outputFinal.output = output;


%Reject trial? 
fprintf('Trial %i result: %f\n', rejecttrial);

KbQueueStop;
KbQueueRelease;

fclose(fileID);



%Part 3: Free recall
%Set up a recording for participants to recall information from all of the
%stimuli they just watched
    Screen('Flip', win);
    Screen('TextSize', win, 50);
    Screen('TextFont', win, 'Arial');
    free_recall_text = ['You will now be tested on what you remember from the 6 movie and theatre clips you just watched. ' ...
                        '\nPlease verbally describe the plot of as many clips as you can in as much detail as possible. You do not have to describe the clips in the same order that you watched them in.' ...
                        '\nYou may speak for as long as you want, but try to speak for at least 2 minutes. ' ...
                        '\nTo start the recording, please press the space button. '...
                        '\nWhen you are finished, please press the space button again.' ...
                        '\n                                                     ' ...
                        '\nPress space to begin.'];

    DrawFormattedText(win, free_recall_text, 'center', 'center', [255 255 255], 70);
    Screen('Flip', win);
    KbStrokeWait;

    % Set up audio recording
    %For my computer: Microphone Array Realtek High Definition Audio
    %For Windows 11 my specific computer, I need to set it up so that it
    %looks for my device through GetDevices to find the specific device
    %name
    %Probably simpler on a mac computer
    InitializePsychSound();
    frequency = 44100; % Standard CD-quality sampling rate
    channels = 1; % Mono audio recording
    deviceName = 'Microphone Array (Realtek High Definition Audio)'; 
    devices = PsychPortAudio('GetDevices', 3); %get all of the audio devices on my computer
    deviceIndex = []; %store the audio device
    for i = 1:length(devices) %looking for deviceName
        if contains(devices(i).DeviceName, deviceName)
            deviceIndex = devices(i).DeviceIndex; %device index becomes my deviceName
            break;
        end
    end
    %pahandle opens the specific audio device for recording
    pahandle = PsychPortAudio('Open', deviceIndex, 2, 0, frequency, channels);
    PsychPortAudio('GetAudioData', pahandle, 3600); % Buffer for up to 1 hour of recording

    % Display recording message
    DrawFormattedText(win, 'Recording has started. Press space to stop.', 'center', 'center', [255 255 0], 70);
    Screen('Flip', win);

    % Start recording
    %Recording will be started and stopped by pressing the space bar
    %When the space bar is first pressed, recording will begin and text
    %will display indicating that
    %When the space bar is pressed again, the recording will finish and the
    %participant will be prompted to move on 

    PsychPortAudio('Start', pahandle, 0, 0, 1); 
    % Check for space bar press to stop recording
    stop = false;
    while ~stop
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(space)
            stop = true; %end the recording
        end
        WaitSecs(0.1); % Check every 100 milliseconds
    end

    % Stop recording
    PsychPortAudio('Stop', pahandle, 1);
    audiodata = PsychPortAudio('GetAudioData', pahandle);
    PsychPortAudio('Close', pahandle);
    %Store the audio recording as a .wav file that can be easily accessed
    %Each recording will be differentiated by the participant's number
    audiowrite(sprintf('recordedAudioFreeRecall[#%d].wav', counter), audiodata, frequency);
    Screen('Flip', win);
    DrawFormattedText(win, 'Recording stopped. Press space to continue.', 'center','center', [0 255 255], 70);
    Screen('Flip',win);
    KbStrokeWait;


    %Part 4: Cued recall instructions
    %6 recordings will be made from this loop - one for each stimulus
    %For every stimulus that the participant just watched, the names of the
    %stimuli will be presented in a random order and the participant will
    %record a 1-2 sentence summary of the plot
    Screen('TextSize', win, 50);
    Screen('TextFont', win, 'Arial');
    cued_recall_text = ['You will now be shown the titles of the 6 movie and theatre clips you just watched one more time. '...
                        '\nFor each title shown, please provide a one to two-sentence summary of the plot.'  ...
                        '\nIf you did not describe the plot of this clip already in depth during the previous recording, please describe it in full now instead of summarizing it.' ...
                        '\nTo start the recording, please press the space button. ' ...
                        '\nWhen you are finished, please press the space button again.' ...
                        '\n                                                     ' ...
                        '\nPress space to continue.'];

    DrawFormattedText(win, cued_recall_text, 'center', 'center', [255 255 255], 70);
    Screen('Flip', win);
    KbStrokeWait;
    
    %randomize the list of selected stimuli so that they're not presented
    %in the same order that they were just played in 
    random_indices = randperm(length(selected_stimuli));
    random_stimuli = selected_stimuli(random_indices);

    for j = 1:length(random_stimuli)
        selected_stimulus = random_stimuli{j};

        % Display the stimulus text
        Screen('TextSize', win, 50);
        Screen('TextFont', win, 'Arial');
        DrawFormattedText(win, [selected_stimulus, '\nPress space to begin.'], 'center', 'center', [255 255 255], 70);
        Screen('Flip', win);
        KbStrokeWait;
        Screen('Flip', win); 

    %Use audio set up from the free recall and just re-initialize sound so
    %a new recording can occur
    InitializePsychSound();
    pahandle = PsychPortAudio('Open', deviceIndex, 2, 0, frequency, channels);
    PsychPortAudio('GetAudioData', pahandle, 3600); % Buffer for up to 1 hour of recording

    % Display recording message
    DrawFormattedText(win, 'Recording has started. Press space to stop.', 'center', 'center', [255 255 0], 70);
    Screen('Flip', win);

        % Start recording
        PsychPortAudio('Start', pahandle, 0, 0, 1);

        % Check for space bar press to stop recording
        stop = false;
        while ~stop
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && keyCode(space)
                stop = true;
            end
            WaitSecs(0.1); % Check every 100 milliseconds
        end

        % Stop recording
       PsychPortAudio('Stop', pahandle, 1);
       audiodata = PsychPortAudio('GetAudioData', pahandle);
       PsychPortAudio('Close', pahandle);
       audiowrite(sprintf('%s_recordedAudioCuedRecall[#%d].wav',selected_stimulus, counter), audiodata', frequency);
       
       Screen('Flip, win');
       DrawFormattedText(win, 'Recording stopped. Press space to continue.', 'center','center', [0 255 255], 70);
       Screen('Flip',win);
       KbStrokeWait;
    end
    KbStrokeWait;

    %Part 5: Questionnaire
    %Display end instructions and link to a qualtrics survey that each
    %participant needs to fill out to complete the experiment
    instructionText = ['For the final task in this experiment, you will fill out a questionnaire about your watching habits.' ...
                       '\nAt this time, this screen will close, and the questionnaire will load as a Google Chrome webpage. ' ...
                       '\nThis questionnaire should take no longer than 10 minutes to complete.' ...
                       '\nPress space to exit this screen.'];
    DrawFormattedText(win, instructionText, 'center', 'center', [255 255 255], 70);
    Screen('Flip', win);
    KbStrokeWait;

    % Close the screen and link to a qualtrics questionnaire
    ShowCursor;
    sca;
    url = 'https://universityrochester.co1.qualtrics.com/jfe/form/SV_bK73SBUWrr4ieJU';
    web(url, '-browser');
    fprintf('All finished!\n')
    return;
    
    %All done!
    end 