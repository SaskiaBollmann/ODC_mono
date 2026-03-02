function triggerTime = waitForTrigger(useScanner)
    % waitForTrigger - Wait for either scanner trigger (5) or spacebar
    % Usage: triggerTime = waitForTrigger(useScanner)
    %
    % Input:
    %   useScanner - boolean, true if waiting for scanner trigger, false for spacebar
    %
    % Output:
    %   triggerTime - GetSecs timestamp when trigger received
    
    % Setup key checking
    KbName('UnifyKeyNames');
    triggerKey = KbName('5%');  % Scanner trigger
    spaceKey = KbName('space');  % Alternative trigger for testing
    
    % % Display waiting message
    % if useScanner
    %     fprintf('\nWaiting for scanner trigger (5)...\n');
    % else
    %     fprintf('\nPress spacebar to start...\n');
    % end
    
    % Wait for key
    while true
        [keyIsDown, keyTime, keyCode] = KbCheck();
        if keyIsDown
            if useScanner && keyCode(triggerKey)
                triggerTime = keyTime;
                fprintf('Scanner trigger received!\n');
                break;
            elseif ~useScanner && keyCode(spaceKey)
                triggerTime = keyTime;
                fprintf('Spacebar pressed!\n');
                break;
            end
        end
        WaitSecs(0.001);  % Prevent CPU hogging
    end
    
    end 