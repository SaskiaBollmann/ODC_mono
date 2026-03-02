function [thresholds, calibData] = calibrateCoherence(params)
    
    % Initialize window
    sca;
    [window, windowRect, xCenter, yCenter, apertureTexture, apertureRect] = initializeWindow(params);
    
    % Constants
    q_num_trials_max = 6; %12;      % Maximum number of trials
    q_num_trials_min = 4; %8;       % Minimum number of trials
    q_trials_per_block = 8;     % Trials before updating target color
    q_blank_duration = 1.0;     % 1 second blank period
    q_instruct_duration = 3.0;  % 3 seconds instruction duration
    q_min_coherence = 0.0;      % 0% coherence
    q_max_coherence = 1.0;      % 100% coherence
    q_convergence_window = 4;   % Number of trials to check for convergence
    q_convergence_criterion = 0.02; % Maximum change in threshold estimate to consider converged (2%)
    
    % Initialize Quest with parameters optimized for brief visual stimuli
    %q_single = QuestCreate(0.5, 0.3, 0.82, 3.5, 0.01, 0.5); % previous parameters
    q_single = QuestCreate(0.35, ... % tGuess: Initial threshold estimate (35% coherence)
                          0.3, ...  % tGuessSd: Standard deviation of initial guess (uncertainty)
                          0.75, ... % pThreshold: Performance level that defines threshold (75% correct)
                          2.5, ...  % beta: Steepness of psychometric function (typical for motion tasks)
                          0.05, ... % delta: Lower asymptote (chance performance level)
                          0.03);    % gamma: Lapse rate (probability of error regardless of stimulus strength)
    
    % Create interleaved red/green trials for monocular calibration
    % All trials are treated as the same condition (monocular single eye)
    
    % Create equal numbers of red and green trials
    numRedTrials = q_num_trials_max / 2;
    numGreenTrials = q_num_trials_max / 2;
    
    % Create trial arrays
    redTrials = struct('type', repmat({'single'}, 1, numRedTrials), ...
                       'color', repmat({'red'}, 1, numRedTrials));
    greenTrials = struct('type', repmat({'single'}, 1, numGreenTrials), ...
                         'color', repmat({'green'}, 1, numGreenTrials));
    
    % Combine and randomize order for interleaving
    trial_array = [redTrials, greenTrials];
    randomOrder = randperm(length(trial_array));
    trial_array = trial_array(randomOrder);
    
    % Initialize data storage  
    calibData = struct();
    calibData.single = struct('trials', [], 'responses', [], 'coherence', []);
    
    % Main calibration loop - simplified for interleaved monocular trials
    previousEstimates = [];     % Store previous threshold estimates
    
    % Display initial instruction (applies to all monocular trials)
    % Note: No fixation dot during instructions to avoid occluding text
    Screen('FillRect', window, params.display.backgroundColor);
    %drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColorDefault);
    Screen('TextSize', window, params.display.textSize);
    instructStr = ['MONOCULAR COHERENCE CALIBRATION\n\n'...
        'You will see RED or GREEN dots moving\n' ...
        '- Press 1 if dots move more horizontally\n' ...
        '- Press 2 if dots move more vertically\n\n' ...
        'Press any key to begin...'];
    DrawFormattedText(window, instructStr, 'center', 'center', [1 1 1]);
    Screen('Flip', window);
    KbWait;
    
    % HIDDEN PRACTICE TRIAL - 100% coherence, does not count towards Quest
    fprintf('Running hidden practice trial with 100%% coherence...\n');
    
    % Choose random color and clear direction for practice
    practiceColor = {'red', 'green'};
    practiceColor = practiceColor{randi(2)};
    practiceVertical = rand > 0.5;  % Random choice of vertical vs horizontal
    
    if practiceVertical
        practiceWedgeClass = 'vertical';
        practiceCorrectResp = 2;
    else
        practiceWedgeClass = 'horizontal';
        practiceCorrectResp = 1;
    end
    
    % Run practice subtrials with 100% coherence (no special announcement)
    for subtrial = 1:params.timing.numSubTrials
        [response, rt] = runCalibrationSubtrial(window, params, 'single', practiceColor, ...
            1.0, 0, practiceWedgeClass, apertureTexture, apertureRect, xCenter, yCenter, params.task.fixationDotColorDefault);
        
        % Check accuracy but don't store or update Quest
        isCorrect = response == practiceCorrectResp;
        fprintf('Hidden practice subtrial %d: Correct = %d\n', subtrial, isCorrect);
    end
    
    % Brief inter-trial interval (same as regular trials)
    Screen('FillRect', window, params.display.backgroundColor);
    drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColorDefault);
    Screen('Flip', window);
    WaitSecs(q_blank_duration);
    
    % Process all calibration trials sequentially
    for t = 1:length(trial_array)
            % Get current trial type and color
            trialType = trial_array(t).type;
            trialColor = trial_array(t).color;
            
            % Run subtrials
            for subtrial = 1:params.timing.numSubTrials
                % Generate random motion direction
                isVertical = rand > 0.5;
                if isVertical
                    wedgeClass = 'vertical';
                    correctResp = 2;
                else
                    wedgeClass = 'horizontal';
                    correctResp = 1;
                end
                
                % Get current coherence estimate (bounded between 0 and 1)
                singleCoh = min(max(QuestQuantile(q_single), q_min_coherence), q_max_coherence);
                
                % Debug Quest values
                fprintf('Trial %d, Type: %s\n', t, trialType);
                fprintf('Single coherence: %.4f\n', singleCoh);
                
                % Run subtrial
                [response, rt] = runCalibrationSubtrial(window, params, trialType, trialColor, ...
                    singleCoh, 0, wedgeClass, apertureTexture, apertureRect, xCenter, yCenter, params.task.fixationDotColorDefault);
                
                % Determine accuracy
                isCorrect = response == correctResp;
                fprintf('isCorrect: %d\n', isCorrect);
                
                % Update Quest (if not first trial)
                if t > 1
                    fprintf('Single trial - Before update: Mean = %.4f\n', QuestMean(q_single));
                    q_single = QuestUpdate(q_single, singleCoh, isCorrect);
                    fprintf('Single trial - After update: Mean = %.4f\n', QuestMean(q_single));
                end
                
                % Store data
                calibData.single.responses(end+1) = isCorrect;
                calibData.single.coherence(end+1) = singleCoh;
            end
            
        % Inter-trial interval
        Screen('FillRect', window, params.display.backgroundColor);
        drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColorDefault);
        Screen('Flip', window);
        WaitSecs(q_blank_duration);
        
        % Check for early convergence after minimum trials
        if t >= q_num_trials_min && mod(t, 2) == 0  % Check every 2 trials after minimum
            currentEstimate = QuestMean(q_single);
            previousEstimates = [previousEstimates currentEstimate];
            
            % Keep only the last q_convergence_window estimates
            if length(previousEstimates) > q_convergence_window
                previousEstimates = previousEstimates(end-q_convergence_window+1:end);
            end
            
            % Check if threshold estimate has stabilized
            if length(previousEstimates) == q_convergence_window
                % Calculate maximum change in recent estimates
                maxChange = max(abs(diff(previousEstimates))) / mean(previousEstimates);
                
                % If change is below criterion, end calibration early
                if maxChange < q_convergence_criterion
                    fprintf('Threshold estimate has stabilized at %.4f (change: %.4f%%)\n', currentEstimate, maxChange*100);
                    fprintf('Ending calibration early after %d trials\n', t);
                    break;  % Exit the trial loop
                end
            end
        end
    end
    
    % Calculate final thresholds (excluding first trial)
    thresholds = struct();
    thresholds.single = min(max(QuestMean(q_single), q_min_coherence), q_max_coherence);
    
    % Save calibration values to text file
    calibFileName = fullfile(params.metadata.dataFolder, [params.metadata.observer '_coherence_calibration_TR' ...
                         sprintf('%.4f', params.timing.TR) 's_SubtrialDur' num2str(params.timing.subTrialDuration) 's.txt']);
    fid = fopen(calibFileName, 'w');
    fprintf(fid, 'Coherence calibration values for participant: %s\n', params.metadata.observer);
    fprintf(fid, 'Date: %s\n\n', datestr(now));
    fprintf(fid, 'TR: %.4f s\n', params.timing.TR);
    fprintf(fid, 'Subtrial Duration: %.2f s\n', params.timing.subTrialDuration);
    fprintf(fid, 'Single task coherence: %.4f\n', thresholds.single);
    fclose(fid);
    
    % Save threshold to params structure
    params.calibration.coherence.single = thresholds.single;
    
    % Display confirmation in command window
    fprintf('\nCoherence calibration completed and saved to: %s\n', calibFileName);
    fprintf('Single task coherence: %.4f\n', thresholds.single);
    
    % Plot results if not deployed
    if ~isdeployed
        plotCalibrationResults(calibData, params);
    end
    
    % Close window
    sca;
