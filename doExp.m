% doExp.m: Main entry point for experiment execution (v4)
%
% USAGE: Run this script after completing calibration via doExpCalibrate.m
%
% v4 FEATURES:
%   - Run options panel: Select run type (passive/attention) and trial
%     ordering (random/interleaved/blocked)
%   - Auto-incrementing run numbers: Detects existing runs and suggests next
%   - Manual override: Option to specify a custom run number if needed
%   - Overwrite protection: Warns before overwriting existing data
%   - Partial data recovery: Saves workspace on crash/interrupt
%
% WORKFLOW:
%   1. Select prepared workspace file (*_prepared_workspace*.mat, includes TR/SubtrialDur in name)
%   2. Choose run type and trial ordering
%   3. Confirm or override run number
%   4. Run experiment

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

% V3 Workflow: Load prepared workspace, auto-assign run number
disp('############## ODC Experiment v4 - Experiment Execution ##############');
disp('############## Note: Calibration must be completed first via doExpCalibrate.m ##############');

% Ask user to select prepared workspace
disp('############## Please select a prepared workspace file ##############');
[filename, pathname] = uigetfile('*_prepared_workspace*.mat', 'Select prepared workspace file', ...
                                 fullfile(scriptPath, 'data'));

if isequal(filename, 0) || isequal(pathname, 0)
    disp('User canceled workspace selection.');
    cd(originalDir);
    return;
end

