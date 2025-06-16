# Task: AssetSpecificTrailing
**Date:** 2025-06-14 00:39 UTC

## Problem
Trailing stops only had special handling for the mini index (WIN). The trading guide
(lines 5320-5355) recommends asset-specific trailing distances after partial exits,
with 10-15 points after 50+ point profit for the dollar (WDO) and 800-1000 dollars
after $4000+ profit for Bitcoin. Without these rules the EA could give back too
much profit on these instruments.

## Solution
`TradeExecutor::ManageOpenPositions` now applies tailored trailing rules:
- For WDO, once profit exceeds 50 points it trails by ~12 points.
- For BTC, once profit exceeds $4000 it trails by about $900.
This logic follows the same style used for WIN's ATR-based trail.

## Code
```mql5
// excerpt from ManageOpenPositions
if(StringFind(symbol,"WDO")==0)
{
    double profit=MathAbs(price-entry);
    if(profit>=50*point)
    {
        double dist=12*point; // around 10-15 points
        ...
    }
}
else if(StringFind(symbol,"BTC")==0)
{
    double profit=MathAbs(price-entry);
    if(profit>=4000.0)
    {
        double dist=900.0; // around 800-1000
        ...
    }
}
```

## Manual Testing Instructions
- [ ] Attach the EA to a chart for WDO and BTC in MetaTrader 5.
- [ ] Open a trade and let it progress beyond the profit thresholds (50 points for WDO, $4000 for BTC).
- [ ] Verify the stop loss trails by roughly the specified distances.

## Observations / Notes
- Distances are approximations; adjust if symbol point values differ.
