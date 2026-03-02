function accuracy = calculateAccuracy(params, trialType, subtrial, response, onset)
    % Initialize accuracy as NaN (for passive runs or no response)
    accuracy = NaN;
    
    % Only calculate accuracy for attention runs
    if strcmp(params.metadata.runType, 'attention')
        % Get the wedge class from subtrial
        wedgeClass = subtrial.primaryWedgeClass;
        
        % In this simplified version, all trials are target trials
        % Participants should respond to all presented stimuli
        
        % If no response was given
        if isempty(response)
            accuracy = 'miss';  % Should have responded but didn't
            return;
        end
        
        % Determine correct response based on wedge class
        % For vertical wedges, correct response is 2
        % For horizontal wedges, correct response is 1
        if strcmp(wedgeClass, 'vertical')
            correctResp = 2;
        else  % horizontal
            correctResp = 1;
        end
        
        % Compare with participant's response
        responseValue = response(1);
        if isnumeric(responseValue)
            givenResp = responseValue;
        else
            givenResp = str2double(responseValue);
        end
        
        % Calculate accuracy based on response
        if givenResp == correctResp
            accuracy = 'correct';
        else
            accuracy = 'incorrect';
        end
    end
end 