end

function [response, rt] = runCalibrationSubtrial(window, params, trialType, trialColor, singleCoherence, ~, wedgeClass, apertureTexture, apertureRect, xCenter, yCenter, fixationColor)
    % Initialize timing
    subtrialStart = GetSecs;
    prevTime = subtrialStart;
    response = [];
    rt = [];
    
    % Generate initial dots
    [dotsRed, dotsGreen] = generateCalibrationDots(params, false, strcmp(trialColor, 'red'), singleCoherence, 0, wedgeClass, xCenter, yCenter);
    
    % Run subtrial until response or timeout
    while GetSecs - subtrialStart < params.timing.subTrialDuration
        % Update timing
        currentTime = GetSecs;
        dt = currentTime - prevTime;
        prevTime = currentTime;
        
        % Update and draw dots
        [dotsRed, dotsGreen] = updateAndDrawDots(window, params, false, strcmp(trialColor, 'red'), dotsRed, dotsGreen, dt, xCenter, yCenter, apertureTexture, apertureRect, fixationColor);
        
        % Check for response if not already received
        if isempty(response)
            subtrialResponse = subjResponse('attention');
            if ~isempty(subtrialResponse)
                response = subtrialResponse(1);  % Get the key number
                rt = subtrialResponse(2) - subtrialStart;  % Calculate RT
            end
        end
    end
    
    % If no response was made, mark as missed
    if isempty(response)
        response = 0;  % 0 indicates no response
        rt = NaN;
    end
