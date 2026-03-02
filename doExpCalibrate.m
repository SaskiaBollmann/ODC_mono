% doExpCalibrate.m: Calibration suite for experiment setup (v4)
%
% PREREQUISITE: Run preExp.m first to configure timing parameters
%
% CALIBRATION STEPS:
%   1. Load timing parameters from preExp
%   2. Enter participant info (ID, red lens eye)
%   3. Visual space mapping (aperture position/size)
%   4. Anaglyph color calibration (red/green separation)
%   5. Coherence threshold calibration (QUEST staircase)
%   6. Save prepared workspace for experiment execution
%
% v4 FEATURES:
%   - Calibration is reusable for ALL runs (passive and attention)
%   - Visual space/anaglyph can be loaded from existing files
%   - Run type and number selected later in doExp.m

% Clear workspace and screen
sca; close all; clear all;

% Add the current script's folder and all subfolders to the MATLAB path
scriptPath = fileparts(which(mfilename('fullpath')));
addpath(genpath(scriptPath));
disp(['############## Added to path: ' scriptPath ' and all subfolders ##############']);

% Store the original directory to return to it later if needed
originalDir = pwd;

% Change to the script directory to ensure we can find all functions
cd(scriptPath);
disp(['############## Changed to script directory: ' scriptPath ' ##############']);

%% STEP 1: Load Timing Parameters (REQUIRED)
% Check for saved timing parameters
paramsFolder = fullfile(scriptPath, 'params');
if ~exist(paramsFolder, 'dir')
    error('No params folder found. Please run preExp.m first to configure timing parameters.');
end

% Look for timing parameter files
timingFiles = dir(fullfile(paramsFolder, 'timing_*.mat'));
if isempty(timingFiles)
    error('No timing parameter files found. Please run preExp.m first to configure timing parameters.');
end

% If multiple files exist, let user choose
if length(timingFiles) > 1
    % Sort by date (newest first)
    [~, idx] = sort([timingFiles.datenum], 'descend');
    timingFiles = timingFiles(idx);
    
    % Create list for user selection
    fileNames = {timingFiles.name};
    fileDescriptions = cell(size(fileNames));
    for i = 1:length(fileNames)
        fileDescriptions{i} = sprintf('%s (created: %s)', fileNames{i}, timingFiles(i).date);
    end
    
    [selection, ok] = listdlg('PromptString', 'Select timing parameter file:', ...
                              'SelectionMode', 'single', ...
                              'ListString', fileDescriptions, ...
                              'ListSize', [400, 200]);
    
    if ~ok || isempty(selection)
        disp('############## Calibration cancelled by user ##############');
        return;
    end
    
    selectedFile = fullfile(paramsFolder, timingFiles(selection).name);
else
    selectedFile = fullfile(paramsFolder, timingFiles(1).name);
end

% Load timing parameters
disp(['############## Loading timing parameters from: ' selectedFile ' ##############']);
loadedData = load(selectedFile);
if ~isfield(loadedData, 'params')
    error('Invalid timing parameter file format. Please run preExp.m to create valid parameters.');
end

params = loadedData.params;

% Verify required timing parameters are present
requiredFields = {'trialDuration', 'numSubTrials', 'subTrialDuration', 'totalTrials', 'TR'};
missingFields = {};
for i = 1:length(requiredFields)
    if ~isfield(params.timing, requiredFields{i}) || isempty(params.timing.(requiredFields{i}))
        missingFields{end+1} = requiredFields{i};
    end
end

if ~isempty(missingFields)
    error('Missing required timing parameters: %s. Please run preExp.m first.', strjoin(missingFields, ', '));
end

disp('############## Timing parameters loaded successfully ##############');
disp(['Trial Duration: ' num2str(params.timing.trialDuration) ' s']);
disp(['Number of Subtrials: ' num2str(params.timing.numSubTrials)]);
disp(['Subtrial Duration: ' num2str(params.timing.subTrialDuration) ' s']);
disp(['TR: ' num2str(params.timing.TR) ' s']);

%% STEP 2: Get Participant Information
% NOTE: Run number and run type are no longer collected here
% - Run number is auto-assigned in doExp.m
% - Run type (passive/attention) is selected in doExp.m at execution time
prompt = {'Subject number:', ...
          'Which eye has the RED lens? (L/R):'};
dlg_title = params.metadata.exName;
num_lines = 1;
def = {'test', 'L'};
answer = inputdlg(prompt, dlg_title, num_lines, def, 'on');

if isempty(answer)
    disp('############## Calibration cancelled by user ##############');
    return;
