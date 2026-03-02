function angle = selectWedgeAngle(category, verticalRanges, horizontalRanges)
    % selectWedgeAngle: Returns a random angle from the wedge ranges based on category.
    % It ensures that the generated angle is at least 3 degrees different
    % from the previously chosen angle for that category.
    
    % Use persistent variables to remember the last angle for each category
    persistent lastVertical lastHorizontal
    if isempty(lastVertical)
        lastVertical = NaN;
    end
    if isempty(lastHorizontal)
        lastHorizontal = NaN;
    end

    % Select the appropriate ranges and last angle based on category.
    switch lower(category)
        case 'vertical'
            ranges = verticalRanges;
            lastAngle = lastVertical;
        case 'horizontal'
            ranges = horizontalRanges;
            lastAngle = lastHorizontal;
        otherwise
            error('Category must be "vertical" or "horizontal".');
    end

    % Sample repeatedly until the new candidate is at least 3 degrees different.
    valid = false;
    maxAttempts = 100;
    attempt = 0;
    candidate = NaN;
    while ~valid && attempt < maxAttempts
        idx = randi(size(ranges, 1));
        currentRange = ranges(idx, :);
        candidate = currentRange(1) + (currentRange(2) - currentRange(1)) * rand;
        % If there's no previous angle or the difference is >= 3, accept candidate.
        if isnan(lastAngle) || abs(candidate - lastAngle) >= 3
            valid = true;
        end
        attempt = attempt + 1;
    end

    % If we never get a valid candidate, we still return the candidate (or you could force a minimum difference).
    angle = candidate;

    % Save the selected angle in the appropriate persistent variable.
    switch lower(category)
        case 'vertical'
            lastVertical = angle;
        case 'horizontal'
            lastHorizontal = angle;
    end
end 