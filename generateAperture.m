function [apertureTexture, apertureRect] = generateAperture(window, xCenter, yCenter, radius)
    % Define Gaussian ring parameters
    gaussDim = radius * 1.05;
    gaussSigma = gaussDim / 15;
    innerRadius = radius * 0.8;
    outerRadius = radius * 1.05;

    % Create a grid for Gaussian computation
    [x, y] = meshgrid(-gaussDim:gaussDim, -gaussDim:gaussDim);
    distanceFromCenter = sqrt(x.^2 + y.^2);

    % Create Gaussian ring mask
    gaussRing = exp(-((distanceFromCenter - innerRadius).^2) / (2 * gaussSigma^2));
    gaussRing(distanceFromCenter < innerRadius) = 1; % Fully transparent inside inner radius
    gaussRing(distanceFromCenter > outerRadius) = 0; % Fully opaque outside outer radius

    % Rescale values between inner and outer radii
    transitionRegion = distanceFromCenter >= innerRadius & distanceFromCenter <= outerRadius;
    gaussRing(transitionRegion) = (gaussRing(transitionRegion) - min(gaussRing(transitionRegion))) ...
                                  / (max(gaussRing(transitionRegion)) - min(gaussRing(transitionRegion)));

    % Invert transparency scale
    gaussRing = 1 - gaussRing;

    % Create texture with only alpha modulation
    maskTexture = ones(size(gaussRing, 1), size(gaussRing, 2), 4);
    maskTexture(:, :, 4) = gaussRing; % Only set alpha channel, leave RGB as 0

    % Create texture and return it
    apertureTexture = Screen('MakeTexture', window, maskTexture);
    apertureRect = CenterRectOnPointd([0 0 size(maskTexture, 2) size(maskTexture, 1)], xCenter, yCenter);
end 