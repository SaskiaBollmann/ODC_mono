function logSubtrial(blockNum, trialNum, subTrialCounter, trialType, subtrial, ...
    coherentAngleRed, coherentAngleGreen, subTrialOnset, subTrialOffset, runOnset, ...
    subtrialResponse, accuracy)
    global trialLog;

% Get response information
if isempty(subtrialResponse)
    respKey = '';
    respRtFromTrial = NaN;
    respRT = NaN;
else
    respKey = subtrialResponse(1);
    respRtFromTrial = subtrialResponse(2) - subTrialOnset;
    respRT = subtrialResponse(2) - subTrialOnset;
end

% Initialize new log entry
newEntry = struct(...
    'Block', blockNum, ...
    'Trial', trialNum, ...
    'Subtrial', subTrialCounter, ...
    'Condition', trialType, ...
    'WedgeRed', '', ...
    'AngleRed', NaN, ...
    'WedgeGreen', '', ...
    'AngleGreen', NaN, ...
    'Onset', subTrialOnset - runOnset, ...
    'Offset', subTrialOffset - runOnset, ...
    'SubtrialDuration', subTrialOffset - subTrialOnset, ...
    'SubtrialRespKey', respKey, ...
    'SubtrialRespTrialRT', respRtFromTrial, ...
    'SubtrialRespRT', respRT, ...
    'Accuracy', accuracy);

% Fill in wedge information based on trial type
if strcmp(trialType, 'red') || strcmp(trialType, 'green')
    if strcmp(trialType, 'red')
        newEntry.WedgeRed = subtrial.primaryWedgeClass;
        newEntry.AngleRed = coherentAngleRed;
        newEntry.WedgeGreen = [];
        newEntry.AngleGreen = [];
    else
        newEntry.WedgeRed = [];
        newEntry.AngleRed = [];
        newEntry.WedgeGreen = subtrial.primaryWedgeClass;
        newEntry.AngleGreen = coherentAngleGreen;
    end
else  % dual-color trials
    if strcmp(trialType, 'red-dominant')
        newEntry.WedgeRed = subtrial.primaryWedgeClass;
        newEntry.AngleRed = coherentAngleRed;
        newEntry.WedgeGreen = subtrial.secondaryWedgeClass;
        newEntry.AngleGreen = coherentAngleGreen;
    else  % green-dominant
        newEntry.WedgeRed = subtrial.secondaryWedgeClass;
        newEntry.AngleRed = coherentAngleRed;
        newEntry.WedgeGreen = subtrial.primaryWedgeClass;
        newEntry.AngleGreen = coherentAngleGreen;
    end
end

% If trialLog is empty, initialize it with the first entry
if isempty(trialLog)
    trialLog = newEntry;
else
    % Otherwise append to existing log
    trialLog = [trialLog; newEntry];
end
end