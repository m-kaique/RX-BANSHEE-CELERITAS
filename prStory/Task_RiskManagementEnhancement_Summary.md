# Task: Risk Management Enhancement
**Date:** 2025-06-13 04:29 UTC

## Problem
The EA lacked dynamic risk management. Positions were opened without partial exit rules or trailing stops, contrary to the guidelines about protecting profits and moving the stop after 1R gains.

## Solution
Implemented partial exits and trailing stop logic in `TradeExecutor`. After a position gains 1x the initial risk, half of the volume is closed and the stop is moved to breakeven. Once profit reaches 2x risk, the stop trails the previous bar (with a small buffer). `OnTick` now calls `ManageOpenPositions` to apply these rules on every tick.

## Code
```mql5
// TradeExecutor.mqh (excerpt)
if(stage<1.0 && price>=firstTarget) {
    double closeVol = NormalizeDouble(volume/2.0,2);
    m_trade.PositionClosePartial(symbol, closeVol);
    m_trade.PositionModify(symbol, entry, 0.0); // move stop to breakeven
    GlobalVariableSet(gv,1.0);
}
...
if(stage>=1.0 && price>=trailTrigger) {
    double new_sl = iLow(symbol, PERIOD_CURRENT, 1) - 10*point;
    if(new_sl>sl) m_trade.PositionModify(symbol,new_sl,0.0);
}
```

## Manual Testing Instructions
- [ ] Compile the EA in MetaEditor and ensure no errors.
- [ ] Run on a demo account. After a trade is triggered, observe partial closure at 1R profit and trailing stop activation after 2R.

## Observations / Notes
- Global variables `stage_<ticket>` track if the first partial was executed.
- Trailing uses the previous bar's high/low with a 10-point buffer; adjust to asset volatility if needed.