end

params.metadata.observer = answer{1};
params.metadata.redLensEye = upper(answer{2});
% Run type and run number will be assigned at experiment execution time
params.metadata.runType = [];
params.metadata.runNum = [];

% Input validation
if ~ismember(params.metadata.redLensEye, {'L', 'R'})
    error('Red lens eye must be specified as L or R');
end

%% STEP 3: Create Data Folder Structure
expDataFolder = fullfile(scriptPath, 'data', params.metadata.exName);
if ~exist(expDataFolder, 'dir')
    mkdir(expDataFolder);
    disp(['############## Created experiment data folder: ' expDataFolder ' ##############']);
else
    disp(['############## Located experiment data folder: ' expDataFolder ' ##############']);
end

participantFolder = fullfile(expDataFolder, params.metadata.observer);
if ~exist(participantFolder, 'dir')
    mkdir(participantFolder);
    disp(['############## Created participant folder: ' participantFolder ' ##############']);
else
    disp(['############## Located participant folder: ' participantFolder ' ##############']);
end
params.metadata.dataFolder = participantFolder;

%% STEP 4: Visual Space Mapping Calibration
disp('############## CALIBRATION STEP 1: Visual Space Mapping ##############');
% Look for any visual space file for this participant (visualSpaceMap_ppt.mat or visualSpaceMap_ppt_YYYYMMDD_HHMMSS.mat)
visualSpaceFiles = dir(fullfile(params.metadata.dataFolder, ['visualSpaceMap_' params.metadata.observer '*.mat']));
if ~isempty(visualSpaceFiles)
    % Sort by date modified, most recent first
    [~, idx] = sort([visualSpaceFiles.datenum], 'descend');
    visualSpaceFiles = visualSpaceFiles(idx);
    visualSpaceMapFile = fullfile(visualSpaceFiles(1).folder, visualSpaceFiles(1).name);
    mapSettings = load(visualSpaceMapFile);
    
    if isfield(mapSettings, 'settings') && ...
       isfield(mapSettings.settings, 'circleX') && ...
       isfield(mapSettings.settings, 'circleY') && ...
       isfield(mapSettings.settings, 'circleRadius')
        
        % Ask if user wants to reuse existing mapping
        mapAnswer = questdlg(['Visual space mapping file found (' visualSpaceFiles(1).name '). Do you want to use it or recalibrate?'], ...
            'Visual Space Mapping', 'Use Existing', 'Recalibrate', 'Use Existing');
        
        if strcmp(mapAnswer, 'Use Existing')
            % Store the mapping values in params
            params.display.customCenter = [mapSettings.settings.circleX, mapSettings.settings.circleY];
            params.stimulus.circleRadius = mapSettings.settings.circleRadius;
            params.calibration.visualSpace.circleX = mapSettings.settings.circleX;
            params.calibration.visualSpace.circleY = mapSettings.settings.circleY;
            params.calibration.visualSpace.circleRadius = mapSettings.settings.circleRadius;
            
            disp('############## Loaded existing visual space mapping ##############');
            disp(['Custom center: [' num2str(params.display.customCenter(1)) ', ' num2str(params.display.customCenter(2)) ']']);
            disp(['Circle radius: ' num2str(params.stimulus.circleRadius)]);
        else
            % Run visual space mapping (saves with new date/time in filename)
            params = visualSpaceMapper(params);
        end
    else
        disp('############## Invalid visual space mapping file format ##############');
        params = visualSpaceMapper(params);
    end
