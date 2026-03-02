function runExperiment(params)
    % runExperiment: Main function to run the experiment
    %
    % Input:
    %   params - Complete parameter structure with all experiment settings
    
    try
        % Hide figures during experiment
        set(0, 'DefaultFigureVisible', 'off');
        
        % Initialize global trial log for detailed tracking
        global trialLog;
        trialLog = [];
        
        % Initialize trialLog fields for all run types
        [trialLog.Block] = deal([]);
        [trialLog.Trial] = deal([]);
        [trialLog.Subtrial] = deal([]);
        [trialLog.Condition] = deal([]);
        [trialLog.WedgeRed] = deal([]);
        [trialLog.AngleRed] = deal([]);
        [trialLog.WedgeGreen] = deal([]);
        [trialLog.AngleGreen] = deal([]);
        [trialLog.Onset] = deal([]);
        [trialLog.Offset] = deal([]);
        [trialLog.SubtrialDuration] = deal([]);
        [trialLog.SubtrialRespKey] = deal([]);
        [trialLog.SubtrialRespTrialRT] = deal([]);
        [trialLog.SubtrialRespRT] = deal([]);
        [trialLog.Accuracy] = deal([]);
        
        % Ask if using scanner trigger
        inp = input('\nStart with fMRI pulse? (y/n) ===== ','s');
        while ~strcmp(inp,'y') && ~strcmp(inp,'n')
            inp = input('\nInvalid entry! \nStart with fMRI trigger? (y/n)','s');
        end
        useScanner = strcmp(inp,'y');
        
        % Suppress keyboard input to MATLAB command window
        ListenChar(2);
        
        % Store trigger mode in params for logging
        params.triggerMode = useScanner;
        
        try
            % Initialize window and stimuli
            disp('Initializing window...');
            
            [window, windowRect, xCenter, yCenter, apertureTexture, apertureRect] = initializeWindow(params);
            disp('Window initialized successfully.');
        catch e
            disp(['Error in initializeWindow: ' e.message]);
            rethrow(e);
        end
        
        try
            % Generate experimental design if not already present or complete
            disp('Checking experimental design...');
            
            % Check if design field exists and has the minimal initialization from get_params.m
            if ~isfield(params, 'design')
                disp('Design field not found. Generating experimental design...');
                params.design = generateRunDesign(params);
                disp('Design generated successfully.');
            elseif isempty(params.design)
                disp('Design field is empty. Generating experimental design...');
                params.design = generateRunDesign(params);
                disp('Design generated successfully.');
            else
                % Check if design has only the basic fields from get_params.m
                designFields = fieldnames(params.design);
                basicFields = {'trialTypes', 'randomSeed'};
                
                % If design only has the basic fields or is missing required fields, regenerate it
                if length(designFields) <= length(basicFields) || ...
                   ~isfield(params.design, 'trialConditions') || ...
                   ~isfield(params.design, 'trialWedges') || ...
                   ~isfield(params.design, 'trialAngles')
                    
                    disp('Design has only basic initialization. Generating complete design...');
                    
                    % Store the original random seed if it exists
                    if isfield(params.design, 'randomSeed')
                        originalSeed = params.design.randomSeed;
                        tempDesign = params.design; % Save other fields
                        params.design = generateRunDesign(params);
                        params.design.randomSeed = originalSeed; % Restore original seed
                        
                        % Restore any other fields that might have been in the original design
                        otherFields = setdiff(fieldnames(tempDesign), fieldnames(params.design));
                        for i = 1:length(otherFields)
                            params.design.(otherFields{i}) = tempDesign.(otherFields{i});
                        end
                    else
                        params.design = generateRunDesign(params);
                    end
                    
                    disp('Design generated successfully.');
                else
                    disp('Using pre-existing complete design.');
                    
                    % Validate the design dimensions
                    if length(params.design.trialConditions) ~= params.timing.totalTrials
                        disp('Design trial count does not match current parameters. Regenerating...');
                        params.design = generateRunDesign(params);
                        disp('Design regenerated successfully.');
                    end
                end
            end
        catch e
            disp(['Error in generateRunDesign: ' e.message]);
            disp('Error details:');
            disp(getReport(e, 'extended'));
            rethrow(e);
        end
        
        % Display experiment start message
        disp(['Starting experiment for participant: ', params.metadata.observer, ', Run: ', num2str(params.metadata.runNum)]);
        disp(['Run type: ', params.metadata.runType]);
        disp(['Total trials: ', num2str(params.timing.totalTrials), ', Blocks: ', num2str(params.timing.numBlocks)]);
        disp(['Estimated duration: ', num2str(params.timing.runDuration/60), ' minutes']);
        
        % Display instructions based on run type
        Screen('TextSize', window, params.display.textSize);
        if strcmp(params.metadata.runType, 'passive')
            instructText = ['Passive viewing run\n\n' ...
                'Please:\n' ...
                '- Keep your eyes fixed on the central dot\n' ...
                '- Keep your eyes open\n' ...
                '- No need to attend to anything in particular\n\n' ...
                'The run will begin shortly...'];
        else
            instructText = ['Attention task run\n\n' ...
                'Please:\n' ...
                '- Keep your eyes fixed on the central dot\n' ...
                '- Keep your eyes open\n' ...
                '- Press 1 if dots move more horizontally\n' ...
                '- Press 2 if dots move more vertically\n\n' ...
                'The run will begin shortly...'];
        end
        
        % Draw instructions
        DrawFormattedText(window, instructText, 'center', 'center', [1 1 1]);
        %drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColor);
        Screen('Flip', window);
        WaitSecs(3);
        
        % Wait for trigger or manual start
        if useScanner
            % Wait for scanner trigger
            try
                disp('Waiting for scanner trigger...');
                runOnset = waitForTrigger(true);  % Pass true to indicate we're waiting for scanner trigger
                %disp('Trigger received.');
            catch e
                disp(['Error in waitForTrigger: ' e.message]);
                % Save workspace for debugging
                save(fullfile(params.metadata.dataFolder, [params.metadata.observer '_run' num2str(params.metadata.runNum) '_error_workspace.mat']));
                disp(['############## Workspace saved to: ' fullfile(params.metadata.dataFolder, [params.metadata.observer '_run' num2str(params.metadata.runNum) '_error_workspace.mat']) ' ##############']);
                rethrow(e);
            end
        else
            % Manual start
            Screen('FillRect', window, params.display.backgroundColor);
            DrawFormattedText(window, 'Press any key to start...', 'center', 'center', [1 1 1]);
            drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColor);
            Screen('Flip', window);
            
            % Wait for key press
            runOnset = waitForTrigger(false);  % Pass false to indicate we're waiting for spacebar
        end
        
        % Run the experiment blocks
        results = struct();
        results.startTime = runOnset;
        
        % Initial blank period
        Screen('FillRect', window, params.display.backgroundColor);
        drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColor);
        Screen('Flip', window);
        WaitSecs(params.timing.initialBlankDuration);
        
        % Run each block
        for block = 1:params.timing.numBlocks
            % Run the block
            try
                disp(['Running block ' num2str(block) '...']);
                
                % Call runBlock with the correct argument order
                runBlock(window, block, params, apertureTexture, apertureRect, xCenter, yCenter, runOnset);
                
                disp(['Block ' num2str(block) ' completed successfully.']);
            catch e
                disp(['Error in runBlock for block ' num2str(block) ': ' e.message]);
                rethrow(e);
            end
            
            % Inter-block blank period (except after the last block)
            if block < params.timing.numBlocks
                Screen('FillRect', window, params.display.backgroundColor);
                drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColor);
                Screen('Flip', window);
                WaitSecs(params.timing.blockBlankDuration);
            end
        end
        
        % Final blank period
        Screen('FillRect', window, params.display.backgroundColor);
        drawFixationDot(window, xCenter, yCenter, params.task.fixationDotSize, params.task.fixationDotColor);
        Screen('Flip', window);
        WaitSecs(params.timing.endBlankDuration);
        
        % Record completion time
        results.completionTime = now;
        results.duration = GetSecs - runOnset;
        
        % Display performance summary for attention runs
        if strcmp(params.metadata.runType, 'attention')
            % Calculate overall accuracy from trialLog
            if ~isempty(trialLog)
                % Extract accuracy values
                accuracyValues = {trialLog.Accuracy};
                
                % Count different response types
                correctCount = sum(strcmp(accuracyValues, 'correct'));
                incorrectCount = sum(strcmp(accuracyValues, 'incorrect'));
                missCount = sum(strcmp(accuracyValues, 'miss'));
                
                % Calculate total valid responses (excluding NaN/empty)
                totalResponses = sum(~cellfun(@isempty, accuracyValues) & ~strcmp(accuracyValues, 'NaN'));
                
                % Calculate percentages
                if totalResponses > 0
                    correctPct = (correctCount / totalResponses) * 100;
                    incorrectPct = (incorrectCount / totalResponses) * 100;
                    missPct = (missCount / totalResponses) * 100;
                else
                    correctPct = 0;
                    incorrectPct = 0;
                    missPct = 0;
                end
                
                % Calculate block-by-block accuracy
                blockAccuracies = zeros(1, params.timing.numBlocks);
                for b = 1:params.timing.numBlocks
                    blockEntries = [trialLog.Block] == b;
                    blockAccValues = {trialLog(blockEntries).Accuracy};
                    blockCorrect = sum(strcmp(blockAccValues, 'correct'));
                    blockTotal = sum(~cellfun(@isempty, blockAccValues) & ~strcmp(blockAccValues, 'NaN'));
                    
                    if blockTotal > 0
                        blockAccuracies(b) = blockCorrect / blockTotal;
                    else
                        blockAccuracies(b) = 0;
                    end
                end
                
                % Display summary
                summaryText = sprintf(['Run complete!\n\n' ...
                                      'Performance Summary:\n' ...
                                      'Correct: %.1f%% (%d trials)\n' ...
                                      'Incorrect: %.1f%% (%d trials)\n' ...
                                      'Missed: %.1f%% (%d trials)\n\n'], ...
                                      correctPct, correctCount, ...
                                      incorrectPct, incorrectCount, ...
                                      missPct, missCount);
                
                % Add block-by-block accuracy
                summaryText = [summaryText 'Block Accuracy:\n'];
                for b = 1:params.timing.numBlocks
                    summaryText = [summaryText sprintf('Block %d: %.1f%%\n', b, blockAccuracies(b) * 100)];
                end
                
                % Display the summary
                Screen('FillRect', window, params.display.backgroundColor);
                DrawFormattedText(window, summaryText, 'center', 'center', [1 1 1]);
                Screen('Flip', window);
                WaitSecs(5);
            else
                % If trialLog is empty, just show completion message
                Screen('FillRect', window, params.display.backgroundColor);
                DrawFormattedText(window, 'Run complete!', 'center', 'center', [1 1 1]);
                Screen('Flip', window);
                WaitSecs(2);
            end
        else
            % For passive runs, just show completion message
            Screen('FillRect', window, params.display.backgroundColor);
            DrawFormattedText(window, 'Run complete!', 'center', 'center', [1 1 1]);
            Screen('Flip', window);
            WaitSecs(2);
        end
        
        % Close the window
        sca;
        
        % Save results
        try
            disp('Saving experiment data...');
            saveExperimentData(params, results, trialLog);
            disp('Data saved successfully.');
        catch e
            disp(['Error in saveExperimentData: ' e.message]);
            rethrow(e);
        end
        
        % Restore figure visibility
        set(0, 'DefaultFigureVisible', 'on');
        
        % Restore normal keyboard input
        ListenChar(0);
        
    catch e
        % Close window in case of error
        sca;
        
        % Restore figure visibility
        set(0, 'DefaultFigureVisible', 'on');
        
        % Restore normal keyboard input
        ListenChar(0);
        
        % Check if this was a user-initiated termination (ESC pressed)
        isUserTerminated = strcmp(e.identifier, 'UserTerminated:EscapePressed');
        
        if isUserTerminated
            disp('############## Saving interrupted run data... ##############');
        else
            disp(['############## Error during experiment: ' e.message ' ##############']);
        end
        
        % Save partial data (trial log collected so far)
        try
            % Create results structure with interruption info
            results = struct();
            results.interrupted = true;
            results.interruptionTime = now;
            results.interruptionReason = e.message;
            if exist('runOnset', 'var')
                results.partialDuration = GetSecs - runOnset;
            end
            
            % Save using modified filename to indicate interruption
            saveInterruptedData(params, results, trialLog, isUserTerminated);
        catch saveError
            disp(['############## Error saving interrupted data: ' saveError.message ' ##############']);
        end
        
        % Also save full workspace for debugging
        try
            if isUserTerminated
                errorWorkspaceFile = fullfile(params.metadata.dataFolder, [params.metadata.observer '_run' num2str(params.metadata.runNum) '_interrupted_workspace.mat']);
            else
                errorWorkspaceFile = fullfile(params.metadata.dataFolder, [params.metadata.observer '_run' num2str(params.metadata.runNum) '_error_workspace.mat']);
            end
            save(errorWorkspaceFile);
            disp(['############## Workspace saved to: ' errorWorkspaceFile ' ##############']);
        catch
            disp('############## Could not save workspace ##############');
        end
        
        % Only rethrow if it was an actual error (not user termination)
        if ~isUserTerminated
            rethrow(e);
        else
            disp('############## Run interrupted by user - partial data saved ##############');
        end
    end