end

function [dotsRed, dotsGreen] = generateCalibrationDots(params, ~, isRed, singleCoherence, ~, wedgeClass, xCenter, yCenter)
    % Debug check
    if ~ismember(wedgeClass, {'vertical', 'horizontal'})
        error('Invalid wedgeClass: %s', wedgeClass);
    end
    
    % Generate dots for single color trials only
    currentCoherence = singleCoherence;
    if isRed
        coherentAngleRed = selectWedgeAngle(wedgeClass, params.stimulus.verticalWedgeRanges, params.stimulus.horizontalWedgeRanges);
        dotsRed = generateDots(2 * params.stimulus.numDotsPerColor, params.stimulus.circleRadius, currentCoherence, coherentAngleRed, params.stimulus.speed, params.stimulus.jitter, xCenter, yCenter);
        dotsGreen = [];
    else
        coherentAngleGreen = selectWedgeAngle(wedgeClass, params.stimulus.verticalWedgeRanges, params.stimulus.horizontalWedgeRanges);
        dotsGreen = generateDots(2 * params.stimulus.numDotsPerColor, params.stimulus.circleRadius, currentCoherence, coherentAngleGreen, params.stimulus.speed, params.stimulus.jitter, xCenter, yCenter);
        dotsRed = [];
    end
end

function [dotsRed, dotsGreen] = updateAndDrawDots(window, params, ~, isRed, dotsRed, dotsGreen, dt, xCenter, yCenter, apertureTexture, apertureRect, fixationColor)
    % Update dots for single color trials only
    if isRed
        dotsRed = updateDots(dotsRed, params.stimulus.circleRadius, xCenter, yCenter, dt, params.stimulus.speed, params.stimulus.jitter);
    else
        dotsGreen = updateDots(dotsGreen, params.stimulus.circleRadius, xCenter, yCenter, dt, params.stimulus.speed, params.stimulus.jitter);
    end
    
    % Draw stimuli
    Screen('FillRect', window, params.display.backgroundColor);
    if isRed
        % Use calibrated color values for red
        Screen('DrawDots', window, [dotsRed.x; dotsRed.y], params.stimulus.dotRadius, params.calibration.anaglyphs.redColor', [], 2);
    else
        % Use calibrated color values for green
        Screen('DrawDots', window, [dotsGreen.x; dotsGreen.y], params.stimulus.dotRadius, params.calibration.anaglyphs.greenColor', [], 2);
    end
    
    % Draw fixation and aperture
    drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, fixationColor);
    Screen('DrawTexture', window, apertureTexture, [], apertureRect, [], [], [], params.display.backgroundColor);
    Screen('Flip', window);
end

function plotCalibrationResults(calibData, params)
    % Create figure for single condition
    figure('Position', [100 100 600 500]);
    
    % Plot single condition  
    plotConditionResults(calibData.single.coherence, calibData.single.responses, 'Single');
    
    % Add title with participant info (annotation for R2017b compatibility; sgtitle is R2019b+)
    titlestr = ['Coherence Calibration: Participant ' params.metadata.observer ...
                ', TR=' num2str(params.timing.TR) 's, SubtrialDur=' num2str(params.timing.subTrialDuration) 's'];
    annotation(gcf, 'textbox', [0.1 0.92 0.8 0.06], 'String', titlestr, ...
               'FontSize', 14, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FitBoxToText', 'off');
    
    % Save figure to participant's folder
    figFilename = fullfile(params.metadata.dataFolder, ...
                          [params.metadata.observer '_coherence_calibration_TR' ...
                           sprintf('%.4f', params.timing.TR) 's_SubtrialDur' ...
                           num2str(params.timing.subTrialDuration) 's.png']);
    
    saveas(gcf, figFilename);
    disp(['Calibration figure saved to: ' figFilename]);
end

function plotConditionResults(coherenceValues, responses, conditionName)
    plot(1:length(coherenceValues), coherenceValues, 'b.-');
    hold on;
    plot(find(responses == 1), coherenceValues(responses == 1), 'g.', 'MarkerSize', 20);
    plot(find(responses == 0), coherenceValues(responses == 0), 'r.', 'MarkerSize', 20);
    xlabel('Subtrial Number');
    ylabel('Coherence');
    title([conditionName ' Condition Calibration']);
    legend('Tested Values', 'Correct', 'Incorrect');
    grid on;
end 