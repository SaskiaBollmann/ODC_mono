function [window, windowRect, xCenter, yCenter, apertureTexture, apertureRect] = initializeWindow(params, display)
    % initializeWindow - Initialize PTB window with standard settings
    % 
    % Usage:
    % [window, windowRect, xCenter, yCenter, apertureTexture, apertureRect] = initializeWindow(params, display)
    %
    % Inputs:
    %   params - Parameter structure containing observer and circleRadius
    %   display - Display parameters structure
    %
    % Outputs:
    %   window - Window pointer
    %   windowRect - Window rectangle
    %   xCenter, yCenter - Screen center coordinates
    %   apertureTexture - Aperture texture
    %   apertureRect - Aperture rectangle
    
    % If display not provided, use params.display
    if nargin < 2
        display = params.display;
    end
    
    % Clear all previous PTB screens and configurations
    sca;  % Screen('CloseAll')
    clear Screen;  % Clear cached Screen functions
    clear PsychImaging;  % Clear PsychImaging configuration
    AssertOpenGL;  % Make sure OpenGL is still available
    
    % Initialize Psychtoolbox
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', display.skipSyncTests);
    %HideCursor;
    
    % Initialize OpenGL
    InitializeMatlabOpenGL();
    
    % Initialize PsychImaging pipeline
    PsychImaging('PrepareConfiguration');
    
    % Add basic imaging pipeline tasks
    PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
    
    % Check if imaging_mode is specified
    if isfield(display, 'imaging_mode') && ~isempty(display.imaging_mode)
        for i = 1:length(display.imaging_mode)
            PsychImaging('AddTask', display.imaging_mode{i}{:});
        end
    end
    
    % Use screenNumber if available, otherwise use screenID
    screenToUse = display.screenNumber;
    if ~isfield(display, 'screenNumber') || isempty(display.screenNumber)
        screenToUse = display.screenID;
    end
    
    % Open window with appropriate settings
    if isfield(display, 'window_rect') && ~isempty(display.window_rect)
        [window, windowRect] = PsychImaging('OpenWindow', screenToUse, ...
            display.backgroundColor, display.window_rect, [], [], [], display.multisample);
    else
        [window, windowRect] = PsychImaging('OpenWindow', screenToUse, ...
            display.backgroundColor, [], [], [], [], display.multisample);
    end
        
    % Set priority for better timing
    %priorityLevel = MaxPriority(window, 'WaitBlanking');
    Priority(1);
    
    % Get center coordinates
    [screenXCenter, screenYCenter] = RectCenter(windowRect);
    
    % Use custom center if available, otherwise use screen center
    if isfield(params.display, 'customCenter') && ~isempty(params.display.customCenter)
        xCenter = params.display.customCenter(1);
        yCenter = params.display.customCenter(2);
        disp(['Using custom center: [' num2str(xCenter) ', ' num2str(yCenter) ']']);
    else
        xCenter = screenXCenter;
        yCenter = screenYCenter;
        disp(['Using screen center: [' num2str(xCenter) ', ' num2str(yCenter) ']']);
    end
    
    % Set blending for smooth dots
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Generate Gaussian aperture texture
    [apertureTexture, apertureRect] = generateAperture(window, xCenter, yCenter, params.stimulus.circleRadius);
end 