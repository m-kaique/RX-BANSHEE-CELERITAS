# Task: VWAPReversion Implementation
**Date:** 2025-06-13 18:59 UTC

## Problem
The trading guide highlights using VWAP for intraday mean reversion (lines 2084-2098). The EA lacked a dedicated strategy to trade the return to VWAP after excessive moves.

## Solution
Implemented a new `VWAPReversion` strategy following the PDF guidance. It identifies when price closes more than two ATRs away from VWAP and starts to revert. A trade is opened targeting the VWAP with a stop beyond the prior bar and quality graded using risk/reward and volume. `SignalEngine` now includes this strategy in the reversal set.

## Code (excerpt)
```mql5
// strategies/VWAPReversion.mqh
if(diff1>2*atr)
{
    if(close1>vwap && close0<close1)
        buySignal=false;
    else if(close1<vwap && close0>close1)
        buySignal=true;
}
```

## Manual Testing Instructions
- [ ] Compile the EA in MetaEditor and ensure no errors.
- [ ] Run on a demo account with trading enabled and monitor logs for "VWAPRev" signals.
- [ ] Check that stops are at least 10 points beyond the prior bar and targets align with the VWAP line.

## Observations / Notes
- The detection logic is simplified; future improvements could include volume divergence or candle pattern checks per the guide.
