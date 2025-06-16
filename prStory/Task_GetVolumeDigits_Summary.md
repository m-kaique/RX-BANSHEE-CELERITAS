# Task: GetVolumeDigits
**Date:** 2025-06-14 04:10 UTC

## Problem
`VolumeDigits` calculated the decimal places only from a given step value. This didn't handle retrieval errors and was awkward when used in other modules.

## Solution
Replaced `VolumeDigits` with `GetVolumeDigits` in `Utils.mqh`. The new function queries `SYMBOL_VOLUME_STEP` for the provided symbol and determines how many decimals are needed by multiplying the step by powers of ten until it becomes an integer. `TradeExecutor` now calls this function to normalize partial close volumes.

## Code Snippet
```mql5
// Utils.mqh
int GetVolumeDigits(string symbol)
{
   double step;
   if(!SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP, step))
   {
      Print("Erro ao obter SYMBOL_VOLUME_STEP para o símbolo: ", symbol);
      return 0;
   }
   for(int digits = 0; digits <= 8; digits++)
   {
      double multiplier = MathPow(10.0, digits);
      double adjusted = step * multiplier;
      if(MathAbs(adjusted - MathRound(adjusted)) < 1e-8)
         return digits;
   }
   return 8;
}
```

## Manual Testing Instructions
- [ ] Run `scripts/compile.sh` and ensure it completes without errors.
- [ ] Open a chart for symbols with integer and fractional volume steps and verify partial closes round correctly.

## Observations / Notes
- Default of `8` decimal places covers exotic cases if the step isn't an exact fraction.
