# Task: SinglePositionPerSymbol
**Date:** 2025-06-13 17:48 UTC

## Problem
Opening multiple trades for the same symbol could stack risk beyond the 1-2% rule mentioned in the trading guide. The current `RiskManager` only checks total account risk and allows new positions even when one is already open.

## Solution
Added a `HasOpenPosition` method to `RiskManager` and updated `CanOpen` to block new orders if a position in the same symbol is active. This follows the guide's recommendation to limit exposure per trade (lines around 2598-2610).

## Code (excerpt)
```mql5
bool HasOpenPosition(const string symbol)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)==symbol)
         return true;
   }
   return false;
}

bool CanOpen(const OrderRequest &req)
{
   if(HasOpenPosition(req.symbol))
      return false;
   double new_risk=PositionRisk(req.symbol,req.price,req.sl,req.volume);
   double allowed=m_equity*(m_max_total_risk/100.0);
   double total=CurrentTotalRisk();
   return((total+new_risk)<=allowed);
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Open a demo chart and allow trading. After a trade opens, confirm that no additional trades are placed for the same symbol until the position closes.

## Observations / Notes
- This rule prevents overexposure on a single instrument while still enforcing overall risk limits.