else
    % No file in expected location - offer to calibrate, load existing, or use defaults
    mapOptions = {'Calibrate Now', 'Load Existing File', 'Use Defaults'};
    [mapChoice, ~] = listdlg('PromptString', 'No visual space mapping found for this participant:', ...
                              'SelectionMode', 'single', ...
                              'ListString', mapOptions, ...
                              'ListSize', [300, 100], ...
                              'Name', 'Visual Space Mapping');
    
    if isempty(mapChoice)
        mapChoice = 3; % Default to use defaults if cancelled
    end
    
    switch mapChoice
        case 1 % Calibrate Now (saves as visualSpaceMap_ppt_YYYYMMDD_HHMMSS.mat)
            params = visualSpaceMapper(params);
            
        case 2 % Load Existing File
            [loadFile, loadPath] = uigetfile('visualSpaceMap_*.mat', ...
                'Select existing visual space mapping file', ...
                fullfile(scriptPath, 'data'));
            
            if ~isequal(loadFile, 0)
                loadedMap = load(fullfile(loadPath, loadFile));
                if isfield(loadedMap, 'settings') && ...
                   isfield(loadedMap.settings, 'circleX') && ...
                   isfield(loadedMap.settings, 'circleY') && ...
                   isfield(loadedMap.settings, 'circleRadius')
                    
                    % Store the mapping values in params
                    params.display.customCenter = [loadedMap.settings.circleX, loadedMap.settings.circleY];
                    params.stimulus.circleRadius = loadedMap.settings.circleRadius;
                    params.calibration.visualSpace.circleX = loadedMap.settings.circleX;
                    params.calibration.visualSpace.circleY = loadedMap.settings.circleY;
                    params.calibration.visualSpace.circleRadius = loadedMap.settings.circleRadius;
                    
                    % Copy to this participant's folder with date/time so we don't overwrite
                    ts = datestr(now, 'yyyymmdd_HHMMSS');
                    destFile = fullfile(params.metadata.dataFolder, ['visualSpaceMap_' params.metadata.observer '_' ts '.mat']);
                    copyfile(fullfile(loadPath, loadFile), destFile);
                    
                    disp(['############## Loaded visual space mapping from: ' fullfile(loadPath, loadFile) ' ##############']);
                    disp(['Custom center: [' num2str(params.display.customCenter(1)) ', ' num2str(params.display.customCenter(2)) ']']);
                    disp(['Circle radius: ' num2str(params.stimulus.circleRadius)]);
                    disp(['############## Copied to: ' destFile ' ##############']);
                else
                    warning('Selected file has invalid format. Using defaults.');
                    params.display.customCenter = [];
                end
            else
                disp('############## No file selected. Using default visual space settings ##############');
                params.display.customCenter = [];
            end
            
        case 3 % Use Defaults
            disp('############## Using default visual space settings ##############');
            params.display.customCenter = [];
    end
end

%% STEP 5: Anaglyph Color Calibration
disp('############## CALIBRATION STEP 2: Anaglyph Color Calibration ##############');
% Look for any anaglyph calibration for this participant ([ppt]_calibration.mat or [ppt]_calibration_YYYYMMDD_HHMMSS.mat)
anaglyphFiles = dir(fullfile(participantFolder, [params.metadata.observer '_calibration*.mat']));
if ~isempty(anaglyphFiles)
    % Sort by date modified, most recent first
    [~, idx] = sort([anaglyphFiles.datenum], 'descend');
    anaglyphFiles = anaglyphFiles(idx);
    calibFile = fullfile(anaglyphFiles(1).folder, anaglyphFiles(1).name);
    calibData = load(calibFile);
    
    if isfield(calibData, 'settings')
        % Ask if user wants to reuse existing calibration
        calibAnswer = questdlg(['Anaglyph calibration file found (' anaglyphFiles(1).name '). Do you want to use it or recalibrate?'], ...
            'Anaglyph Calibration', 'Use Existing', 'Recalibrate', 'Use Existing');
        
        if strcmp(calibAnswer, 'Use Existing')
            params.calibration.anaglyphs.redColor = calibData.settings.redColor;
            params.calibration.anaglyphs.greenColor = calibData.settings.greenColor;
            
            disp('############## Loaded anaglyph calibration parameters ##############');
            disp(['Red color: [' num2str(params.calibration.anaglyphs.redColor) ']']);
            disp(['Green color: [' num2str(params.calibration.anaglyphs.greenColor) ']']);
        else
            % Run calibration (saves with new date/time in filename)
            disp('############## Starting anaglyph calibration procedure ##############');
            calibrationParams = calibrateAnaglyphs(params);
            params.calibration = calibrationParams;
            disp('############## Anaglyph calibration completed ##############');
        end
    else
        warning('Calibration file format is incorrect. Running calibration.');
        disp('############## Starting anaglyph calibration procedure ##############');
        calibrationParams = calibrateAnaglyphs(params);
        params.calibration = calibrationParams;
        disp('############## Anaglyph calibration completed ##############');
    end
