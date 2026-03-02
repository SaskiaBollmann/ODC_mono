function params = configureTimingParamsGUI(params)
    % configureTimingParamsGUI - GUI to configure timing parameters for the experiment
    %
    % Input:
    %   params - Parameter structure containing initial timing settings
    %
    % Output:
    %   params - Updated parameter structure with configured timing parameters
    
    % Define constraints for trial and subtrial durations
    minTrialDuration = 8.0;      % Minimum trial duration in seconds
    maxTrialDuration = 15.0;     % Maximum trial duration in seconds
    minSubTrialDuration = 1.5;   % Minimum subtrial duration in seconds
    maxSubTrialDuration = 2.5;   % Maximum subtrial duration in seconds
    targetSubTrialDuration = 1.7; % Target subtrial duration in seconds
    
    % Initialize variables to track optimal parameters
    bestTrialDuration = 0;
    bestNumSubtrials = 0;
    bestSubtrialDuration = 0;
    % Single block design - no multiple blocks in v2
    
    % Initialize configuration flag
    configCompleted = false;
    
    % Create the figure with increased height
    f = figure('Name', 'Configure Timing Parameters', ...
              'NumberTitle', 'off', ...
              'MenuBar', 'none', ...
              'ToolBar', 'none', ...
              'Position', [100, 100, 800, 800], ...
              'CloseRequestFcn', @closeGUI);
    
    % Check if figure was created successfully
    if ~ishandle(f)
        error('Failed to create figure for timing parameter configuration');
    end
    
    % Create panels with adjusted positions and increased height
    inputPanel = uipanel('Title', 'Input Parameters', 'Position', [0.05, 0.60, 0.4, 0.35]);
    resultsPanel = uipanel('Title', 'Results', 'Position', [0.5, 0.1, 0.45, 0.85]);
    manualPanel = uipanel('Title', 'Manual Adjustments', 'Position', [0.05, 0.1, 0.4, 0.45]); 
    
    % Input fields moved up by 50 pixels
    uicontrol('Parent', inputPanel, 'Style', 'text', 'String', 'TR (seconds):', ...
              'Position', [20, 220, 150, 20], 'HorizontalAlignment', 'left');
    trEdit = uicontrol('Parent', inputPanel, 'Style', 'edit', ...
                       'Position', [180, 220, 100, 25], ...
                       'String', sprintf('%.4f', params.timing.TR), ...
                       'Callback', @updateTR);
    
    uicontrol('Parent', inputPanel, 'Style', 'text', 'String', 'Run Duration (min):', ...
              'Position', [20, 190, 155, 20], 'HorizontalAlignment', 'left');
    durationEdit = uicontrol('Parent', inputPanel, 'Style', 'edit', ...
                            'Position', [180, 190, 100, 25], ...
                            'String', '10', ...
                            'Callback', @updateDuration);
    
    uicontrol('Parent', inputPanel, 'Style', 'text', 'String', 'Initial Blank (TRs):', ...
              'Position', [20, 160, 150, 20], 'HorizontalAlignment', 'left');
    initialBlankEdit = uicontrol('Parent', inputPanel, 'Style', 'edit', ...
                                'Position', [180, 160, 100, 25], ...
                                'String', num2str(round(params.timing.initialBlankDuration / params.timing.TR)), ...
                                'Callback', @updateInitialBlank);
    
    uicontrol('Parent', inputPanel, 'Style', 'text', 'String', 'End Blank (TRs):', ...
              'Position', [20, 130, 150, 20], 'HorizontalAlignment', 'left');
    endBlankEdit = uicontrol('Parent', inputPanel, 'Style', 'edit', ...
                            'Position', [180, 130, 100, 25], ...
                            'String', num2str(round(params.timing.endBlankDuration / params.timing.TR)), ...
                            'Callback', @updateEndBlank);
    
    uicontrol('Parent', inputPanel, 'Style', 'text', 'String', 'Block Blank (TRs):', ...
              'Position', [20, 100, 150, 20], 'HorizontalAlignment', 'left');
    blockBlankEdit = uicontrol('Parent', inputPanel, 'Style', 'edit', ...
                              'Position', [180, 100, 100, 25], ...
                              'String', num2str(round(params.timing.blockBlankDuration / params.timing.TR)), ...
                              'Callback', @updateBlockBlank);
    
    % Add Match ITI checkbox to input panel - default to unchecked (ITI = 0)
    itiMatchCheckbox = uicontrol('Parent', inputPanel, 'Style', 'checkbox', ...
                                'String', 'Match ITI to Trial Duration', ...
                                'Position', [20, 70, 200, 20], ...
                                'Value', 0, ...  % Default to unchecked (ITI = 0)
                                'Callback', @toggleITIMatch);
    
    % Add Calculate button inside the input panel, below the checkbox
    calculateButton = uicontrol('Parent', inputPanel, 'Style', 'pushbutton', ...
                               'String', 'Calculate Optimal Parameters', ...
                               'Position', [20, 30, 260, 30], ...
                               'Callback', @calculateOptimal);
    
    % Manual adjustment fields moved up by 50 pixels
    uicontrol('Parent', manualPanel, 'Style', 'text', 'String', 'Trial Duration (TRs):', ...
              'Position', [20, 270, 150, 20], 'HorizontalAlignment', 'left');
    trialTRsEdit = uicontrol('Parent', manualPanel, 'Style', 'edit', ...
                            'Position', [180, 270, 100, 25], ...
                            'String', '', 'Enable', 'off', ...
                            'Callback', @updateTrialDuration);
    
    % Move ITI to manual adjustments panel
    uicontrol('Parent', manualPanel, 'Style', 'text', 'String', 'ITI (TRs):', ...
              'Position', [20, 240, 150, 20], 'HorizontalAlignment', 'left');
    itiEdit = uicontrol('Parent', manualPanel, 'Style', 'edit', ...
                        'Position', [180, 240, 100, 25], ...
                        'String', '0', ...  % Default ITI = 0 TRs
                        'Enable', 'on', ... % Enabled by default since checkbox unchecked
                        'Callback', @updateITI);
    
    uicontrol('Parent', manualPanel, 'Style', 'text', 'String', 'Number of Subtrials:', ...
              'Position', [20, 210, 150, 20], 'HorizontalAlignment', 'left');
    numSubtrialsEdit = uicontrol('Parent', manualPanel, 'Style', 'edit', ...
                                'Position', [180, 210, 100, 25], ...
                                'String', '', 'Enable', 'off', ...
                                'Callback', @updateNumSubtrials);
    
    uicontrol('Parent', manualPanel, 'Style', 'text', 'String', 'Total Trials:', ...
              'Position', [20, 180, 150, 20], 'HorizontalAlignment', 'left');
    totalTrialsEdit = uicontrol('Parent', manualPanel, 'Style', 'edit', ...
                               'Position', [180, 180, 100, 25], ...
                               'String', '', 'Enable', 'off', ...
                               'Callback', @updateFromManualInput);
    
    % Add a second row of manual adjustments
    uicontrol('Parent', manualPanel, 'Style', 'text', 'String', 'Trials per Block:', ...
              'Position', [20, 150, 150, 20], 'HorizontalAlignment', 'left');
    trialsPerBlockEdit = uicontrol('Parent', manualPanel, 'Style', 'edit', ...
                                  'Position', [180, 150, 100, 25], ...
                                  'String', '', 'Enable', 'off', ...
                                  'Callback', @updateFromManualInput);
    
    % Block controls removed - single block design in v2
    
    % Add Finish button
    finishButton = uicontrol('Style', 'pushbutton', 'String', 'Finish Configuration', ...
                            'Position', [400, 50, 150, 30], ...
                            'Callback', @finishConfig);
    
    % Results text area - moved up by 100 pixels
    resultsText = uicontrol('Parent', resultsPanel, 'Style', 'text', ...
                           'Position', [10, 110, 340, 500], ... % Moved up by 100 pixels
                           'HorizontalAlignment', 'left', ...
                           'String', 'Results will appear here after calculation.');
    
    % Create a local copy of params.timing to work with
    params.timing.trialDuration = 0;  % Will be calculated
    params.timing.numSubTrials = 0;   % Will be calculated
    params.timing.subTrialDuration = 0; % Will be calculated
    params.timing.totalTrials = 0;    % Will be calculated
    params.timing.numTrialsPerBlock = 0; % Will be calculated
    params.timing.numBlocks = 0;      % Will be calculated
    params.timing.totalTRs = 0;       % Will be calculated
    
    % Wait for user to finish configuration
    if ishandle(f)
        uiwait(f);
    else
        warning('Figure handle is not valid. Configuration may not complete properly.');
    end
    
    % Return updated params
    if ~configCompleted
        % If user closed without finishing, return original params
        warning('Configuration was not completed. Using original parameters.');
    end
    
    % Handle close request
    function closeGUI(~, ~)
        if ~configCompleted
            choice = questdlg('Configuration not completed. Exit anyway?', ...
                'Exit Confirmation', 'Yes', 'No', 'No');
            if strcmp(choice, 'Yes')
                delete(f);
            end
        else
            delete(f);
        end
    end
    
    % Update TR
    function updateTR(~, ~)
        newTR = str2double(get(trEdit, 'String'));
        if ~isnan(newTR) && newTR > 0
            % Format with 4 decimal places
            set(trEdit, 'String', sprintf('%.4f', newTR));
            
            % Update params
            params.timing.TR = newTR;
            
            % Update all TR-dependent fields
            params.timing.initialBlankDuration = str2double(get(initialBlankEdit, 'String')) * newTR;
            params.timing.endBlankDuration = str2double(get(endBlankEdit, 'String')) * newTR;
            params.timing.blockBlankDuration = str2double(get(blockBlankEdit, 'String')) * newTR;
            params.timing.ITI = str2double(get(itiEdit, 'String')) * newTR;
            
            % If trial duration has been set, update it
            if bestTrialDuration > 0
                params.timing.trialDuration = round(params.timing.trialDuration / params.timing.TR) * newTR;
                set(trialTRsEdit, 'String', num2str(round(params.timing.trialDuration / newTR)));
            end
            
            % Update display
            updateResultsDisplay();
        else
            warndlg('TR must be a positive number.');
            set(trEdit, 'String', sprintf('%.4f', params.timing.TR));
        end
    end
    
    % Update target duration
    function updateDuration(~, ~)
        % No immediate action needed, will be used in calculation
    end
    
    % Update initial blank
    function updateInitialBlank(~, ~)
        newInitialBlankTRs = str2double(get(initialBlankEdit, 'String'));
        if ~isnan(newInitialBlankTRs) && newInitialBlankTRs >= 0
            % Ensure it's a whole number
            newInitialBlankTRs = round(newInitialBlankTRs);
            set(initialBlankEdit, 'String', num2str(newInitialBlankTRs));
            
            % Update params
            params.timing.initialBlankDuration = newInitialBlankTRs * params.timing.TR;
            
            % Update display
            updateResultsDisplay();
        else
            warndlg('Initial blank must be a non-negative integer.');
            set(initialBlankEdit, 'String', num2str(round(params.timing.initialBlankDuration / params.timing.TR)));
        end
    end
    
    % Update end blank
    function updateEndBlank(~, ~)
        newEndBlankTRs = str2double(get(endBlankEdit, 'String'));
        if ~isnan(newEndBlankTRs) && newEndBlankTRs >= 0
            % Ensure it's a whole number
            newEndBlankTRs = round(newEndBlankTRs);
            set(endBlankEdit, 'String', num2str(newEndBlankTRs));
            
            % Update params
            params.timing.endBlankDuration = newEndBlankTRs * params.timing.TR;
            
            % Update display
            updateResultsDisplay();
        else
            warndlg('End blank must be a non-negative integer.');
            set(endBlankEdit, 'String', num2str(round(params.timing.endBlankDuration / params.timing.TR)));
        end
    end
    
    % Update block blank
    function updateBlockBlank(~, ~)
        newBlockBlankTRs = str2double(get(blockBlankEdit, 'String'));
        if ~isnan(newBlockBlankTRs) && newBlockBlankTRs >= 0
            % Ensure it's a whole number
            newBlockBlankTRs = round(newBlockBlankTRs);
            set(blockBlankEdit, 'String', num2str(newBlockBlankTRs));
            
            % Update params
            params.timing.blockBlankDuration = newBlockBlankTRs * params.timing.TR;
            
            % Update display
            updateResultsDisplay();
        else
            warndlg('Block blank must be a non-negative integer.');
            set(blockBlankEdit, 'String', num2str(round(params.timing.blockBlankDuration / params.timing.TR)));
        end
    end
    
    % Toggle ITI matching
    function toggleITIMatch(~, ~)
        if get(itiMatchCheckbox, 'Value')
            % If checked, match ITI to trial duration and disable ITI edit
            if ~isempty(get(trialTRsEdit, 'String'))
                trialTRs = str2double(get(trialTRsEdit, 'String'));
                set(itiEdit, 'String', num2str(trialTRs));
                params.timing.ITI = trialTRs * params.timing.TR;
                set(itiEdit, 'Enable', 'off');
                updateResultsDisplay();
            end
        else
            % If unchecked, enable ITI edit
            set(itiEdit, 'Enable', 'on');
        end
    end
    
    % Update trial duration
    function updateTrialDuration(~, ~)
        % Get new trial duration in TRs
        newTrialTRs = str2double(get(trialTRsEdit, 'String'));
        if ~isnan(newTrialTRs) && newTrialTRs > 0
            % Ensure it's a whole number
            newTrialTRs = round(newTrialTRs);
            set(trialTRsEdit, 'String', num2str(newTrialTRs));
            
            newTrialDuration = newTrialTRs * params.timing.TR;
            
            % Check if duration is within bounds
            if newTrialDuration >= minTrialDuration && newTrialDuration <= maxTrialDuration
                % Find valid number of subtrials
                validNumSubtrials = [];
                bestSubTrialDuration = Inf;
                bestNumSubtrials = 0;
                bestDifference = Inf;
                
                % Try different numbers of subtrials
                for i = 2:floor(newTrialDuration/minSubTrialDuration)
                    testSubTrialDuration = newTrialDuration / i;
                    if testSubTrialDuration >= minSubTrialDuration && testSubTrialDuration <= maxSubTrialDuration
                        % Calculate how close this is to our target duration
                        difference = abs(testSubTrialDuration - targetSubTrialDuration);
                        if difference < bestDifference
                            bestDifference = difference;
                            bestNumSubtrials = i;
                            bestSubTrialDuration = testSubTrialDuration;
                        end
                    end
                end
                
                if bestNumSubtrials > 0
                    % Update parameters
                    params.timing.trialDuration = newTrialDuration;
                    params.timing.numSubTrials = bestNumSubtrials;
                    params.timing.subTrialDuration = bestSubTrialDuration;
                    
                    % Update ITI if checkbox is checked
                    if get(itiMatchCheckbox, 'Value')
                        params.timing.ITI = newTrialDuration;
                        set(itiEdit, 'String', num2str(newTrialTRs));
                    end
                    
                    % Recalculate number of trials that can fit
                    recalculateTrials();
                    
                    % Update display
                    set(numSubtrialsEdit, 'String', num2str(bestNumSubtrials));
                    updateResultsDisplay();
                else
                    warndlg('No valid number of subtrials found for this trial duration.');
                    set(trialTRsEdit, 'String', num2str(round(params.timing.trialDuration/params.timing.TR)));
                end
            else
                warndlg(sprintf('Trial duration must be between %.1f and %.1f seconds.', minTrialDuration, maxTrialDuration));
                set(trialTRsEdit, 'String', num2str(round(params.timing.trialDuration/params.timing.TR)));
            end
        end
    end
    
    % Update ITI
    function updateITI(~, ~)
        newITITRs = str2double(get(itiEdit, 'String'));
        if ~isnan(newITITRs) && newITITRs >= 0
            % Ensure it's a whole number
            newITITRs = round(newITITRs);
            set(itiEdit, 'String', num2str(newITITRs));
            
            % Update params
            params.timing.ITI = newITITRs * params.timing.TR;
            
            % Recalculate number of trials that can fit
            recalculateTrials();
            
            % Update display
            updateResultsDisplay();
        else
            warndlg('ITI must be a non-negative integer.');
            set(itiEdit, 'String', num2str(round(params.timing.ITI / params.timing.TR)));
        end
    end
    
    % Helper function to recalculate trials based on current parameters
    function recalculateTrials()
        % Get target run duration in minutes
        targetMinutes = str2double(get(durationEdit, 'String'));
        if isnan(targetMinutes) || targetMinutes <= 0
            return;
        end
        
        % Convert to seconds
        targetSeconds = targetMinutes * 60;
        
        % Get fixed time components
        initialBlankTRs = str2double(get(initialBlankEdit, 'String'));
        endBlankTRs = str2double(get(endBlankEdit, 'String'));
        blockBlankTRs = str2double(get(blockBlankEdit, 'String'));
        
        % Convert to seconds
        initialBlankDuration = initialBlankTRs * params.timing.TR;
        endBlankDuration = endBlankTRs * params.timing.TR;
        blockBlankDuration = blockBlankTRs * params.timing.TR;
        
        % Fixed time in seconds
        fixedTime = initialBlankDuration + endBlankDuration;
        
        % Calculate time per trial including ITI
        timePerTrial = params.timing.trialDuration + params.timing.ITI;
        
        % Calculate how many trials we can fit
        availableTime = targetSeconds - fixedTime;
        totalTrials = floor(availableTime / timePerTrial);
        
        % Ensure totalTrials is divisible by 8 (for balanced conditions)
        totalTrials = floor(totalTrials / 8) * 8;
        
        if totalTrials <= 0
            totalTrials = 8; % Minimum of 8 trials
        end
        
        % Single block design - all trials in one block
        numBlocks = 1;  % Always single block in v2
        trialsPerBlock = totalTrials;
        
        % Update params
        params.timing.totalTrials = totalTrials;
        params.timing.numTrialsPerBlock = trialsPerBlock;
        params.timing.numBlocks = numBlocks;
        
        % Update UI
        set(totalTrialsEdit, 'String', num2str(totalTrials));
        set(trialsPerBlockEdit, 'String', num2str(trialsPerBlock));
    end
    
    % Calculate optimal parameters
    function calculateOptimal(~, ~)
        % Get target run duration in minutes
        targetMinutes = str2double(get(durationEdit, 'String'));
        if isnan(targetMinutes) || targetMinutes <= 0
            warndlg('Target run duration must be a positive number.');
            return;
        end
        
        % Convert to seconds
        targetSeconds = targetMinutes * 60;
        
        % Calculate fixed time components in TRs
        initialBlankTRs = str2double(get(initialBlankEdit, 'String'));
        endBlankTRs = str2double(get(endBlankEdit, 'String'));
        blockBlankTRs = str2double(get(blockBlankEdit, 'String'));
        
        % Convert to seconds
        params.timing.initialBlankDuration = initialBlankTRs * params.timing.TR;
        params.timing.endBlankDuration = endBlankTRs * params.timing.TR;
        params.timing.blockBlankDuration = blockBlankTRs * params.timing.TR;
        
        % Fixed time in seconds
        fixedTime = params.timing.initialBlankDuration + params.timing.endBlankDuration;
        
        % Initialize best parameters
        bestTrialTRs = 0;
        bestNumSubTrials = 0;
        bestSubTrialDuration = 0;
        bestScore = Inf;
        
        % Try different trial durations in whole TRs
        for trialTRs = 1:10  % Try from 1 to 10 TRs
            trialDuration = trialTRs * params.timing.TR;
            
            % Try different numbers of subtrials
            for numSubTrials = 2:floor(trialDuration/minSubTrialDuration)
                subTrialDuration = trialDuration / numSubTrials;
                
                % Check if subtrial duration is within bounds
                if subTrialDuration < minSubTrialDuration || subTrialDuration > maxSubTrialDuration
                    continue;
                end
                
                % Calculate time per trial including ITI
                if get(itiMatchCheckbox, 'Value')
                    % Match ITI to trial duration
                    timePerTrial = trialDuration * 2;  % Trial + ITI
                    itiTRs = trialTRs;
                else
                    % Use existing ITI
                    itiTRs = round(params.timing.ITI / params.timing.TR);
                    timePerTrial = trialDuration + (itiTRs * params.timing.TR);
                end
                
                % Calculate how many trials we can fit
                availableTime = targetSeconds - fixedTime;
                totalTrials = floor(availableTime / timePerTrial);
                
                % Ensure totalTrials is divisible by 8 (for balanced conditions)
                totalTrials = floor(totalTrials / 8) * 8;
                
                if totalTrials <= 0
                    continue;
                end
                
                % Single block design - all trials in one block
                numBlocks = 1;  % Always single block in v2
                trialsPerBlock = totalTrials;
                
                % No block blank time needed for single block
                actualRunDuration = fixedTime + (totalTrials * timePerTrial);
                
                % Calculate score based on how close we are to target duration
                % and how close subtrial duration is to target
                durationDiff = abs(actualRunDuration - targetSeconds);
                subtrialDiff = abs(subTrialDuration - targetSubTrialDuration);
                
                % Weight duration difference more heavily
                score = durationDiff + subtrialDiff * 10;
                
                % Update best parameters if this is better
                if score < bestScore
                    bestScore = score;
                    bestTrialTRs = trialTRs;
                    bestTrialDuration = trialDuration;
                    bestNumSubTrials = numSubTrials;
                    bestSubTrialDuration = subTrialDuration;
                    bestTotalTrials = totalTrials;
                    bestTrialsPerBlock = trialsPerBlock;
                    bestNumBlocks = numBlocks;
                    bestITITRs = itiTRs;
                end
            end
        end
        
        % Update params with best values
        params.timing.trialDuration = bestTrialDuration;
        params.timing.numSubTrials = bestNumSubTrials;
        params.timing.subTrialDuration = bestSubTrialDuration;
        params.timing.totalTrials = bestTotalTrials;
        params.timing.numTrialsPerBlock = bestTrialsPerBlock;
        params.timing.numBlocks = bestNumBlocks;
        params.timing.ITI = bestITITRs * params.timing.TR;
        
        % Calculate total TRs (single block design)
        totalTRs = initialBlankTRs + ...                     % Initial blank
                  endBlankTRs + ...                         % End blank
                  0 + ...                                   % No block blanks in single block design
                  (bestTotalTrials * bestTrialTRs) + ...            % Active trial time
                  (bestTotalTrials * bestITITRs);                   % ITI time
        
        params.timing.totalTRs = totalTRs;
        
        % Enable manual adjustment fields and set their values
        set(trialTRsEdit, 'Enable', 'on', 'String', num2str(bestTrialTRs));
        
        % Fix the error by using string values for Enable property
        if get(itiMatchCheckbox, 'Value')
            set(itiEdit, 'Enable', 'off', 'String', num2str(bestITITRs));
        else
            set(itiEdit, 'Enable', 'on', 'String', num2str(bestITITRs));
        end
        
        set(numSubtrialsEdit, 'Enable', 'on', 'String', num2str(bestNumSubTrials));
        set(totalTrialsEdit, 'Enable', 'on', 'String', num2str(bestTotalTrials));
        set(trialsPerBlockEdit, 'Enable', 'on', 'String', num2str(bestTrialsPerBlock));
        % numBlocksEdit removed - single block design
        
        % Display results
        updateResultsDisplay();
    end
    
    % Update the results display text
    function updateResultsDisplay()
        % Get current values
        initialBlankTRs = str2double(get(initialBlankEdit, 'String'));
        endBlankTRs = str2double(get(endBlankEdit, 'String'));
        blockBlankTRs = str2double(get(blockBlankEdit, 'String'));
        
        % Calculate total run duration in seconds
        if params.timing.totalTrials > 0
            % Get trial duration in TRs
            trialTRs = round(params.timing.trialDuration / params.timing.TR);
            
            % Get ITI in TRs
            itiTRs = round(params.timing.ITI / params.timing.TR);
            
            % Calculate total TRs
            totalTRs = initialBlankTRs + ...                     % Initial blank
                      endBlankTRs + ...                         % End blank
                      0 + ...                                   % No block blanks in single block design
                      (params.timing.totalTrials * trialTRs) + ...            % Active trial time
                      (params.timing.totalTrials * itiTRs);                   % ITI time
            
            % Calculate actual run duration in seconds
            actualRunDuration = totalTRs * params.timing.TR;
            
            % Update params
            params.timing.totalTRs = totalTRs;
            
            % Calculate analysis metrics
            % Assuming 2 main conditions with equal distribution of trials
            trialsPerCondition = params.timing.totalTrials / 2;
            timePerCondition = trialsPerCondition * params.timing.trialDuration;
            percentPerCondition = (timePerCondition / actualRunDuration) * 100;
            
            % Format results text (single block design)
            resultsStr = sprintf(['--- Trial Timing ---\n', ...
                                 'Trial Duration: %.2f s (%d TRs)\n', ...
                                 'Number of Subtrials: %d\n', ...
                                 'Subtrial Duration: %.2f s\n', ...
                                 'Total Run Duration: %.2f s (%.2f min)\n', ...
                                 'Total TRs: %d\n\n', ...
                                 '--- Blank Periods ---\n', ...
                                 'Initial Blank: %.2f s (%d TRs)\n', ...
                                 'End Blank: %.2f s (%d TRs)\n', ...
                                 'ITI: %.2f s (%d TRs)\n\n', ...
                                 '--- Trial Structure (Single Block) ---\n', ...
                                 'Total Trials: %d\n\n', ...
                                 '--- Analysis Metrics ---\n', ...
                                 'Trials per Condition: %d\n', ...
                                 'Imaging Time per Condition: %.2f s\n', ...
                                 'Percentage of Run Time per Condition: %.2f%%\n', ...
                                 'Total Active Imaging Time: %.2f s (%.2f%%)\n', ...
                                 'Total Non-imaging Time (blanks + ITIs): %.2f s (%.2f%%)'], ...
                                params.timing.trialDuration, trialTRs, ...
                                params.timing.numSubTrials, ...
                                params.timing.subTrialDuration, ...
                                actualRunDuration, actualRunDuration/60, ...
                                totalTRs, ...
                                params.timing.initialBlankDuration, initialBlankTRs, ...
                                params.timing.endBlankDuration, endBlankTRs, ...
                                params.timing.ITI, itiTRs, ...
                                params.timing.totalTrials, ...
                                trialsPerCondition, ...
                                timePerCondition, ...
                                percentPerCondition, ...
                                params.timing.totalTrials * params.timing.trialDuration, ...
                                (params.timing.totalTrials * params.timing.trialDuration / actualRunDuration) * 100, ...
                                actualRunDuration - (params.timing.totalTrials * params.timing.trialDuration), ...
                                ((actualRunDuration - (params.timing.totalTrials * params.timing.trialDuration)) / actualRunDuration) * 100);
        else
            resultsStr = 'Results will appear here after calculation.';
        end
        
        % Update display
        set(resultsText, 'String', resultsStr);
    end
    
    % Update calculations when manual inputs change
    function updateFromManualInput(src, ~)
        % Only proceed if the optimal calculation has been done
        if bestTrialDuration == 0
            return;
        end
        
        % Get values from manual inputs (single block design)
        newTotalTrials = str2double(get(totalTrialsEdit, 'String'));
        newTrialsPerBlock = str2double(get(trialsPerBlockEdit, 'String'));
        
        % Single block design - synchronize total trials and trials per block
        if src == totalTrialsEdit && ~isnan(newTotalTrials)
            % Ensure the total is divisible by 8
            newTotalTrials = floor(newTotalTrials / 8) * 8;
            set(totalTrialsEdit, 'String', num2str(newTotalTrials));
            
            % In single block design, trials per block = total trials
            newTrialsPerBlock = newTotalTrials;
            set(trialsPerBlockEdit, 'String', num2str(newTrialsPerBlock));
        elseif src == trialsPerBlockEdit && ~isnan(newTrialsPerBlock)
            % In single block design, total trials = trials per block
            newTotalTrials = newTrialsPerBlock;
            % Ensure divisible by 8
            newTotalTrials = floor(newTotalTrials / 8) * 8;
            set(totalTrialsEdit, 'String', num2str(newTotalTrials));
            
            % Update trials per block to match
            newTrialsPerBlock = newTotalTrials;
            set(trialsPerBlockEdit, 'String', num2str(newTrialsPerBlock));
        end
        
        % Update params with new values (single block design)
        params.timing.totalTrials = newTotalTrials;
        params.timing.numTrialsPerBlock = newTrialsPerBlock;
        params.timing.numBlocks = 1;  % Always 1 in single block design
        
        % Calculate run duration and TRs (single block design)
        fixedTime = params.timing.initialBlankDuration + params.timing.endBlankDuration;  % No block blanks in single block design
        timePerTrial = params.timing.trialDuration + params.timing.ITI;
        actualRunDuration = fixedTime + (params.timing.totalTrials * timePerTrial);
        params.timing.totalTRs = ceil(actualRunDuration / params.timing.TR);
        
        % Update display
        updateResultsDisplay();
    end
    
    % Finish configuration
    function finishConfig(~, ~)
        % Check if all required parameters have been set
        if params.timing.trialDuration <= 0 || params.timing.numSubTrials <= 0 || params.timing.totalTrials <= 0
            warndlg('Please calculate optimal parameters first.');
            return;
        end
        
        % Set additional timing parameters
        params.timing.runDuration = params.timing.totalTRs * params.timing.TR;
        
        % Ensure all timing parameters are properly set
        % These fields should match the ones in get_params.m
        requiredFields = {'TR', 'initialBlankDuration', 'blockBlankDuration', 'endBlankDuration', ...
                         'ITI', 'trialDuration', 'numSubTrials', 'subTrialDuration', ...
                         'totalTrials', 'numTrialsPerBlock', 'numBlocks', 'totalTRs', 'runDuration'};
        
        % Check if any required fields are missing
        missingFields = {};
        for i = 1:length(requiredFields)
            field = requiredFields{i};
            if ~isfield(params.timing, field) || isempty(params.timing.(field))
                missingFields{end+1} = field;
            end
        end
        
        if ~isempty(missingFields)
            warndlg(['The following timing parameters are missing: ' strjoin(missingFields, ', ')]);
            return;
        end
        
        % Set configuration completed flag
        configCompleted = true;
        
        % Close the GUI
        delete(f);
    end
    
    % Update number of subtrials
    function updateNumSubtrials(~, ~)
        % Get new number of subtrials
        newNumSubtrials = str2double(get(numSubtrialsEdit, 'String'));
        if ~isnan(newNumSubtrials) && newNumSubtrials >= 2
            % Calculate resulting subtrial duration
            testSubTrialDuration = params.timing.trialDuration / newNumSubtrials;
            
            % Check if this divides evenly within a small tolerance
            tolerance = 0.001;  % 1ms tolerance for floating point division
            if abs(testSubTrialDuration - round(testSubTrialDuration * 1000)/1000) > tolerance
                warndlg(sprintf('Cannot evenly divide trial duration (%.2f s) into %d subtrials.\nWould result in %.3f s subtrials.', ...
                              params.timing.trialDuration, newNumSubtrials, testSubTrialDuration));
                set(numSubtrialsEdit, 'String', num2str(params.timing.numSubTrials));
                return;
            end
            
            % Check if duration is within bounds
            if testSubTrialDuration >= minSubTrialDuration && testSubTrialDuration <= maxSubTrialDuration
                % Update parameters
                params.timing.numSubTrials = newNumSubtrials;
                params.timing.subTrialDuration = testSubTrialDuration;
                
                % Update display
                updateResultsDisplay();
            else
                warndlg(sprintf('This number of subtrials would result in subtrial duration of %.2f seconds.\nMust be between %.1f and %.1f seconds.', ...
                              testSubTrialDuration, minSubTrialDuration, maxSubTrialDuration));
                set(numSubtrialsEdit, 'String', num2str(params.timing.numSubTrials));
            end
        else
            warndlg('Number of subtrials must be at least 2.');
            set(numSubtrialsEdit, 'String', num2str(params.timing.numSubTrials));
        end
    end
end 