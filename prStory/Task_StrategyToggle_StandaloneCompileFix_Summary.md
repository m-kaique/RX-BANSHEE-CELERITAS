# Task: StrategyToggle Standalone Compile Fix
**Date:** 2025-06-13 21:15 UTC

## Problem
`SignalEngine.mqh` failed to compile on its own because the strategy toggle variables were only defined as `input` in the main expert file. Without these definitions, the header produced undeclared identifier errors.

## Solution
Added macros after each strategy input in `IntegratedPA_EA.mq5` and used conditional `extern` declarations in `SignalEngine.mqh`. This allows the header to compile by itself while avoiding conflicts with the `input` variables when included in the expert file.

## Code (excerpt)
```mql5
// IntegratedPA_EA.mq5
input bool UseSpikeAndChannel = true;  #define HAS_USE_SPIKE_AND_CHANNEL
...

// SignalEngine.mqh
#ifndef HAS_USE_SPIKE_AND_CHANNEL
extern bool UseSpikeAndChannel;
#endif
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` to ensure no redefinition errors.
- [ ] Compile `SignalEngine.mqh` individually to verify that undeclared identifier errors are gone.

## Observations / Notes
- Headers rarely need standalone compilation, but these guards help prevent confusion for new developers.