else
    % No file in expected location - offer to calibrate, load existing, or use defaults
    anaglyphOptions = {'Calibrate Now', 'Load Existing File', 'Use Defaults'};
    [anaglyphChoice, ~] = listdlg('PromptString', 'No anaglyph calibration found for this participant:', ...
                                   'SelectionMode', 'single', ...
                                   'ListString', anaglyphOptions, ...
                                   'ListSize', [300, 100], ...
                                   'Name', 'Anaglyph Calibration');
    
    if isempty(anaglyphChoice)
        anaglyphChoice = 3; % Default to use defaults if cancelled
    end
    
    switch anaglyphChoice
        case 1 % Calibrate Now (saves as [ppt]_calibration_YYYYMMDD_HHMMSS.mat)
            disp('############## Starting anaglyph calibration procedure ##############');
            calibrationParams = calibrateAnaglyphs(params);
            params.calibration = calibrationParams;
            disp('############## Anaglyph calibration completed ##############');
            
        case 2 % Load Existing File
            [loadFile, loadPath] = uigetfile('*_calibration*.mat', ...
                'Select existing anaglyph calibration file', ...
                fullfile(scriptPath, 'data'));
            
            if ~isequal(loadFile, 0)
                loadedCalib = load(fullfile(loadPath, loadFile));
                if isfield(loadedCalib, 'settings') && ...
                   isfield(loadedCalib.settings, 'redColor') && ...
                   isfield(loadedCalib.settings, 'greenColor')
                    
                    % Store the calibration values in params
                    params.calibration.anaglyphs.redColor = loadedCalib.settings.redColor;
                    params.calibration.anaglyphs.greenColor = loadedCalib.settings.greenColor;
                    
                    % Copy to this participant's folder with date/time so we don't overwrite
                    ts = datestr(now, 'yyyymmdd_HHMMSS');
                    destFile = fullfile(participantFolder, [params.metadata.observer '_calibration_' ts '.mat']);
                    copyfile(fullfile(loadPath, loadFile), destFile);
                    
                    disp(['############## Loaded anaglyph calibration from: ' fullfile(loadPath, loadFile) ' ##############']);
                    disp(['Red color: [' num2str(params.calibration.anaglyphs.redColor) ']']);
                    disp(['Green color: [' num2str(params.calibration.anaglyphs.greenColor) ']']);
                    disp(['############## Copied to: ' destFile ' ##############']);
                else
                    warning('Selected file has invalid format. Using defaults.');
                    params.calibration.anaglyphs.redColor = params.stimulus.defaultRedColor;
                    params.calibration.anaglyphs.greenColor = params.stimulus.defaultGreenColor;
                end
            else
                disp('############## No file selected. Using default anaglyph colors ##############');
                params.calibration.anaglyphs.redColor = params.stimulus.defaultRedColor;
                params.calibration.anaglyphs.greenColor = params.stimulus.defaultGreenColor;
            end
            
        case 3 % Use Defaults
            disp('############## Using default anaglyph colors ##############');
            params.calibration.anaglyphs.redColor = params.stimulus.defaultRedColor;
            params.calibration.anaglyphs.greenColor = params.stimulus.defaultGreenColor;
    end
end

%% STEP 6: Coherence Threshold Calibration
disp('############## CALIBRATION STEP 3: Coherence Threshold Calibration ##############');
coherenceCalibFile = fullfile(participantFolder, [params.metadata.observer '_coherence_calibration_TR' ...
                             sprintf('%.4f', params.timing.TR) 's_SubtrialDur' num2str(params.timing.subTrialDuration) 's.mat']);

if exist(coherenceCalibFile, 'file')
    % Ask if user wants to reuse existing calibration
    calibAnswer = questdlg(['Coherence calibration file found for TR=' num2str(params.timing.TR) '. Do you want to use it or recalibrate?'], ...
        'Coherence Calibration', 'Use Existing', 'Recalibrate', 'Use Existing');
    
    if strcmp(calibAnswer, 'Use Existing')
        % Load calibration file
        calibData = load(coherenceCalibFile);
        if isfield(calibData, 'thresholds')
            params.stimulus.coherenceRedSingle = calibData.thresholds.single;
            params.stimulus.coherenceGreenSingle = calibData.thresholds.single;
            params.calibration.coherence.single = calibData.thresholds.single;
            
            disp('############## Loaded coherence calibration parameters ##############');
            disp(['Single task coherence: ' num2str(calibData.thresholds.single)]);
        else
            warning('Coherence calibration file format is incorrect. Using default values.');
            params.calibration.coherence.single = params.stimulus.coherenceRedSingle;
        end
    else
        % Run coherence calibration
        disp('############## Starting coherence calibration procedure ##############');
        [thresholds, calibData] = calibrateCoherence(params);
        
        % Store the coherence values in params
        params.stimulus.coherenceRedSingle = thresholds.single;
        params.stimulus.coherenceGreenSingle = thresholds.single;
        params.calibration.coherence.single = thresholds.single;
        
        % Save calibration data
        save(coherenceCalibFile, 'thresholds', 'calibData');
        
        disp('############## Coherence calibration completed and saved ##############');
        disp(['Single task coherence: ' num2str(thresholds.single)]);
    end
