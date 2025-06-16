# Task: DailyProfitTarget
**Date:** 2025-06-14 00:32 UTC

## Problem
The trading guide recommends pausing trading for the day once a profit goal or loss limit is reached (lines 3380-3440). The EA only enforced a daily loss limit.

## Solution
Introduced `DailyProfitPercent` input and extended the daily limit logic. Trading is now paused when either the loss or profit threshold is hit. Functions were renamed to `ResetDailyLimits` and `CheckDailyLimits` to reflect the broader purpose.

## Code (excerpt)
```mql5
input double DailyProfitPercent = 5.0; // stop trading after X% daily profit

void ResetDailyLimits(){
    // resets counters and equity reference each day
}

void CheckDailyLimits(){
    // pauses trading when loss or profit target reached
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Run on a demo account with the profit target set small to trigger quickly.
- [ ] Observe that new orders stop once the target is hit and resume the next day.

## Observations / Notes
- Uses account equity to track cumulative result for the day.
