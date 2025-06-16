# Task: BreakevenBuffer
**Date:** 2025-06-14 01:27 UTC

## Problem
Stops were moved to the exact entry price after the first partial. The trading guide (line 5473) recommends adding a small buffer when moving to breakeven to avoid premature stop-outs.

## Solution
`TradeExecutor::ManageOpenPositions` now calculates a buffer equal to 10% of the initial risk with a minimum of two ticks and shifts the stop beyond the entry when performing the first partial. This aligns with the dynamic stop management section of the guide.

## Code (snippet)
```mql5
// after first partial
double buffer=risk*0.1;
double minBuf=2*point;
if(buffer<minBuf) buffer=minBuf;
double be=(type==POSITION_TYPE_BUY)? entry+buffer : entry-buffer;
m_trade.PositionModify(symbol,be,0.0);
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaTrader 5.
- [ ] Execute trades to trigger the first partial profit.
- [ ] Confirm the stop loss moves slightly beyond breakeven instead of exactly at the entry.

## Observations / Notes
- Buffer uses 10% of initial risk with a 2-tick minimum; adjust if assets require different margins.
