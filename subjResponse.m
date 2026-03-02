function [response] = subjResponse(runType)
    % subjResponse: Check/record observer's response
    % For attention runs: 1 = horizontal, 2 = vertical
    % For other runs: responses 1-4 are valid
    
    response = [];
    [keyIsDown, secs, keyCode, ~] = KbCheck(-3);
    
    if keyIsDown
        if strcmp(runType, 'attention')
            % For attention runs, only accept 1 or 2
            topRowKeys = [KbName('1!'), KbName('2@')];
            numpadKeys = [KbName('1'), KbName('2')];
        else
            % For other runs, accept 1-4
            topRowKeys = [KbName('1!'), KbName('2@'), KbName('3#'), KbName('4$')];
            numpadKeys = [KbName('1'), KbName('2'), KbName('3'), KbName('4')];
        end
        
        % Create logical vectors for keys pressed
        topRowPressed = keyCode(topRowKeys);
        numpadPressed = keyCode(numpadKeys);
        
        % Combine them elementwise
        combinedPressed = topRowPressed | numpadPressed;
        
        % If any of these keys are pressed, take the first one
        if any(combinedPressed)
            keyIndices = find(combinedPressed);
            % keyIndices(1) gives the first key from our defined order
            response = [keyIndices(1), secs];
        elseif keyCode(KbName('q')) || keyCode(KbName('escape'))
            Screen('CloseAll');
        end
    end
end 