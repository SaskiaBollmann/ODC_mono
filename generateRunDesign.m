function design = generateRunDesign(params)
    % generateRunDesign - Creates the experimental design for a run
    %
    % INPUT: params - Complete parameter structure
    %
    % OUTPUT: design - Structure containing:
    %   .blocks{} - Cell array of blocks, each with .trials
    %   .timing   - Timing information copied from params
    %   .trialOrdering - Which ordering was used
    %
    % TRIAL ORDERING (params.design.trialOrdering):
    %   'random'      - Fully randomized red/green order (default)
    %   'interleaved' - Alternating R-G-R-G or G-R-G-R (random start)
    %   'blocked'     - All red then green, or vice versa (random order)
    %
    % DESIGN: Balanced 4-condition design (red/green x vertical/horizontal)
    
    % Get parameters from params structure
    numBlocks = params.timing.numBlocks;
    totalTrials = params.timing.totalTrials;
    numSubTrials = params.timing.numSubTrials;
    trialsPerBlock = params.timing.numTrialsPerBlock;
    
    % Get trial ordering preference (default to 'random' if not specified)
    if isfield(params.design, 'trialOrdering') && ~isempty(params.design.trialOrdering)
        trialOrdering = params.design.trialOrdering;
    else
        trialOrdering = 'random';
    end
    disp(['############## Trial ordering: ' trialOrdering ' ##############']);
    
    % Ensure totalTrials is divisible by 4 (our basic design cells)
    if mod(totalTrials, 4) ~= 0
        error('Total number of trials must be divisible by 4 to ensure balanced design');
    end
    
    % Define our 4 basic conditions (single trials only)
    conditions = struct();
    conditions.colorType = {'single', 'single', 'single', 'single'};
    conditions.color = {'red', 'red', 'green', 'green'};
    conditions.wedgeClass = {'vertical', 'horizontal', 'vertical', 'horizontal'};
    conditions.trialType = {'red', 'red', 'green', 'green'};
    
    % How many repetitions of each condition do we need?
    repsPerCondition = totalTrials / 4;
    
    % Pre-allocate allTrials array
    allTrials(1:totalTrials) = struct('colorType', [], 'color', [], 'wedgeClass', [], ...
                                     'trialType', [], 'wedgeAssignment', [], ...
                                     'secondWedgeAssignment', [], 'subTrials', []);
    trialCounter = 1;
    
    % Create full trial sequence
    for condIdx = 1:4
        for rep = 1:repsPerCondition
            allTrials(trialCounter).colorType = conditions.colorType{condIdx};
            allTrials(trialCounter).color = conditions.color{condIdx};
            allTrials(trialCounter).wedgeClass = conditions.wedgeClass{condIdx};
            allTrials(trialCounter).trialType = conditions.trialType{condIdx};
            
            % Randomly select one of 4 possible wedges for this class
            if strcmp(allTrials(trialCounter).wedgeClass, 'vertical')
                possibleWedges = params.stimulus.verticalWedgeRanges;
            else
                possibleWedges = params.stimulus.horizontalWedgeRanges;
            end
            selectedWedgeIdx = randi(4);
            allTrials(trialCounter).wedgeAssignment = possibleWedges(selectedWedgeIdx, :);
            
            % For single trials, set secondWedgeAssignment to empty
            allTrials(trialCounter).secondWedgeAssignment = [];
            
            % Generate subtrial parameters
            subTrials(1:numSubTrials) = struct('primaryWedgeClass', [], 'primaryWedgeRange', [], ...
                                             'secondaryWedgeClass', [], 'secondaryWedgeRange', []);
            
            % First subtrial always uses the trial's wedge assignments
            subTrials(1).primaryWedgeClass = allTrials(trialCounter).wedgeClass;
            subTrials(1).primaryWedgeRange = allTrials(trialCounter).wedgeAssignment;
            subTrials(1).secondaryWedgeClass = [];
            subTrials(1).secondaryWedgeRange = [];
            
            % For remaining subtrials
            remainingTrials = numSubTrials - 1;
            if mod(remainingTrials, 2) == 0
                % Even number remaining - split equally
                numSameType = remainingTrials / 2;
                numOppositeType = remainingTrials / 2;
            else
                % Odd number remaining - one more of original type
                numSameType = ceil(remainingTrials / 2);
                numOppositeType = floor(remainingTrials / 2);
            end
            
            % Assign wedge types and ranges for remaining subtrials
            subIdx = 2;  % start after first subtrial
            
            % Add same-type subtrials for primary color
            for i = 1:numSameType
                % Primary color wedge (same as original)
                subTrials(subIdx).primaryWedgeClass = allTrials(trialCounter).wedgeClass;
                if strcmp(subTrials(subIdx).primaryWedgeClass, 'vertical')
                    subTrials(subIdx).primaryWedgeRange = params.stimulus.verticalWedgeRanges(randi(4), :);
                else
                    subTrials(subIdx).primaryWedgeRange = params.stimulus.horizontalWedgeRanges(randi(4), :);
                end
                
                % For single trials, set secondary fields to empty
                subTrials(subIdx).secondaryWedgeClass = [];
                subTrials(subIdx).secondaryWedgeRange = [];
                
                subIdx = subIdx + 1;
            end
            
            % Add opposite-type subtrials
            for i = 1:numOppositeType
                % Primary color wedge (opposite of original)
                subTrials(subIdx).primaryWedgeClass = oppositeWedgeClass(allTrials(trialCounter).wedgeClass);
                if strcmp(subTrials(subIdx).primaryWedgeClass, 'vertical')
                    subTrials(subIdx).primaryWedgeRange = params.stimulus.verticalWedgeRanges(randi(4), :);
                else
                    subTrials(subIdx).primaryWedgeRange = params.stimulus.horizontalWedgeRanges(randi(4), :);
                end
                
                % For single trials, set secondary fields to empty
                subTrials(subIdx).secondaryWedgeClass = [];
                subTrials(subIdx).secondaryWedgeRange = [];
                
                subIdx = subIdx + 1;
            end
            
            % Randomize order of subtrials after the first one
            if numSubTrials > 1
                randIdxs = randperm(numSubTrials-1) + 1;  % +1 to keep first subtrial fixed
                subTrials = subTrials([1 randIdxs]);  % keep first trial, randomize rest
            end
            
            allTrials(trialCounter).subTrials = subTrials;
            trialCounter = trialCounter + 1;
        end
    end
    
    % Apply trial ordering based on selected option
    switch trialOrdering
        case 'random'
            % Fully randomized (original behavior)
            allTrials = allTrials(randperm(length(allTrials)));
            
        case 'interleaved'
            % Alternating red/green with random start
            allTrials = orderTrialsInterleaved(allTrials);
            
        case 'blocked'
            % All red then all green (or vice versa, random choice)
            allTrials = orderTrialsBlocked(allTrials);
            
        otherwise
            % Default to random if unknown option
            warning('Unknown trial ordering option: %s. Using random.', trialOrdering);
            allTrials = allTrials(randperm(length(allTrials)));
    end
    
    % Store the ordering used
    design.trialOrdering = trialOrdering;
    
    % Distribute trials across blocks
    for blockNum = 1:numBlocks
        startIdx = (blockNum-1) * trialsPerBlock + 1;
        endIdx = min(blockNum * trialsPerBlock, totalTrials);
        design.blocks{blockNum}.trials = allTrials(startIdx:endIdx);
    end
    
    % Add timing information from params structure
    design.timing = struct(...
        'trialDuration', params.timing.trialDuration, ...
        'subTrialDuration', params.timing.subTrialDuration, ...
        'numSubTrials', params.timing.numSubTrials);
    
    return;
