# Task: AssetConfigFile
**Date:** 2025-06-14 02:30 UTC

## Problem
Asset parameters like minimum stop distance and context timeframe were hardcoded in `SetupAssets`, requiring code changes for each adjustment.

## Solution
Created a CSV file `assets.csv` storing per-asset settings and added `LoadAssetCsv` in `Utils.mqh` to parse it. `SetupAssets` now loads this file and falls back to defaults if absent. A helper `TfFromString` converts timeframe strings and recognizes the `MAIN` keyword to use the expert's main timeframe.

## Code (snippet)
```mql5
AssetConfig loaded[];
if(LoadAssetCsv(cfgFile,MainTimeframe,loaded))
{
    ... populate g_assets ...
}
```

## Manual Testing Instructions
- [ ] Edit `IntegratedPA_EA/assets.csv` to tweak parameters.
- [ ] Compile `IntegratedPA_EA.mq5` in MetaTrader 5.
- [ ] Verify that changed values apply without modifying the source code.

## Observations / Notes
- Defaults remain as before when the CSV file is missing.
- Timeframe strings support M1, M5, M15, M30, H1, H4, D1 and `MAIN`.
