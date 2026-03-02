function dots = generateDots(numDots, radius, coherenceLevel, motionDirection, speed, jitter, xCenter, yCenter)
    % Determine number of dots per quadrant
    baseDots = floor(numDots / 4);
    quadrants = repmat(baseDots, 1, 4);
    remainder = numDots - 4 * baseDots;
    % Distribute any remaining dots among the first few quadrants
    for k = 1:remainder
        quadrants(k) = quadrants(k) + 1;
    end

    % Preallocate arrays for positions
    xPos = [];
    yPos = [];

    % Quadrant I: theta from 0 to pi/2
    theta = rand(1, quadrants(1)) * (pi/2);
    r = sqrt(rand(1, quadrants(1))) * radius;
    xPos = [xPos, xCenter + r .* cos(theta)];
    yPos = [yPos, yCenter + r .* sin(theta)];
    
    % Quadrant II: theta from pi/2 to pi
    theta = (pi/2) + rand(1, quadrants(2)) * (pi/2);
    r = sqrt(rand(1, quadrants(2))) * radius;
    xPos = [xPos, xCenter + r .* cos(theta)];
    yPos = [yPos, yCenter + r .* sin(theta)];
    
    % Quadrant III: theta from pi to 3pi/2
    theta = pi + rand(1, quadrants(3)) * (pi/2);
    r = sqrt(rand(1, quadrants(3))) * radius;
    xPos = [xPos, xCenter + r .* cos(theta)];
    yPos = [yPos, yCenter + r .* sin(theta)];
    
    % Quadrant IV: theta from 3pi/2 to 2pi
    theta = (3*pi/2) + rand(1, quadrants(4)) * (pi/2);
    r = sqrt(rand(1, quadrants(4))) * radius;
    xPos = [xPos, xCenter + r .* cos(theta)];
    yPos = [yPos, yCenter + r .* sin(theta)];
    
    % Shuffle dot order so quadrant grouping isn't obvious
    idx = randperm(numDots);
    xPos = xPos(idx);
    yPos = yPos(idx);
    
    % Determine which dots are coherent
    coherentIdx = rand(1, numDots) < coherenceLevel;
    
    % Initialize velocity arrays
    dx = zeros(1, numDots);
    dy = zeros(1, numDots);
    
    % Coherent motion: fixed direction but with jittered speed
    % Each coherent dot's speed becomes speed + jitter*(rand-0.5)
    speedCoherent = speed + jitter * (rand(1, sum(coherentIdx)) - 0.5);
    dx(coherentIdx) = speedCoherent .* cosd(motionDirection);
    dy(coherentIdx) = speedCoherent .* sind(motionDirection);
    
    % Incoherent motion: random directions with speed scaling plus jitter
    numIncoherent = sum(~coherentIdx);
    randomDirections = rand(1, numIncoherent) * 2 * pi;
    dx(~coherentIdx) = speed * cos(randomDirections) + jitter * (rand(1, numIncoherent) - 0.5);
    dy(~coherentIdx) = speed * sin(randomDirections) + jitter * (rand(1, numIncoherent) - 0.5);
    
    % Store properties in structure
    dots.x = xPos;
    dots.y = yPos;
    dots.dx = dx;
    dots.dy = dy;
end 