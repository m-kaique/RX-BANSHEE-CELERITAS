# Task: TrendRangeDay and WedgeReversal Implementation
**Date:** 2025-06-13 12:21 UTC

## Problem
The EA lacked implementations for the strategies *Trending Trading Range Day* and *Wedge Reversal*. These patterns are referenced in the trading guide (lines 3955-3990 and 4316-4388) as important setups. Without them, the EA could not generate signals in these contexts.

## Solution
Implemented simplified versions of both strategies:
- **TrendRangeDay** detects when consecutive small ranges move in the trend direction and triggers breakout entries with stops inside the range (guide lines 3980-3984).
- **WedgeReversal** identifies converging trendlines and issues breakout signals for rising or falling wedges as described around lines 4316-4379.
SignalEngine now uses these strategies for trend and reversal phases.

## Code
```mql5
// TrendRangeDay.mqh
if(up){
    s.stop = low1 - range*0.5; // stop inside range
    s.target = s.entry + (s.entry - s.stop)*2.0;
}

// WedgeReversal.mqh
if(rising && close0 < low1){
    s.direction = SIGNAL_SELL;
    s.stop = high1 + height*0.25;
    s.target = s.entry - height;
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Run the EA on historical charts containing wedge reversals or trending range days.
- [ ] Confirm that trades are placed when these patterns occur and that stops/targets respect the 2:1 risk ratio.

## Observations / Notes
- Detection logic is simplified and may require tuning for specific instruments.
- Further enhancements could add volume confirmation and pullback entries as suggested in the guide.
