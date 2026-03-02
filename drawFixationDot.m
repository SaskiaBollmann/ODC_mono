function drawFixationDot(window, xCenter, yCenter, sizePixels, color)
    % drawFixationDot.m: Draws a central fixation dot on the screen
    
    Screen('DrawDots', window, [xCenter; yCenter], sizePixels * 2, color', [], 2);
    Screen('DrawDots', window, [xCenter; yCenter], 2 * 2, [0 0 0], [], 2);
end 