% preExp.m: Script to run pre-experiment setup and configuration
% This script handles timing parameter configuration and saves settings
% for later use in the main experiment.

% Clear workspace and screen
sca; close all; clear all;

% Add the current script's folder and all subfolders to the MATLAB path
scriptPath = fileparts(which(mfilename('fullpath')));
addpath(genpath(scriptPath));
disp(['############## Added to path: ' scriptPath ' and all subfolders ##############']);

%% Initialize experiment parameters
params.metadata.exName = '2025_nextgen_odc_v4';  % Updated to v4

% Get experiment parameters
params = get_params(params);

% Create params folder at the script level if it doesn't exist
paramsFolder = fullfile(scriptPath, 'params');
if ~exist(paramsFolder, 'dir')
    mkdir(paramsFolder);
    disp(['############## Created params folder: ' paramsFolder ' ##############']);
else
    disp(['############## Located params folder: ' paramsFolder ' ##############']);
end

%% CONFIGURATION SECTION: Timing Parameters
% Run timing configuration GUI
disp('############## Starting timing parameter configuration ##############');
params = configureTimingParamsGUI(params);

% Check if timing parameters were configured
if isempty(params.timing.trialDuration) || isempty(params.timing.totalTrials)
    disp('############## Timing configuration was not completed ##############');
    return;
end

% Save timing parameters to a .mat file with TR and duration in the filename
try
    % Format TR and duration for filename
    trStr = sprintf('%.4f', params.timing.TR);
    durationStr = sprintf('%.4f', params.timing.runDuration/60); % in minutes
    
    % Generate filename with timestamp
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    filename = fullfile(paramsFolder, ['timing_TR' trStr '_' durationStr 'min_' timestamp '.mat']);
    
    % Save the entire params structure
    save(filename, 'params');
    
    disp(['############## Timing parameters saved to: ' filename ' ##############']);
    disp(['Trial Duration: ' num2str(params.timing.trialDuration) ' s']);
    disp(['Number of Subtrials: ' num2str(params.timing.numSubTrials)]);
    disp(['Total Trials: ' num2str(params.timing.totalTrials) ' (Single Block Design)']);
    disp(['Total Run Duration: ' num2str(params.timing.runDuration/60) ' minutes']);
    disp(['Total TRs: ' num2str(params.timing.totalTRs)]);
catch e
    disp(['############## Failed to save parameters: ' e.message ' ##############']);
end

disp('############## Pre-experiment setup completed ##############');
disp('############## Next step: Run doExpCalibrate.m to perform calibrations ##############'); 
disp('############## NOTE: Calibration and experiment execution are now separate steps ##############'); 