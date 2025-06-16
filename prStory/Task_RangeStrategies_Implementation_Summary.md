# Task: RangeStrategies
**Date:** 2025-06-13 12:47 UTC

## Problem
`GenerateRangeSignals` returned an empty signal, leaving the EA without logic for markets identified as range phase. The trading guide emphasizes fading extremes or trading confirmed breakouts in ranges.

## Solution
Implemented two range strategies based on the guide (lines 4768-4824):
- **RangeFade** identifies reversals near support or resistance and targets the opposite extreme with a stop 20% beyond the range.
- **RangeBreakout** detects momentum closes beyond the range boundaries and projects the range amplitude as target.
`SignalEngine` now includes these modules and checks for breakout first, then fade.

## Code (excerpt)
```mql5
#include "strategies/RangeFade.mqh"
#include "strategies/RangeBreakout.mqh"
...
Signal GenerateRangeSignals(const string symbol,ENUM_TIMEFRAMES tf)
{
    Signal s; s.valid=false;
    RangeBreakout br;
    if(br.Identify(symbol,tf))
        return br.GenerateSignal(symbol,tf);

    RangeFade rf;
    if(rf.Identify(symbol,tf))
        return rf.GenerateSignal(symbol,tf);
    return s;
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor to ensure no compilation errors.
- [ ] Run the EA on historical data where the market shows clear ranges.
- [ ] Confirm that buy/sell signals appear near range extremes or on breakouts with appropriate stops and targets.

## Observations / Notes
- The identification rules are simplified and may need refinement for different instruments and volatility conditions.
