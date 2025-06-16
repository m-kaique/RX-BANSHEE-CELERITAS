# Task: PartialVolumeStepFix
**Date:** $(date -u +"%Y-%m-%d %H:%M UTC")

## Problem
Partial exits in `TradeExecutor` used a fixed two-decimal rounding which failed when an instrument's `SYMBOL_VOLUME_STEP` was 1.0 or another integer. Orders like closing half of a 1-lot position would produce an invalid volume (0.5) and the broker would reject the partial close.

## Solution
Added a helper `VolumeDigits` in `Utils.mqh` to compute the proper number of decimal places for a volume step. `TradeExecutor::ManageOpenPositions` now uses this function and the symbol's step to round partial volumes before calling `PositionClosePartial`. This follows the risk management guidance on executing partial exits reliably.

## Code (snippet)
```mql5
// Utils.mqh
inline int VolumeDigits(double step) { /* calculate digits */ }

// TradeExecutor.mqh (partial close)
 double lot_step = SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
 int vol_digits = VolumeDigits(lot_step);
 double closeVol = volume/2.0;
 closeVol = MathFloor(closeVol/lot_step + 0.0000001)*lot_step;
 closeVol = NormalizeDouble(closeVol,vol_digits);
 m_trade.PositionClosePartial(symbol,closeVol);
```

## Manual Testing Instructions
- [ ] Compile the EA with MetaEditor.
- [ ] Open a demo account with an instrument whose lot step is 1 (e.g., WIN/WDO).
- [ ] Trigger a trade and verify that partial closes execute without volume errors.

## Observations / Notes
- Ensures consistency for all assets regardless of lot sizing.
