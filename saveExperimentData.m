function saveExperimentData(params, results, trialLog)
    try
        % Create participant folder if it doesn't exist
        if ~exist(params.metadata.dataFolder, 'dir')
            mkdir(params.metadata.dataFolder);
            disp(['############## Created data folder: ' params.metadata.dataFolder ' ##############']);
        end
        
        % Create TR-specific folder
        trFolder = sprintf('TR%.4f', params.timing.TR);
        trPath = fullfile(params.metadata.dataFolder, trFolder);
        if ~exist(trPath, 'dir')
            mkdir(trPath);
            disp(['############## Created folder for TR: ' trFolder ' ##############']);
        else
            disp(['############## Located folder for TR: ' trFolder ' ##############']);
        end
        
        % Create run-specific folder
        runFolder = sprintf('run-%02d_%s_TR%.1f', params.metadata.runNum, params.metadata.runType, params.timing.TR);
        runPath = fullfile(trPath, runFolder);
        if ~exist(runPath, 'dir')
            mkdir(runPath);
            disp(['############## Created run folder: ' runFolder ' ##############']);
        else
            disp(['############## Located run folder: ' runFolder ' ##############']);
        end
        
        % Save data
        dataFile = fullfile(runPath, [params.metadata.observer '_run' num2str(params.metadata.runNum) '_data.mat']);
        save(dataFile, 'params', 'results', 'trialLog');
        disp(['############## Data saved to: ' dataFile ' ##############']);
        
        % Save trial log as CSV for easier analysis
        if ~isempty(trialLog)
            csvFile = fullfile(runPath, [params.metadata.observer '_run' num2str(params.metadata.runNum) '_trialLog.csv']);
            
            % Convert trialLog to table
            trialTable = struct2table(trialLog);
            
            % Write table to CSV
            writetable(trialTable, csvFile);
            disp(['############## Trial log saved to: ' csvFile ' ##############']);
        end
        
    catch e
        disp(['Error saving data: ' e.message]);
        rethrow(e);
    end
end 