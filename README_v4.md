# ODC Experiment v4 - Complete Workflow

## Overview
This is version 4 of the 2025 NextGen ODC experiment with improved run management that prevents accidental data overwrites.

### Attention task (v4)
In this version, **attention** runs mean participants attend to and respond to motion direction for **both** colours (red and green) within the same run. Future iterations will stratify so that within a run participants are cued to attend to **either** red **or** green; that design will then scale to the dual-presentation code that will follow.

## Key Changes from v2
- **Run type selection at execution**: Passive/attention is now selected in doExp.m, not during calibration
- **Auto-incrementing run numbers**: Run numbers are now automatically assigned at experiment execution time
- **Overwrite protection**: doExp.m detects existing runs and assigns the next available number
- **Reusable calibration**: Calibration workspaces are saved by participant only - same calibration works for both passive and attention runs
- **Run confirmation**: Shows existing runs and confirms before starting
- **Load existing calibrations**: Visual space and anaglyph calibrations can be loaded from existing files (useful when changing timing parameters)

## Complete Workflow

### Phase 1: Timing Configuration  
**Run `preExp.m` first**
```matlab
cd mono_code_v4
preExp
```

This script:
- Opens a GUI for timing parameter configuration (single block design)
- Calculates optimal trial/subtrial durations based on target run duration  
- Saves timing parameters to `params/` folder for reuse
- **Must be completed before calibration**

### Phase 2: Calibration and Setup
**Run `doExpCalibrate.m` to perform all calibrations**
```matlab
doExpCalibrate
```

This script performs:

a. **Initial Setup**:
   - Enter subject number and red lens eye (L/R)
   - **Note**: Run type and run number are NO LONGER collected here (selected in Phase 3)
   - Data folders are created automatically

b. **Visual Space Mapping**:
   - Calibrates the position and size of the stimulus aperture
   - If no file exists: Choose "Calibrate Now", "Load Existing File", or "Use Defaults"
   - If file exists: Choose "Use Existing" or "Recalibrate"
   - Controls: Arrow keys to move, S/L to resize, ESC to save

c. **Anaglyph Calibration** (Scanner-compatible):
   - Adjusts red/green colors for optimal separation with anaglyph glasses
   - If no file exists: Choose "Calibrate Now", "Load Existing File", or "Use Defaults"
   - If file exists: Choose "Use Existing" or "Recalibrate"
   - Controls: 1,2 for red, 3,4 for green (works with top row or numpad)
   - ESC to save and continue

d. **Coherence Calibration**:
   - Determines appropriate motion coherence thresholds
   - Uses interleaved red/green trials with single Quest staircase
   - Automated convergence detection

e. **Workspace Preparation**:
   - Saves prepared workspace as `[participant]_prepared_workspace_TR[X]s_SubtrialDur[Y]s.mat` (same timing detail as coherence calibration)
   - This workspace can be reused for ALL runs (both passive and attention) for that timing; new TR/timing creates a new file (no overwrite)

### Phase 3: Experiment Execution
**Run `doExp.m` to execute the experiment**  
```matlab
doExp
```

This script:
- Loads a previously prepared workspace from calibration
- **Opens a Run Options panel** where you select:
  - **Run Type**: Passive or Attention
  - **Trial Ordering**: 
    - Random (fully randomized red/green)
    - Interleaved (R-G-R-G... or G-R-G-R... with random start)
    - Blocked (all red then all green, or vice versa)
- **Automatically detects existing runs** for this participant
- **Confirms run number** with options to:
  - Use next available (auto-incrementing, prevents overwrites)
  - Specify custom run number (with overwrite warning if exists)
- Shows summary of existing runs before starting
- Runs the full experiment with:
  - Scanner trigger option
  - Block-based design
  - Real-time trial logging
  - Response collection and performance tracking
  - Automatic data saving

## File Structure

### Core Scripts
- `preExp.m` - Phase 1: Timing configuration
- `doExpCalibrate.m` - Phase 2: Complete calibration suite  
- `doExp.m` - Phase 3: Experiment execution with auto-run-numbering

### Workspace Naming Convention

**v2 (old)**: `[participant]_run[N]_prepared_workspace.mat`
- Problem: Each run needed separate calibration, risk of overwrites

