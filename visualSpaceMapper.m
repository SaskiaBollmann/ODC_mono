function params = visualSpaceMapper(params)
    % visualSpaceMapper - Interactive tool to map visual space in the scanner
    %
    % Input:
    %   params - Parameter structure containing display settings and participant info
    %
    % Controls:
    % - Arrow keys: Move the circle
    % - S key: Reduce circle size
    % - L key: Enlarge circle size
    % - ESC key: Save settings and exit
    %
    % Output:
    % - Saves circle position and radius to a .mat file in the participant's data folder
    
    % Clear the workspace and screen
    close all;
    sca;
    KbName('UnifyKeyNames');
    
    try
        % If no params provided, create minimal structure
        if nargin < 1 || isempty(params)
            pptCode = inputdlg('Enter participant code:', 'Participant Information', 1);
            if isempty(pptCode) || isempty(pptCode{1})
                pptCode = 'unknown';
            else
                pptCode = pptCode{1};
            end
            
            % Create minimal params
            params = struct();
            params.metadata = struct();
            params.metadata.observer = pptCode;
            params = get_params(params);
        end
        
        % Extract participant code for convenience
        pptCode = params.metadata.observer;
        
        % Get display parameters
        display = params.display;
        
        % Initialize parameters
        backgroundColor = [128 128 128]; %display.backgroundColor;  % Grey background from display params
        circleColor = [0 0 0];                     % Black circle
        circleThickness = 3;                       % Thickness of circle outline in pixels
        initialRadius = params.stimulus.circleRadius;  % Initial radius from params
        radiusStep = 5;                            % How much to change radius with each key press
        moveStep = 10;                             % How much to move with each arrow key press
        
        % Get screen parameters
        screenNumber = display.screenNumber;
        
        % Set up PsychImaging
        PsychImaging('PrepareConfiguration');
        
        % Check if imaging_mode is specified
        if isfield(display, 'imaging_mode') && ~isempty(display.imaging_mode)
            PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
            for i = 1:length(display.imaging_mode)
                PsychImaging('AddTask', display.imaging_mode{i}{:});
            end
        end
        
        % Open window with appropriate settings
        Screen('Preference', 'SkipSyncTests', display.skipSyncTests);
        
        % Use window_rect if specified
        if isfield(display, 'window_rect') && ~isempty(display.window_rect)
            [window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundColor, display.window_rect);
        else
            [window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundColor, []);
        end
        
        % Get screen dimensions
        [screenWidth, screenHeight] = Screen('WindowSize', window);
        [xCenter, yCenter] = RectCenter(windowRect);
        
        % Initialize circle position and size
        circleX = xCenter;
        circleY = yCenter;
        circleRadius = initialRadius;
        
        % Display instructions - clear screen first to avoid artifacts
        Screen('FillRect', window, backgroundColor);
        Screen('TextSize', window, display.textSize);
        instructText = ['Visual Space Mapper\n\n' ...
                       'Experimenter to use display keys to adjust the circle\n' ...
                       'Use arrow keys to move the circle\n' ...
                       'Press S to make the circle smaller\n' ...
                       'Press L to make the circle larger\n' ...
                       'Press ESC to save and exit\n\n' ...
                       'Press any key to begin'];
        DrawFormattedText(window, instructText, 'center', 'center', [0 0 0]);
        Screen('Flip', window);
        KbWait;
        
        % Main loop
        exitFlag = false;
        while ~exitFlag
            % Draw the circle outline
            circleRect = [circleX-circleRadius, circleY-circleRadius, circleX+circleRadius, circleY+circleRadius];
            Screen('FrameOval', window, circleColor, circleRect, circleThickness);
            
            % Display current settings
            infoText = sprintf('Position: [%d, %d]\nRadius: %d pixels\nParticipant: %s', ...
                              round(circleX), round(circleY), round(circleRadius), pptCode);
            DrawFormattedText(window, infoText, 'center', screenHeight - 100, [0 0 0]);
            
            % Flip to the screen
            Screen('Flip', window);
            
            % Check for key presses
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                % Move with arrow keys
                if keyCode(KbName('LeftArrow'))
                    circleX = max(circleRadius, circleX - moveStep);
                elseif keyCode(KbName('RightArrow'))
                    circleX = min(screenWidth - circleRadius, circleX + moveStep);
                elseif keyCode(KbName('UpArrow'))
                    circleY = max(circleRadius, circleY - moveStep);
                elseif keyCode(KbName('DownArrow'))
                    circleY = min(screenHeight - circleRadius, circleY + moveStep);
                % Change size with S/L keys
                elseif keyCode(KbName('s'))
                    circleRadius = max(10, circleRadius - radiusStep);
                elseif keyCode(KbName('l'))
                    circleRadius = min(min(screenWidth, screenHeight)/2, circleRadius + radiusStep);
                % Exit with ESC key
                elseif keyCode(KbName('ESCAPE'))
                    exitFlag = true;
                end
                
                % Small delay to prevent too rapid key processing
                WaitSecs(0.05);
            end
        end
        
        % Save the settings
        settings = struct();
        settings.observer = pptCode;
        settings.circleX = circleX;
        settings.circleY = circleY;
        settings.circleRadius = circleRadius;
        settings.screenWidth = screenWidth;
        settings.screenHeight = screenHeight;
        settings.screenCenter = [xCenter, yCenter];
        settings.display = display;  % Save the display parameters too
        
        % Create filename with participant code and date/time (no overwrite)
        ts = datestr(now, 'yyyymmdd_HHMMSS');
        if isfield(params.metadata, 'dataFolder') && ~isempty(params.metadata.dataFolder)
            % Save in participant's data folder
            filename = fullfile(params.metadata.dataFolder, ['visualSpaceMap_' pptCode '_' ts '.mat']);
        else
            % Fallback to current directory if data folder not specified
            filename = ['visualSpaceMap_' pptCode '_' ts '.mat'];
        end
        
        % Save to file
        save(filename, 'settings');
        
        % Display confirmation
        confirmText = sprintf('Settings saved to:\n%s', filename);
        Screen('FillRect', window, backgroundColor);
        DrawFormattedText(window, confirmText, 'center', 'center', [0 0 0]);
        Screen('Flip', window);
        WaitSecs(2);
        
        % Clean up
        sca;
        fprintf('Visual space mapping complete.\n');
        fprintf('Settings saved to: %s\n', filename);
        fprintf('Participant: %s\n', pptCode);
        fprintf('Circle position: [%d, %d]\n', round(circleX), round(circleY));
        fprintf('Circle radius: %d pixels\n', round(circleRadius));
        
        % Update params
        params.display.customCenter = [circleX, circleY];
        params.stimulus.circleRadius = circleRadius;
        
        % Also update calibration structure
        params.calibration.visualSpace.circleX = circleX;
        params.calibration.visualSpace.circleY = circleY;
        params.calibration.visualSpace.circleRadius = circleRadius;
        
    catch e
        % Clean up on error
        sca;
        psychrethrow(psychlasterror);
    end
end 