end

function orderedTrials = orderTrialsInterleaved(allTrials)
    % Order trials as alternating red/green with random start
    % Maintains balance of vertical/horizontal within each color
    
    % Separate red and green trials
    redTrials = allTrials(strcmp({allTrials.color}, 'red'));
    greenTrials = allTrials(strcmp({allTrials.color}, 'green'));
    
    % Shuffle within each color to randomize wedge directions
    redTrials = redTrials(randperm(length(redTrials)));
    greenTrials = greenTrials(randperm(length(greenTrials)));
    
    % Determine random start (red or green first)
    startWithRed = rand > 0.5;
    
    if startWithRed
        disp('############## Interleaved ordering: Starting with RED ##############');
        firstSet = redTrials;
        secondSet = greenTrials;
    else
        disp('############## Interleaved ordering: Starting with GREEN ##############');
        firstSet = greenTrials;
        secondSet = redTrials;
    end
    
    % Interleave the trials
    numTrials = length(allTrials);
    orderedTrials = allTrials;  % Pre-allocate with same structure
    
    firstIdx = 1;
    secondIdx = 1;
    
    for i = 1:numTrials
        if mod(i, 2) == 1  % Odd positions (1, 3, 5, ...)
            if firstIdx <= length(firstSet)
                orderedTrials(i) = firstSet(firstIdx);
                firstIdx = firstIdx + 1;
            else
                orderedTrials(i) = secondSet(secondIdx);
                secondIdx = secondIdx + 1;
            end
        else  % Even positions (2, 4, 6, ...)
            if secondIdx <= length(secondSet)
                orderedTrials(i) = secondSet(secondIdx);
                secondIdx = secondIdx + 1;
            else
                orderedTrials(i) = firstSet(firstIdx);
                firstIdx = firstIdx + 1;
            end
        end
    end
end

function orderedTrials = orderTrialsBlocked(allTrials)
    % Order trials as all of one color first, then all of the other
    % Random choice of which color comes first
    
    % Separate red and green trials
    redTrials = allTrials(strcmp({allTrials.color}, 'red'));
    greenTrials = allTrials(strcmp({allTrials.color}, 'green'));
    
    % Shuffle within each color to randomize wedge directions
    redTrials = redTrials(randperm(length(redTrials)));
    greenTrials = greenTrials(randperm(length(greenTrials)));
    
    % Determine random order (red first or green first)
    redFirst = rand > 0.5;
    
    if redFirst
        disp('############## Blocked ordering: RED block first, then GREEN ##############');
        orderedTrials = [redTrials, greenTrials];
    else
        disp('############## Blocked ordering: GREEN block first, then RED ##############');
        orderedTrials = [greenTrials, redTrials];
    end
end

% Helper function to get opposite wedge class
function opposite = oppositeWedgeClass(wedgeClass)
    if strcmp(wedgeClass, 'vertical')
        opposite = 'horizontal';
    else
        opposite = 'vertical';
    end
end 