**v4 (new)**: `[participant]_prepared_workspace_TR[X]s_SubtrialDur[Y]s.mat`
- Example: `test_prepared_workspace_TR4.5000s_SubtrialDur2s.mat`
- Same level of detail as coherence calibration files, so changing TR (or timing) does not overwrite an existing workspace.
- Benefit: Same calibration reused for ALL runs (both passive and attention) *for that timing setup*; different timing = separate workspace file.

### Data Output Structure
```
data/2025_nextgen_odc_v4/
├── [participant]/
│   ├── visualSpaceMap_[ppt]_YYYYMMDD_HHMMSS.mat   # Per-participant, date/time (no overwrite)
│   ├── [ppt]_calibration_YYYYMMDD_HHMMSS.mat      # Per-participant, date/time (no overwrite)  
│   ├── [ppt]_coherence_calibration_*.mat  # Per-participant + timing
│   ├── [ppt]_prepared_workspace_TR*_SubtrialDur*.mat  # One per timing setup (no overwrite)
│   └── TR[X]/
│       ├── run-01_passive_TR[X]/         # Run 1 (passive)
│       │   ├── [ppt]_run1_data.mat
│       │   └── [ppt]_run1_trialLog.csv
│       ├── run-02_passive_TR[X]/         # Run 2 (passive)
│       │   └── ...
│       └── run-03_attention_TR[X]/       # Run 3 (attention) - sequential numbering!
│           └── ...
```

**Note**: Run numbers are sequential across ALL run types (passive + attention).

## Typical Session Workflow

### First Session (New Participant)
```matlab
% 1. Configure timing (once per study protocol)
preExp

% 2. Calibrate participant (one calibration works for ALL runs at this TR/timing!)
doExpCalibrate  % Enter participant ID and red lens eye

% 3. Run first passive experiment
doExp  % Select workspace (e.g. test_prepared_workspace_TR4.5000s_SubtrialDur2s.mat), choose "Passive", auto-assigns Run 1

% 4. Run second passive experiment (same calibration!)
doExp  % Select same workspace, choose "Passive", auto-assigns Run 2

% 5. Run attention experiment (same calibration - no recalibration needed!)
doExp  % Select same workspace, choose "Attention", auto-assigns Run 3 (sequential!)
```

### Follow-up Session (Returning Participant)
```matlab
% Just run experiments - calibration already saved!
doExp  % Select workspace, choose run type, auto-assigns next run number
```

## Key Improvements in v4
- **No more accidental overwrites**: Run numbers auto-increment with overwrite warnings
- **Manual run number override**: Option to specify custom run number when needed
- **Sequential run numbering**: Run numbers are global across passive AND attention runs
- **Reusable calibrations**: One workspace per participant per timing (TR + subtrial duration); no overwrite when you change TR
- **Run type selection at execution**: Choose passive/attention when you run, not during calibration  
- **Trial ordering options**: Random, interleaved (R-G-R-G), or blocked ordering
- **Clear run tracking**: Shows existing runs (with type) before starting
- **User confirmation**: Explicit confirmation prevents accidental runs
- **Scanner compatibility**: All input methods work with both keyboard types
- **Error recovery**: Error/interrupted workspaces saved with correct run numbers

## Quick Reference

### Calibration file naming
- **Visual space**: `visualSpaceMap_[ppt]_YYYYMMDD_HHMMSS.mat` — date/time appended so new calibrations never overwrite.
- **Anaglyph**: `[ppt]_calibration_YYYYMMDD_HHMMSS.mat` — same. When multiple exist, "Use Existing" uses the most recent.

### Calibration Controls
| Task | Keys |
|------|------|
| Visual Space | Arrow keys (move), S/L (resize), ESC (save) |
| Anaglyph | 1,2 (red), 3,4 (green), ESC (save) |
| Coherence | Left/Right arrows (respond), ESC (abort) |

### Trial Ordering Options
| Option | Behaviour |
|--------|-----------|
| Random | Fully shuffled red/green trials |
| Interleaved | R-G-R-G... or G-R-G-R... (random start) |
| Blocked | All red then green (or vice versa) |

## Migration from v2
If you have v2 workspaces (`*_run[N]_prepared_workspace.mat`):
1. They will still work with v4's doExp.m (file dialog shows `*_prepared_workspace*.mat`)
2. Consider re-running doExpCalibrate to create the new naming format (`*_prepared_workspace_TR*_SubtrialDur*.mat`)
3. Old data in `run-XX_type_TR` folders will be detected for run numbering

This structure ensures proper experimental setup, prevents data loss from overwrites, and provides a robust foundation for scanner-based data collection.

