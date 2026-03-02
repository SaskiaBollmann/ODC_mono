function calibrationParams = calibrateAnaglyphs(params)
    % calibrateAnaglyphs - Calibrate R and G colors for red-green anaglyph goggles
    % Usage: calibrationParams = calibrateAnaglyphs(params)
    % 
    % Controls:
    % 1,2: Adjust red dots (decrease/increase)
    % 3,4: Adjust green dots (decrease/increase)
    % ESCAPE: Save and exit
    % 
    % Returns structure with calibrated color values
    
    % Get display parameters
    display = params.display;
    
    % Initialize window
    [window, windowRect, xCenter, yCenter] = initializeWindow(params);
    
    % Define colors
    white = [1 1 1];
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    
    % Setup calibration parameters
    dotSize = params.stimulus.dotRadius;
    nDots = params.stimulus.numDotsPerColor;  % Use same number of dots as main experiment
    speed = params.stimulus.speed;  % Use same speed as main experiment
    colorIncrement = 0.0125;
    
    % Initialize colors with stimulus defaults
    colors.dots1 = params.stimulus.defaultRedColor;    % Red dots
    colors.dots2 = params.stimulus.defaultGreenColor;  % Green dots
    
    % Generate initial dot fields using the same function as main experiment
    % Using 0 coherence for calibration (random motion)
    dotsRed = generateDotsAnaglyph(nDots, params.stimulus.circleRadius, 0, 0, speed, params.stimulus.jitter, xCenter, yCenter);
    dotsGreen = generateDotsAnaglyph(nDots, params.stimulus.circleRadius, 0, 0, speed, params.stimulus.jitter, xCenter, yCenter);
    
    % Setup keyboard
    KbName('UnifyKeyNames');
    escapeKey = KbName('ESCAPE');
    
    % Define keys for scanner compatibility (both top row and numpad)
    key1TopRow = KbName('1!');
    key2TopRow = KbName('2@');
    key3TopRow = KbName('3#');
    key4TopRow = KbName('4$');
    
    key1Numpad = KbName('1');
    key2Numpad = KbName('2');
    key3Numpad = KbName('3');
    key4Numpad = KbName('4');
    
    % Display instructions - clear screen first to avoid artifacts
    Screen('FillRect', window, display.backgroundColor);
    Screen('TextSize', window, display.textSize);
    instructText = ['Anaglyph Color Calibration\n\n' ...
        'Adjust colors until depth perception is optimal\n\n' ...
        '1,2: Adjust red (decrease/increase)\n' ...
        '3,4: Adjust green (decrease/increase)\n' ...
        '(should work with scanner buttons or display buttons)\n' ...
        'ESCAPE: Save and exit\n\n' ...
        'Press any key to begin...'];
    DrawFormattedText(window, instructText, 'center', 'center', white);
    Screen('Flip', window);
    KbWait;
    
    
    % Initialize timing variables
    prevTime = GetSecs;
    
    % Main calibration loop
    while true
        % Update timing
        currentTime = GetSecs;
        dt = currentTime - prevTime;
        prevTime = currentTime;
        
        % Check for keypress
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(escapeKey)
                break;
            end
            
            % Adjust colors based on key press (scanner compatible)
            if keyCode(key1TopRow) || keyCode(key1Numpad)
                colors.dots1(2:3) = max(0, colors.dots1(2:3) - colorIncrement);
            elseif keyCode(key2TopRow) || keyCode(key2Numpad)
                colors.dots1(2:3) = min(1, colors.dots1(2:3) + colorIncrement);
            elseif keyCode(key3TopRow) || keyCode(key3Numpad)
                colors.dots2(1) = max(0, colors.dots2(1) - colorIncrement);
            elseif keyCode(key4TopRow) || keyCode(key4Numpad)
                colors.dots2(1) = min(1, colors.dots2(1) + colorIncrement);
            end
            
            % Display current values
            fprintf('Current values:\n');
            fprintf('Red dots:   [%.2f %.2f %.2f]\n', colors.dots1);
            fprintf('Green dots: [%.2f %.2f %.2f]\n', colors.dots2);
            
            WaitSecs(0.1);
        end
        
        % Update dot positions
        dotsRed = updateDotsAnaglyph(dotsRed, params.stimulus.circleRadius, xCenter, yCenter, dt, speed, params.stimulus.jitter);
        dotsGreen = updateDotsAnaglyph(dotsGreen, params.stimulus.circleRadius, xCenter, yCenter, dt, speed, params.stimulus.jitter);
        
        % Draw
        Screen('FillRect', window, display.backgroundColor);
        
        % Draw dots
        Screen('DrawDots', window, [dotsRed.x; dotsRed.y], dotSize, colors.dots1, [], 2);
        Screen('DrawDots', window, [dotsGreen.x; dotsGreen.y], dotSize, colors.dots2, [], 2);
        
        % Draw fixation dot using the standard function
        drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColorDefault);
    
        % Show current values on screen
        valueText = sprintf('Red: [%.2f %.2f %.2f]\nGreen: [%.2f %.2f %.2f]', ...
            colors.dots1(1), colors.dots1(2), colors.dots1(3), ...
            colors.dots2(1), colors.dots2(2), colors.dots2(3));
        DrawFormattedText(window, valueText, 'center', screenYpixels * 0.05, white);
        
        Screen('Flip', window);
    end
    
    % Create settings structure for saving
    settings = struct();
    settings.observer = params.metadata.observer;
    settings.redColor = colors.dots1;
    settings.greenColor = colors.dots2;
    settings.date = datestr(now);
    
    % Save to .mat file with date/time in filename (no overwrite)
    ts = datestr(now, 'yyyymmdd_HHMMSS');
    matFileName = fullfile(params.metadata.dataFolder, [params.metadata.observer '_calibration_' ts '.mat']);
    save(matFileName, 'settings');
    
    % Also save to text file for reference
    txtFileName = fullfile(params.metadata.dataFolder, [params.metadata.observer '_calibration_' ts '.txt']);
    fid = fopen(txtFileName, 'w');
    fprintf(fid, 'Calibration values for participant: %s\n', params.metadata.observer);
    fprintf(fid, 'Date: %s\n\n', datestr(now));
    fprintf(fid, 'Red dots:   [%.3f %.3f %.3f]\n', colors.dots1);
    fprintf(fid, 'Green dots: [%.3f %.3f %.3f]\n', colors.dots2);
    fclose(fid);
    
    % Display confirmation on screen
    Screen('FillRect', window, display.backgroundColor);
    confirmText = sprintf('Calibration saved to:\n%s\n\nRed: [%.2f %.2f %.2f]\nGreen: [%.2f %.2f %.2f]', ...
        matFileName, colors.dots1(1), colors.dots1(2), colors.dots1(3), ...
        colors.dots2(1), colors.dots2(2), colors.dots2(3));
    DrawFormattedText(window, confirmText, 'center', 'center', white);
    Screen('Flip', window);
    WaitSecs(3);
    
    % Clean up
    Screen('CloseAll');
    ShowCursor;
    
    % Return calibrated values
    calibrationParams = params.calibration;  % Start with existing calibration
    calibrationParams.anaglyphs = struct();
    calibrationParams.anaglyphs.redColor = colors.dots1;
    calibrationParams.anaglyphs.greenColor = colors.dots2;
    
    % Display confirmation in command window
    fprintf('\nCalibration completed and saved to:\n');
    fprintf('MAT file: %s\n', matFileName);
    fprintf('TXT file: %s\n', txtFileName);
    fprintf('Red dots:   [%.3f %.3f %.3f]\n', colors.dots1);
    fprintf('Green dots: [%.3f %.3f %.3f]\n', colors.dots2);
