function runBlock(window, blockIdx, params, apertureTexture, apertureRect, xCenter, yCenter, runOnset)
    % runBlock.m: Run a single block of trials
    
    % Display block start message
    disp(['Starting Block ', num2str(blockIdx)]);
    
    % Get trials for this block
    blockTrials = params.design.blocks{blockIdx}.trials;
    numTrials = length(blockTrials);
    
    % Run each trial in the block
    for trialIdx = 1:numTrials
        % Get current trial
        currentTrial = blockTrials(trialIdx);
        
        % Get trial type from the design
        trialType = currentTrial.trialType;
        
        % Run the trial
        runTrials(window, trialType, params, apertureTexture, apertureRect, xCenter, yCenter, currentTrial, blockIdx, trialIdx, runOnset);
        
        % Present grey screen and fixation period (ITI/blank period)
        Screen('FillRect', window, params.display.backgroundColor);
        drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColor);
        Screen('Flip', window);
        WaitSecs(params.timing.ITI);
        
        % Check for early exit (e.g., escape key)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(KbName('ESCAPE'))
            disp('############## Experiment terminated by user (ESC pressed) ##############');
            % Throw a specific error that can be caught to save partial data
            error('UserTerminated:EscapePressed', 'Experiment terminated by user pressing ESCAPE');
        end
    end
    
    % If this isn't the last block, present the block blank period
    % if params.numBlocks > 1 && blockIdx < params.numBlocks
    if blockIdx < params.timing.numBlocks && params.timing.numBlocks > 1
        disp(['Presenting block blank period after block ', num2str(blockIdx)]);
        Screen('FillRect', window, params.display.backgroundColor);
        drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColor);
        Screen('Flip', window);
        WaitSecs(params.timing.blockBlankDuration);
    end
    
    % Display block end message
    disp(['Completed Block ', num2str(blockIdx)]);
end
    