else
    % Ask if user wants to calibrate
    calibAnswer = questdlg('No coherence calibration file found. Do you want to calibrate?', ...
        'Coherence Calibration', 'Yes', 'No (Use Defaults)', 'Yes');
    
    if strcmp(calibAnswer, 'Yes')
        disp('############## Starting coherence calibration procedure ##############');
        [thresholds, calibData] = calibrateCoherence(params);
        
        % Store the coherence values in params
        params.stimulus.coherenceRedSingle = thresholds.single;
        params.stimulus.coherenceGreenSingle = thresholds.single;
        params.calibration.coherence.single = thresholds.single;
        
        % Save calibration data
        save(coherenceCalibFile, 'thresholds', 'calibData');
        
        disp('############## Coherence calibration completed and saved ##############');
        disp(['Single task coherence: ' num2str(thresholds.single)]);
    else
        disp('############## Using default coherence settings ##############');
        params.calibration.coherence.single = params.stimulus.coherenceRedSingle;
        disp(['Default coherence: ' num2str(params.stimulus.coherenceRedSingle)]);
    end
end

%% STEP 7: Save Calibrated Workspace (NO EXPERIMENT EXECUTION)
% In v4, workspace is saved by participant + timing (same detail as coherence calibration)
% so that different TR/subtrial-duration setups do not overwrite each other.
% Naming: [ppt]_prepared_workspace_TR[X]s_SubtrialDur[Y]s.mat
workspaceFile = fullfile(participantFolder, [params.metadata.observer '_prepared_workspace_TR' ...
    sprintf('%.4f', params.timing.TR) 's_SubtrialDur' num2str(params.timing.subTrialDuration) 's.mat']);

% Create a summary of calibration settings
calibSummary = struct();
calibSummary.observer = params.metadata.observer;
calibSummary.redLensEye = params.metadata.redLensEye;

% Visual space calibration info
if isfield(params.calibration, 'visualSpace') && ~isempty(params.calibration.visualSpace.circleX)
    calibSummary.visualSpaceCalibrated = true;
    calibSummary.customCenter = params.display.customCenter;
    calibSummary.circleRadius = params.stimulus.circleRadius;
else
    calibSummary.visualSpaceCalibrated = false;
end

% Anaglyph calibration info
if isfield(params.calibration, 'anaglyphs') && ~isempty(params.calibration.anaglyphs.redColor)
    calibSummary.anaglyphsCalibrated = true;
    calibSummary.redColor = params.calibration.anaglyphs.redColor;
    calibSummary.greenColor = params.calibration.anaglyphs.greenColor;
else
    calibSummary.anaglyphsCalibrated = false;
end

% Timing parameters info
calibSummary.timingSource = selectedFile;
calibSummary.trialDuration = params.timing.trialDuration;
calibSummary.numSubTrials = params.timing.numSubTrials;
calibSummary.totalTrials = params.timing.totalTrials;
calibSummary.runDuration = params.timing.runDuration;

% Coherence calibration info
calibSummary.coherenceCalibrated = isfield(params.calibration, 'coherence') && ~isempty(params.calibration.coherence.single);
if calibSummary.coherenceCalibrated
    calibSummary.singleCoherence = params.calibration.coherence.single;
end

% Save both the full params and the summary
save(workspaceFile, 'params', 'calibSummary');

% Display completion message
disp('############## ALL CALIBRATIONS COMPLETE ##############');
disp(['Workspace saved to: ' workspaceFile]);
disp('############## CALIBRATION SUMMARY ##############');
disp(['Participant: ' calibSummary.observer]);
disp(['Red lens eye: ' calibSummary.redLensEye]);
disp(['Visual space calibrated: ' num2str(calibSummary.visualSpaceCalibrated)]);
disp(['Anaglyph calibrated: ' num2str(calibSummary.anaglyphsCalibrated)]);
disp(['Coherence calibrated: ' num2str(calibSummary.coherenceCalibrated)]);
disp(['Trial duration: ' num2str(calibSummary.trialDuration) ' s']);
disp(['Subtrials: ' num2str(calibSummary.numSubTrials)]);
disp('############################################');
disp('');
disp('CALIBRATION PHASE COMPLETE');
disp('Next: Run doExp.m to execute the experiment');
disp('      You will select run type (passive/attention) there');
disp('      Run numbers will be auto-assigned to prevent overwrites');
disp(['      Workspace: ' workspaceFile]);

% Return to original directory
cd(originalDir); 