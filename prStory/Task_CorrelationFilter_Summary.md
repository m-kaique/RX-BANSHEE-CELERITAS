# Task: CorrelationFilter
**Date:** 2025-06-14 01:50 UTC

## Problem
Trades on the dollar and index ignored their typical negative correlation. The trading guide (lines 2854-2925) recommends monitoring dollar moves to confirm index direction. Without this filter, signals could conflict with market context.

## Solution
Implemented `GetCorrelation`, `CheckDollarIndexCorrelation` and the helper `ValidateDollarIndexCorrelation` in `Utils.mqh` to measure divergence between WDO and WIN. Added a new `UseDollarIndexCorrelation` input in the expert. `OnTick` now calls the helper so trades only trigger when the two markets diverge as expected.

## Code (snippet)
```mql5
if(UseDollarIndexCorrelation &&
   !ValidateDollarIndexCorrelation(symbol,sig.direction,g_assets,ArraySize(g_assets),MainTimeframe))
{
    if(g_log) g_log.Log(LOG_INFO,"Correlation filter blocked signal");
    continue;
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaTrader 5.
- [ ] Run the EA on both WDO and WIN charts.
- [ ] Ensure trades only occur when dollar and index move opposite with negative correlation.

## Observations / Notes
- The 20-bar correlation window and -0.2 threshold were chosen for simplicity and may need adjustment based on historical analysis.
