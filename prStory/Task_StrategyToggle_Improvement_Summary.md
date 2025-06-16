# Task: StrategyToggle Improvement
**Date:** 2025-06-13 21:10 UTC

## Problem
The EA always evaluated every strategy, leaving no way to customize which ones are active. The trading guide advises adapting strategies to the trader's profile (lines 36-42).

## Solution
Added input parameters to enable or disable each strategy. `SignalEngine` simply references these global inputs and skips any disabled strategy when generating signals.

## Code (excerpt)
```mql5
// IntegratedPA_EA.mq5
input bool UseSpikeAndChannel = true;
input bool UsePullbackMA = true;
...

// SignalEngine.mqh no longer declares the variables, it just reads them
if(UseSpikeAndChannel && sac.Identify(symbol,tf))
    return sac.GenerateSignal(symbol,tf);
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` and ensure no errors.
- [ ] Toggle strategies on/off via inputs and observe signals only from enabled strategies.
- [ ] Verify strategy logs reflect the chosen configuration.

## Observations / Notes
- Default values keep existing behavior with all strategies enabled.
