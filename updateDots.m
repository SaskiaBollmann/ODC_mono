function dots = updateDots(dots, radius, xCenter, yCenter, dt, speed, jitter)
    % Update positions using dt for frame-rate independence:
    dots.x = dots.x + dots.dx * dt;
    dots.y = dots.y + dots.dy * dt;

    % Calculate squared distances from the center
    distancesFromCenterSqrd = (dots.x - xCenter).^2 + (dots.y - yCenter).^2;

    % Identify dots that have moved outside the circular aperture
    outsideApertureIdx = distancesFromCenterSqrd > radius^2;

    if any(outsideApertureIdx)
        % Generate new positions within the circle for replaced dots:
        thetaNew = rand(1, sum(outsideApertureIdx)) * 2 * pi;
        rNew = sqrt(rand(1, sum(outsideApertureIdx))) * radius;
        dots.x(outsideApertureIdx) = xCenter + rNew .* cos(thetaNew);
        dots.y(outsideApertureIdx) = yCenter + rNew .* sin(thetaNew);
        
        % Reinitialize velocities with the proper speed and jitter:
        randomDirectionsNew = rand(1, sum(outsideApertureIdx)) * 2 * pi;
        dots.dx(outsideApertureIdx) = speed * cos(randomDirectionsNew) + jitter * (rand(1, sum(outsideApertureIdx)) - 0.5);
        dots.dy(outsideApertureIdx) = speed * sin(randomDirectionsNew) + jitter * (rand(1, sum(outsideApertureIdx)) - 0.5);
    end
end 