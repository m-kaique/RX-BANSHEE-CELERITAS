# Task: MaxTotalRiskCheck
**Date:** 2025-06-13 12:04 UTC

## Problem
The EA allowed unlimited simultaneous risk. The `RiskManager` parameter `MaxTotalRisk` was unused, so new trades could exceed the account's allowed total exposure, violating the trading guide's risk control recommendations.

## Solution
Implemented total risk calculation in `RiskManager` following the guide's emphasis on strict risk management. New methods compute the risk of each open position and check if adding a new trade would exceed `MaxTotalRisk`. `OnTick` now skips order execution when the limit is reached and logs a warning.

## Code
```mql5
// RiskManager.mqh
double PositionRisk(...);
double CurrentTotalRisk();
bool CanOpen(const OrderRequest &req);

// IntegratedPA_EA.mq5
if(g_risk.CanOpen(req))
    g_exec.Execute(req);
else if(g_log)
    g_log.Log(LOG_WARNING,"Total risk limit exceeded, order skipped");
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Run the EA on a demo account with multiple signals.
- [ ] Verify that no new positions are opened once total risk (open positions plus new order) exceeds the configured `MaxTotalRisk` percentage.
- [ ] Observe log messages for "Total risk limit exceeded".

## Observations / Notes
- This implementation assumes each position has a defined stop loss. Trades without stops are ignored in risk calculations.
- Fixed a compilation issue by replacing `PositionSelectByIndex` with `PositionGetTicket` and `PositionSelectByTicket` when iterating positions.