% Load the selected file
fullFilePath = fullfile(pathname, filename);
try
    % Add the directory of the workspace file to the path
    addpath(pathname);
    disp(['############## Added workspace directory to path: ' pathname ' ##############']);
    
    loadedData = load(fullFilePath);
    if ~isfield(loadedData, 'params')
        error('Selected file does not contain valid experiment parameters.');
    end
    
    params = loadedData.params;
    
    % Validate that this is a properly prepared workspace
    if ~isfield(params, 'calibration')
        error('Selected workspace does not contain calibration data. Please run doExpCalibrate.m first.');
    end
    
    if ~isfield(params, 'timing')
        error('Selected workspace does not contain timing parameters. Please run preExp.m and doExpCalibrate.m first.');
    end
    
    % Extract participant info
    observer = params.metadata.observer;
    
    disp(['############## Loaded workspace from: ' fullFilePath ' ##############']);
    disp(['############## Participant: ' observer ' ##############']);
    
    %% SELECT RUN OPTIONS
    % All run options are now selected at execution time via a single dialog
    runOptions = selectRunOptions(observer);
    
    if isempty(runOptions)
        disp('############## Run cancelled by user ##############');
        cd(originalDir);
        return;
    end
    
    % Apply selected options to params
    runType = runOptions.runType;
    params.metadata.runType = runType;
    params.design.trialOrdering = runOptions.trialOrdering;
    
    disp(['############## Run Type: ' runType ' ##############']);
    disp(['############## Trial Ordering: ' runOptions.trialOrdering ' ##############']);
    
    %% AUTO-DETECT EXISTING RUNS
    % Look for ALL existing run data folders (regardless of run type) to determine next run number
    % Run numbering is global across passive and attention runs
    trFolder = sprintf('TR%.4f', params.timing.TR);
    trPath = fullfile(pathname, trFolder);
    
    existingRuns = [];
    existingRunInfo = {};  % Store run type info for display
    if exist(trPath, 'dir')
        % Look for ALL run folders (any run type)
        runFolders = dir(fullfile(trPath, 'run-*_*_TR*'));
        
        if ~isempty(runFolders)
            % Extract run numbers and types from folder names
            for i = 1:length(runFolders)
                folderName = runFolders(i).name;
                % Parse run number from folder name (format: run-XX_type_TR)
                tokens = regexp(folderName, 'run-(\d+)_(\w+)_TR', 'tokens');
                if ~isempty(tokens)
                    runNum = str2double(tokens{1}{1});
                    runTypeFound = tokens{1}{2};
                    existingRuns(end+1) = runNum;
                    existingRunInfo{end+1} = sprintf('%d (%s)', runNum, runTypeFound);
                end
            end
            [existingRuns, sortIdx] = sort(existingRuns);
            existingRunInfo = existingRunInfo(sortIdx);
        end
    end
    
    % Determine next run number (global across all run types)
    if isempty(existingRuns)
        nextRunNum = 1;
    else
        nextRunNum = max(existingRuns) + 1;
    end
    
    %% DISPLAY RUN INFORMATION AND CONFIRM
    disp('');
    disp('============================================================');
    disp('                    RUN INFORMATION');
    disp('============================================================');
    disp(['Participant:    ' observer]);
    disp(['Run Type:       ' runType]);
    disp(['TR:             ' num2str(params.timing.TR) ' s']);
    disp(['Trial Duration: ' num2str(params.timing.trialDuration) ' s']);
    disp(['Total Trials:   ' num2str(params.timing.totalTrials)]);
    disp(['Run Duration:   ' sprintf('%.1f', params.timing.runDuration/60) ' minutes']);
    disp('------------------------------------------------------------');
    
    if isempty(existingRuns)
        disp('Existing runs:  None');
    else
        disp(['Existing runs:  ' strjoin(existingRunInfo, ', ')]);
    end
    
    disp(['NEXT RUN:       ' num2str(nextRunNum) ' (' runType ')']);
    disp('============================================================');
    disp('');
    
    % Confirm with user - allow override of run number
    [finalRunNum, confirmed] = confirmRunNumber(observer, runType, nextRunNum, existingRuns);
    
    if ~confirmed
        disp('############## Run cancelled by user ##############');
        cd(originalDir);
        return;
    end
    
    % Check if user selected an existing run number (potential overwrite)
    if ismember(finalRunNum, existingRuns)
        overwriteChoice = questdlg(sprintf('Run %d already exists! Data will be OVERWRITTEN.\n\nAre you sure?', finalRunNum), ...
                                   'Overwrite Warning', ...
                                   'Yes, overwrite', 'No, cancel', 'No, cancel');
        if ~strcmp(overwriteChoice, 'Yes, overwrite')
            disp('############## Run cancelled - overwrite not confirmed ##############');
            cd(originalDir);
            return;
        end
        disp(['############## WARNING: Overwriting existing Run ' num2str(finalRunNum) ' ##############']);
    end
    
    % Assign the run number to params
    params.metadata.runNum = finalRunNum;
    disp(['############## Starting Run ' num2str(finalRunNum) ' ##############']);
    
    %% RUN THE EXPERIMENT
    % Disable figure creation during experiment
    set(0, 'DefaultFigureVisible', 'off');
    
    % Find the full path to runExperiment.m
    runExpFullPath = fullfile(scriptPath, 'runExperiment.m');
    
    % Check if the file exists
    if ~exist(runExpFullPath, 'file')
        error(['Could not find runExperiment.m at expected location: ' runExpFullPath]);
    end
    
    disp(['############## Found runExperiment.m at: ' runExpFullPath ' ##############']);
    
    % Make sure we're in the script directory
    cd(scriptPath);
    
    try
        % Set debug breakpoint in case of error
        dbstop if error
        
        runExperiment(params);
        disp('############## Experiment completed successfully ##############');
        disp(['############## Run ' num2str(finalRunNum) ' data saved ##############']);
        
        % Clear debug breakpoint
        dbclear if error
    catch e
        disp(['############## Error during experiment: ' e.message ' ##############']);
        disp('############## Error stack trace: ##############');
        disp(getReport(e, 'extended'));
        
        % Save workspace on error for debugging
        errorWorkspaceFile = fullfile(pathname, [observer '_run' num2str(finalRunNum) '_error_workspace.mat']);
        save(errorWorkspaceFile, 'params');
        disp(['############## Error workspace saved to: ' errorWorkspaceFile ' ##############']);
        
        % Clear debug breakpoint
        dbclear if error
        
        % Restore figure visibility
        set(0, 'DefaultFigureVisible', 'on');
        
        rethrow(e);
    end
    
    % Restore figure visibility
    set(0, 'DefaultFigureVisible', 'on');
    
catch e
    disp(['############## Error: ' e.message ' ##############']);
    disp('############## Error stack trace: ##############');
    disp(getReport(e, 'extended'));
    
    % Restore figure visibility
    set(0, 'DefaultFigureVisible', 'on');
end