end

function saveInterruptedData(params, results, trialLog, isUserTerminated)
    % Save interrupted/partial run data similar to saveExperimentData
    % but with different naming to indicate it was not completed
    
    try
        % Create participant folder if it doesn't exist
        if ~exist(params.metadata.dataFolder, 'dir')
            mkdir(params.metadata.dataFolder);
        end
        
        % Create TR-specific folder
        trFolder = sprintf('TR%.4f', params.timing.TR);
        trPath = fullfile(params.metadata.dataFolder, trFolder);
        if ~exist(trPath, 'dir')
            mkdir(trPath);
        end
        
        % Create run-specific folder with INTERRUPTED suffix
        if isUserTerminated
            runFolder = sprintf('run-%02d_%s_TR%.1f_INTERRUPTED', params.metadata.runNum, params.metadata.runType, params.timing.TR);
        else
            runFolder = sprintf('run-%02d_%s_TR%.1f_ERROR', params.metadata.runNum, params.metadata.runType, params.timing.TR);
        end
        runPath = fullfile(trPath, runFolder);
        if ~exist(runPath, 'dir')
            mkdir(runPath);
        end
        
        % Save data
        dataFile = fullfile(runPath, [params.metadata.observer '_run' num2str(params.metadata.runNum) '_data_PARTIAL.mat']);
        save(dataFile, 'params', 'results', 'trialLog');
        disp(['############## Partial data saved to: ' dataFile ' ##############']);
        
        % Save trial log as CSV for easier analysis
        if ~isempty(trialLog)
            csvFile = fullfile(runPath, [params.metadata.observer '_run' num2str(params.metadata.runNum) '_trialLog_PARTIAL.csv']);
            trialTable = struct2table(trialLog);
            writetable(trialTable, csvFile);
            disp(['############## Partial trial log saved to: ' csvFile ' ##############']);
        end
        
    catch e
        disp(['Error saving interrupted data: ' e.message]);
        rethrow(e);
    end
end
