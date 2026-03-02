function params = get_params(userParams)
    % get_params: Returns a complete parameter structure for the experiment
    %
    % Input:
    %   userParams - Optional structure with user-defined parameters that will
    %                override defaults
    %
    % Output:
    %   params - Complete parameter structure with all experiment settings
    
    % Initialize empty params structure if not provided
    if nargin < 1
        userParams = struct();
    end
    
    % Create default parameter structure
    params = struct();
    
    % ======== Metadata parameters ========
    params.metadata = struct();
    params.metadata.exName = '2025_nextgen_odc_v4';  % Updated to v4
    params.metadata.observer = 'test';
    params.metadata.runNum = 0;
    params.metadata.runType = 'passive';
    params.metadata.redLensEye = 'L';
    params.metadata.dataFolder = '';             % Will be set in doExp.m
    
    % ======== Display parameters ========
    params.display = struct();
    params.display.skipSyncTests = 1;
    params.display.screenNumber = 0; %comment this line out for scanner
    params.display.backgroundColor = [0.5 0.5 0.5]; % Grey background
    params.display.textSize = 45;
    params.display.customCenter = [];  % Default is empty, will use screen center
    
    % Additional display parameters
    params.display.screenID = max(Screen('Screens'));
    params.display.multisample = 8;
    params.display.window_rect = [0 0 1920 1080];  % Smaller window for testing
    params.display.imaging_mode = [];
    params.display.screen_width_m = 0.30;  % Approximate for laptop/desktop monitor
    
    % ======== Stimulus parameters ========
    params.stimulus = struct();
    params.stimulus.circleRadius = 450;          % Radius of circular aperture (in pixels)
    params.stimulus.numDotsPerColor = 400;       % Number of dots per color (red/green)
    params.stimulus.dotRadius = 10;              % Radius of each dot (in pixels)
    params.stimulus.speed = 60;                  % Speed in pixels per second
    params.stimulus.jitter = 10;                 % Speed jitter in pixels per second
    params.stimulus.coherenceRedSingle = 0.7;    % Default coherence for red dots in single condition
    params.stimulus.coherenceGreenSingle = 0.7;  % Default coherence for green dots in single condition
    params.stimulus.defaultRedColor = [1 0.55 0.55];    % Default red color
    params.stimulus.defaultGreenColor = [0.4 0.9 0];    % Default green color
    
    % Wedge ranges for coherent motion
    % Vertical-most wedges
    params.stimulus.verticalWedgeRanges = [55 80; 100 125; 235 260; 280 305];
    % Horizontal-most wedges
    params.stimulus.horizontalWedgeRanges = [10 35; 145 170; 190 215; 325 350];
    
    % ======== Timing parameters ========
    params.timing = struct();
    params.timing.TR = 4.5;                          % TR duration in seconds
    params.timing.initialBlankDuration = 3 * 4.5;    % Initial blank duration (3 TRs)
    params.timing.blockBlankDuration = 2 * 4.5;      % Blank duration between blocks (2 TRs)
    params.timing.endBlankDuration = 3 * 4.5;        % Final blank duration (3 TRs)
    params.timing.ITI = 0;                           % Inter-trial interval (default: 0); was 1TR
    
    % Additional timing parameters (will be set by configureTimingParamsGUI)
    params.timing.trialDuration = [];                % Trial duration in seconds
    params.timing.numSubTrials = [];                 % Number of subtrials per trial
    params.timing.subTrialDuration = [];             % Duration of each subtrial
    params.timing.totalTrials = [];                  % Total number of trials
    params.timing.numTrialsPerBlock = [];            % Number of trials per block
    params.timing.numBlocks = [];                    % Number of blocks
    params.timing.totalTRs = [];                     % Total number of TRs
    params.timing.runDuration = [];                  % Total run duration in seconds
    
    % ======== Task parameters ========
    params.task = struct();
    params.task.fixationDotColorDefault = [1 1 0];   % Default yellow fixation
    params.task.fixationDotColor = [1 1 0];          % Will be updated for attention runs
    params.task.fixationDotSize = 7;                 % Diameter in pixels
    params.task.targetColor = '';                    % Will be filled based on run type
    
    % ======== Design parameters ========
    params.design = struct();
    params.design.trialTypes = {'red', 'green'};      
    params.design.randomSeed = 12345;                % Random seed for reproducibility
    
    % ======== Calibration parameters ========
    params.calibration = struct();
    
    % Visual space mapping calibration
    params.calibration.visualSpace = struct();
    params.calibration.visualSpace.circleX = [];     % Will be filled during visual space mapping
    params.calibration.visualSpace.circleY = [];     % Will be filled during visual space mapping
    params.calibration.visualSpace.circleRadius = params.stimulus.circleRadius; % Initialize with stimulus default
    
    % Anaglyph calibration
    params.calibration.anaglyphs = struct();
    params.calibration.anaglyphs.redColor = [];    % Will be filled during anaglyph calibration
    params.calibration.anaglyphs.greenColor = [];  % Will be filled during anaglyph calibration
    
    % Coherence calibration
    params.calibration.coherence = struct();
    params.calibration.coherence.single = [];      % Will be filled during coherence calibration
    
    % ======== Experiment control flags ========
    params.skipCalibration = false;              % Default to not skip calibration
    
    % ======== Override with user-provided parameters ========
    % Recursively merge userParams into params
    params = mergeStructs(params, userParams);
end

function result = mergeStructs(default, override)
    % Helper function to recursively merge structures
    result = default;
    
    % Return if override is empty
    if isempty(override) || ~isstruct(override)
        return;
    end
    
    fields = fieldnames(override);
    
    for i = 1:length(fields)
        field = fields{i};
        
        % If both are structures, merge recursively
        if isfield(default, field) && isstruct(default.(field)) && isstruct(override.(field))
            result.(field) = mergeStructs(default.(field), override.(field));
        else
            % Otherwise just override
            result.(field) = override.(field);
        end
    end
end 