% Return to the original directory
cd(originalDir);
disp(['############## Returned to original directory: ' originalDir ' ##############']);


function runOptions = selectRunOptions(observer)
    % selectRunOptions - Display a dialog for selecting all run options
    %
    % Returns a structure with:
    %   runOptions.runType - 'passive' or 'attention'
    %   runOptions.trialOrdering - 'random', 'interleaved', etc.
    %
    % Returns empty if user cancels
    
    runOptions = [];
    
    % Larger, cleaner dialog
    figWidth = 520;
    figHeight = 420;
    screenSize = get(0, 'ScreenSize');
    figX = (screenSize(3) - figWidth) / 2;
    figY = (screenSize(4) - figHeight) / 2;
    
    % Create figure for options
    fig = figure('Name', sprintf('Run Options - %s', observer), ...
                 'NumberTitle', 'off', ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Position', [figX, figY, figWidth, figHeight], ...
                 'Resize', 'off', ...
                 'Color', [0.95, 0.95, 0.95], ...
                 'CloseRequestFcn', @cancelCallback);
    
    % Store selection state
    data.confirmed = false;
    data.runType = 'passive';
    data.trialOrdering = 'random';
    guidata(fig, data);
    
    % === HEADER ===
    uicontrol('Parent', fig, ...
              'Style', 'text', ...
              'String', sprintf('Configure Run for: %s', observer), ...
              'FontSize', 16, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.95, 0.95, 0.95], ...
              'Position', [20, 365, 480, 40], ...
              'HorizontalAlignment', 'center');
    
    % === RUN TYPE PANEL ===
    runTypePanel = uipanel('Parent', fig, ...
                           'Title', '  Run Type  ', ...
                           'FontSize', 12, ...
                           'FontWeight', 'bold', ...
                           'BackgroundColor', [1, 1, 1], ...
                           'Position', [0.04, 0.52, 0.92, 0.32]);
    
    % Run type button group inside panel
    runTypeGroup = uibuttongroup('Parent', runTypePanel, ...
                                  'Position', [0.02, 0.05, 0.96, 0.9], ...
                                  'BorderType', 'none', ...
                                  'BackgroundColor', [1, 1, 1], ...
                                  'SelectionChangedFcn', @runTypeCallback);
    
    uicontrol('Parent', runTypeGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Passive - no response required', ...
              'FontSize', 11, ...
              'BackgroundColor', [1, 1, 1], ...
              'Position', [20, 55, 400, 28], ...
              'Tag', 'passive');
    
    uicontrol('Parent', runTypeGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Attention - respond to motion direction', ...
              'FontSize', 11, ...
              'BackgroundColor', [1, 1, 1], ...
              'Position', [20, 15, 400, 28], ...
              'Tag', 'attention');
    
    % === TRIAL ORDERING PANEL ===
    orderPanel = uipanel('Parent', fig, ...
                         'Title', '  Trial Ordering  ', ...
                         'FontSize', 12, ...
                         'FontWeight', 'bold', ...
                         'BackgroundColor', [1, 1, 1], ...
                         'Position', [0.04, 0.17, 0.92, 0.32]);
    
    % Trial ordering button group inside panel
    orderGroup = uibuttongroup('Parent', orderPanel, ...
                               'Position', [0.02, 0.05, 0.96, 0.9], ...
                               'BorderType', 'none', ...
                               'BackgroundColor', [1, 1, 1], ...
                               'SelectionChangedFcn', @orderCallback);
    
    uicontrol('Parent', orderGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Random - fully randomized red/green order', ...
              'FontSize', 11, ...
              'BackgroundColor', [1, 1, 1], ...
              'Position', [20, 75, 420, 28], ...
              'Tag', 'random');
    
    uicontrol('Parent', orderGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Interleaved - alternating R-G-R-G with random start', ...
              'FontSize', 11, ...
              'BackgroundColor', [1, 1, 1], ...
              'Position', [20, 42, 420, 28], ...
              'Tag', 'interleaved');
    
    uicontrol('Parent', orderGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Blocked - all red then green (or vice versa)', ...
              'FontSize', 11, ...
              'BackgroundColor', [1, 1, 1], ...
              'Position', [20, 9, 420, 28], ...
              'Tag', 'blocked');
    
    % === BUTTONS ===
    uicontrol('Parent', fig, ...
              'Style', 'pushbutton', ...
              'String', 'START RUN', ...
              'FontSize', 13, ...
              'FontWeight', 'bold', ...
              'Position', [100, 25, 140, 45], ...
              'BackgroundColor', [0.3, 0.7, 0.3], ...
              'ForegroundColor', [1, 1, 1], ...
              'Callback', @confirmCallback);
    
    uicontrol('Parent', fig, ...
              'Style', 'pushbutton', ...
              'String', 'Cancel', ...
              'FontSize', 12, ...
              'Position', [280, 25, 140, 45], ...
              'BackgroundColor', [0.85, 0.85, 0.85], ...
              'Callback', @cancelCallback);
    
    % Wait for user interaction
    uiwait(fig);
    
    % Get final data if figure still exists
    if ishandle(fig)
        data = guidata(fig);
        if data.confirmed
            runOptions = struct();
            runOptions.runType = data.runType;
            runOptions.trialOrdering = data.trialOrdering;
        end
        delete(fig);
    end
    
    % Nested callback functions
    function runTypeCallback(~, event)
        data = guidata(fig);
        data.runType = event.NewValue.Tag;
        guidata(fig, data);
    end
    
    function orderCallback(~, event)
        data = guidata(fig);
        data.trialOrdering = event.NewValue.Tag;
        guidata(fig, data);
    end
    
    function confirmCallback(~, ~)
        data = guidata(fig);
        data.confirmed = true;
        guidata(fig, data);
        uiresume(fig);
    end
    
    function cancelCallback(~, ~)
        data = guidata(fig);
        data.confirmed = false;
        guidata(fig, data);
        uiresume(fig);
    end
