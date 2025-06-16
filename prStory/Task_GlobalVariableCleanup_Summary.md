# Task: GlobalVariableCleanup
**Date:** 2025-06-13 19:17 UTC

## Problem
Stage tracking global variables `stage_<ticket>` were never removed when a trade closed, leaving stale data. Risk settings also lacked per-asset customization despite the guide's recommendation to adapt position size to each asset's characteristics.

## Solution
- Added `riskPercent` to `AssetConfig` and used it in `RiskManager::BuildRequest` to override the default risk per trade.
- Implemented `CleanupStageVariables` in `TradeExecutor` to delete `stage_*` variables for closed tickets, called after managing positions and at EA deinitialization.
- Updated `SetupAssets` with example risk percentages and OnDeinit to invoke the cleanup.

## Code (excerpt)
```mql5
// TradeExecutor.mqh
void CleanupStageVariables()
{
    int total=GlobalVariablesTotal();
    for(int i=total-1;i>=0;i--)
    {
        string name=GlobalVariableName(i);
        if(StringFind(name,"stage_")==0)
        {
            ulong ticket=(ulong)StringToInteger(StringSubstr(name,6));
            if(!PositionSelectByTicket(ticket))
                GlobalVariableDel(name);
        }
    }
}
```

## Manual Testing Instructions
- [ ] Compile the EA in MetaEditor and ensure no errors.
- [ ] Run a few trades and verify that the global variables `stage_*` disappear after positions close (check via `GlobalVariablesFlush`).
- [ ] Confirm that different assets size positions according to their configured `riskPercent`.

## Observations / Notes
- Risk percentages per asset are illustrative; adjust according to account profile.
- Cleaning global variables avoids clutter and potential mismanagement during long sessions.
