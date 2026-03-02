function runTrials(window, trialType, params, apertureTexture, apertureRect, xCenter, yCenter, currentTrial, blockNum, trialNum, runOnset)
    % Display info
    disp(['Presenting Trial: ', trialType]);
    
    % Use params.display directly instead of calling get_display_params
    display = params.display;

    % Timing setup using GUI-configured values
    overallTrialDuration = params.timing.trialDuration;
    subTrialDuration = params.timing.subTrialDuration;
    overallStartTime = GetSecs;
    subTrialCounter = 1;

    % Response timing parameters
    minResponseTime = 0.2;  % Could potentially move to GUI if needed

    % Get the appropriate colors - use calibrated colors if available, otherwise defaults
    if isfield(params.calibration, 'anaglyphs') && ...
       isfield(params.calibration.anaglyphs, 'redColor') && ...
       ~isempty(params.calibration.anaglyphs.redColor)
        redColor = params.calibration.anaglyphs.redColor;
    else
        redColor = params.stimulus.defaultRedColor;
    end
    
    if isfield(params.calibration, 'anaglyphs') && ...
       isfield(params.calibration.anaglyphs, 'greenColor') && ...
       ~isempty(params.calibration.anaglyphs.greenColor)
        greenColor = params.calibration.anaglyphs.greenColor;
    else
        greenColor = params.stimulus.defaultGreenColor;
    end

    % Get the appropriate coherence values - use calibrated values if available, otherwise defaults
    if isfield(params.calibration, 'coherence') && ...
       isfield(params.calibration.coherence, 'single') && ...
       ~isempty(params.calibration.coherence.single)
        singleCoherence = params.calibration.coherence.single;
    else
        singleCoherence = params.stimulus.coherenceRedSingle;  % Use default as fallback
    end

    % Outer loop for overall trial duration
    while GetSecs - overallStartTime < overallTrialDuration
        % Get current subtrial parameters
        subtrial = currentTrial.subTrials(subTrialCounter);
        
        % Initialize coherent angles to NaN
        coherentAngleRed = NaN;
        coherentAngleGreen = NaN;
        
        % Generate new dot fields based on trial type and subtrial parameters
        switch trialType
            case 'red'  % single red
                coherentAngleRed = selectWedgeAngle(subtrial.primaryWedgeClass, params.stimulus.verticalWedgeRanges, params.stimulus.horizontalWedgeRanges);
                dotsRed = generateDots(2 * params.stimulus.numDotsPerColor, params.stimulus.circleRadius, ...
                    singleCoherence, coherentAngleRed, params.stimulus.speed, params.stimulus.jitter, xCenter, yCenter);
            case 'green'  % single green
                coherentAngleGreen = selectWedgeAngle(subtrial.primaryWedgeClass, params.stimulus.verticalWedgeRanges, params.stimulus.horizontalWedgeRanges);
                dotsGreen = generateDots(2 * params.stimulus.numDotsPerColor, params.stimulus.circleRadius, ...
                    singleCoherence, coherentAngleGreen, params.stimulus.speed, params.stimulus.jitter, xCenter, yCenter);
        end

        % Response tracking setup
        subtrialResponse = [];
        responseBufferTime = 1;

        % Subtrial timing
        subTrialOnset = GetSecs;
        prevTime = subTrialOnset;
        
        % Check if this is the last subtrial
        isLastSubtrial = (GetSecs - overallStartTime + subTrialDuration + responseBufferTime) >= overallTrialDuration;
        subtrialEndTime = subTrialOnset + subTrialDuration;
        if isLastSubtrial
            subtrialEndTime = subtrialEndTime + responseBufferTime;
        end
        
        % Inner loop for subtrial duration
        while GetSecs < subtrialEndTime && GetSecs - overallStartTime < overallTrialDuration
            currentTime = GetSecs;
            dt = currentTime - prevTime;
            prevTime = currentTime;
            
            % Update dots
            switch trialType
                case 'red'
                    dotsRed = updateDots(dotsRed, params.stimulus.circleRadius, xCenter, yCenter, dt, params.stimulus.speed, params.stimulus.jitter);
                case 'green'
                    dotsGreen = updateDots(dotsGreen, params.stimulus.circleRadius, xCenter, yCenter, dt, params.stimulus.speed, params.stimulus.jitter);
            end
            
            % Draw stimuli
            Screen('FillRect', window, display.backgroundColor);
            switch trialType
                case 'red'
                    Screen('DrawDots', window, [dotsRed.x; dotsRed.y], params.stimulus.dotRadius, redColor', [], 2);
                case 'green'
                    Screen('DrawDots', window, [dotsGreen.x; dotsGreen.y], params.stimulus.dotRadius, greenColor', [], 2);
            end
            
            % Draw fixation and aperture
            drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColor);
            Screen('DrawTexture', window, apertureTexture, [], apertureRect, [], [], [], display.backgroundColor);
            Screen('Flip', window);

            % Check for responses
            if isempty(subtrialResponse)
                response = subjResponse(params.metadata.runType);
                if ~isempty(response) && (response(2) - subTrialOnset) >= minResponseTime
                    subtrialResponse = response;
                end
            end
        end
        
        % Log subtrial info
        accuracy = calculateAccuracy(params, trialType, subtrial, subtrialResponse, subTrialOnset);
        logSubtrial(blockNum, trialNum, subTrialCounter, trialType, subtrial, ...
                   coherentAngleRed, coherentAngleGreen, subTrialOnset, GetSecs, runOnset, ...
                   subtrialResponse, accuracy);
        
        subTrialCounter = subTrialCounter + 1;
    end
end