end


function [runNum, confirmed] = confirmRunNumber(observer, runType, suggestedRunNum, existingRuns)
    % confirmRunNumber - Dialog to confirm or override the run number
    %
    % Returns:
    %   runNum - the final run number (suggested or user-entered)
    %   confirmed - true if user confirmed, false if cancelled
    
    runNum = suggestedRunNum;
    confirmed = false;
    
    % Dialog size and positioning
    figWidth = 450;
    figHeight = 300;
    screenSize = get(0, 'ScreenSize');
    figX = (screenSize(3) - figWidth) / 2;
    figY = (screenSize(4) - figHeight) / 2;
    
    % Create dialog figure
    fig = figure('Name', 'Confirm Run Number', ...
                 'NumberTitle', 'off', ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Position', [figX, figY, figWidth, figHeight], ...
                 'Resize', 'off', ...
                 'Color', [0.95, 0.95, 0.95], ...
                 'CloseRequestFcn', @cancelCallback);
    
    % Store state
    data.confirmed = false;
    data.runNum = suggestedRunNum;
    data.useCustom = false;
    guidata(fig, data);
    
    % === HEADER ===
    uicontrol('Parent', fig, ...
              'Style', 'text', ...
              'String', sprintf('Confirm Run for: %s', observer), ...
              'FontSize', 14, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.95, 0.95, 0.95], ...
              'Position', [20, 255, 410, 30], ...
              'HorizontalAlignment', 'center');
    
    uicontrol('Parent', fig, ...
              'Style', 'text', ...
              'String', sprintf('Run type: %s', runType), ...
              'FontSize', 11, ...
              'BackgroundColor', [0.95, 0.95, 0.95], ...
              'Position', [20, 230, 410, 22], ...
              'HorizontalAlignment', 'center');
    
    % === EXISTING RUNS INFO ===
    if isempty(existingRuns)
        existingText = 'No existing runs found';
    else
        existingText = sprintf('Existing runs: %s', mat2str(existingRuns));
    end
    uicontrol('Parent', fig, ...
              'Style', 'text', ...
              'String', existingText, ...
              'FontSize', 10, ...
              'ForegroundColor', [0.4, 0.4, 0.4], ...
              'BackgroundColor', [0.95, 0.95, 0.95], ...
              'Position', [20, 205, 410, 20], ...
              'HorizontalAlignment', 'center');
    
    % === RUN NUMBER SELECTION ===
    runPanel = uipanel('Parent', fig, ...
                       'Title', '  Run Number  ', ...
                       'FontSize', 11, ...
                       'FontWeight', 'bold', ...
                       'BackgroundColor', [1, 1, 1], ...
                       'Position', [0.05, 0.32, 0.9, 0.38]);
    
    % Button group for selection
    btnGroup = uibuttongroup('Parent', runPanel, ...
                             'Position', [0.02, 0.05, 0.96, 0.9], ...
                             'BorderType', 'none', ...
                             'BackgroundColor', [1, 1, 1], ...
                             'SelectionChangedFcn', @selectionCallback);
    
    % Auto option (use next available)
    uicontrol('Parent', btnGroup, ...
              'Style', 'radiobutton', ...
              'String', sprintf('Use next available:  %d', suggestedRunNum), ...
              'FontSize', 12, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [1, 1, 1], ...
              'Position', [15, 50, 350, 28], ...
              'Tag', 'auto', ...
              'Value', 1);
    
    % Custom option (specify manually)
    uicontrol('Parent', btnGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Specify run number:', ...
              'FontSize', 12, ...
              'BackgroundColor', [1, 1, 1], ...
              'Position', [15, 15, 180, 28], ...
              'Tag', 'custom');
    
    % Text field for custom number
    customEdit = uicontrol('Parent', runPanel, ...
              'Style', 'edit', ...
              'String', num2str(suggestedRunNum), ...
              'FontSize', 12, ...
              'Enable', 'off', ...
              'Position', [210, 12, 60, 28], ...
              'HorizontalAlignment', 'center', ...
              'Callback', @editCallback);
    
    % === BUTTONS ===
    uicontrol('Parent', fig, ...
              'Style', 'pushbutton', ...
              'String', 'START', ...
              'FontSize', 13, ...
              'FontWeight', 'bold', ...
              'Position', [80, 20, 130, 45], ...
              'BackgroundColor', [0.3, 0.7, 0.3], ...
              'ForegroundColor', [1, 1, 1], ...
              'Callback', @confirmCallback);
    
    uicontrol('Parent', fig, ...
              'Style', 'pushbutton', ...
              'String', 'Cancel', ...
              'FontSize', 12, ...
              'Position', [240, 20, 130, 45], ...
              'BackgroundColor', [0.85, 0.85, 0.85], ...
              'Callback', @cancelCallback);
    
    % Wait for user
    uiwait(fig);
    
    % Get result
    if ishandle(fig)
        data = guidata(fig);
        confirmed = data.confirmed;
        runNum = data.runNum;
        delete(fig);
    end
    
    % Nested callbacks
    function selectionCallback(~, event)
        data = guidata(fig);
        if strcmp(event.NewValue.Tag, 'custom')
            data.useCustom = true;
            set(customEdit, 'Enable', 'on');
            % Parse custom value
            customVal = str2double(get(customEdit, 'String'));
            if ~isnan(customVal) && customVal > 0
                data.runNum = round(customVal);
            end
        else
            data.useCustom = false;
            set(customEdit, 'Enable', 'off');
            data.runNum = suggestedRunNum;
        end
        guidata(fig, data);
    end
    
    function editCallback(src, ~)
        data = guidata(fig);
        customVal = str2double(get(src, 'String'));
        if ~isnan(customVal) && customVal > 0
            data.runNum = round(customVal);
            set(src, 'String', num2str(data.runNum));  % Show rounded value
        else
            % Reset to suggested if invalid
            set(src, 'String', num2str(suggestedRunNum));
            data.runNum = suggestedRunNum;
        end
        guidata(fig, data);
    end
    
    function confirmCallback(~, ~)
        data = guidata(fig);
        % Final validation of custom value if in custom mode
        if data.useCustom
            customVal = str2double(get(customEdit, 'String'));
            if ~isnan(customVal) && customVal > 0
                data.runNum = round(customVal);
            else
                errordlg('Please enter a valid run number (positive integer)', 'Invalid Input');
                return;
            end
        end
        data.confirmed = true;
        guidata(fig, data);
        uiresume(fig);
    end
    
    function cancelCallback(~, ~)
        data = guidata(fig);
        data.confirmed = false;
        guidata(fig, data);
        uiresume(fig);
    end
end