end

function dots = generateDotsAnaglyph(nDots, radius, coherence, direction, speed, jitter, xCenter, yCenter)
    % Generate random dot positions within a circle
    theta = 2 * pi * rand(1, nDots);
    r = radius * sqrt(rand(1, nDots));
    
    dots = struct();
    dots.x = r .* cos(theta) + xCenter;
    dots.y = r .* sin(theta) + yCenter;
    dots.direction = zeros(1, nDots);
    
    % Set directions for coherent dots
    nCoherent = round(nDots * coherence);
    dots.direction(1:nCoherent) = direction;
    
    % Set random directions for noise dots
    dots.direction(nCoherent+1:end) = 360 * rand(1, nDots - nCoherent);
    
    % Set speeds with jitter
    dots.speed = speed + jitter * (rand(1, nDots) - 0.5);
end

function dots = updateDotsAnaglyph(dots, radius, xCenter, yCenter, dt, speed, jitter)
    % Update dot positions based on their direction and speed
    nDots = length(dots.x);
    
    % Convert direction to radians
    dirRad = dots.direction * pi / 180;
    
    % Update positions
    dots.x = dots.x + dots.speed .* cos(dirRad) * dt;
    dots.y = dots.y + dots.speed .* sin(dirRad) * dt;
    
    % Check which dots are outside the circle
    distFromCenter = sqrt((dots.x - xCenter).^2 + (dots.y - yCenter).^2);
    outsideCircle = distFromCenter > radius;
    
    % Reposition dots that are outside the circle
    nOutside = sum(outsideCircle);
    if nOutside > 0
        % Generate new random positions within the circle
        theta = 2 * pi * rand(1, nOutside);
        r = radius * sqrt(rand(1, nOutside));
        
        dots.x(outsideCircle) = r .* cos(theta) + xCenter;
        dots.y(outsideCircle) = r .* sin(theta) + yCenter;
        
        % Randomize directions for repositioned dots
        dots.direction(outsideCircle) = 360 * rand(1, nOutside);
        
        % Randomize speeds for repositioned dots
        dots.speed(outsideCircle) = speed + jitter * (rand(1, nOutside) - 0.5);
    end
end 