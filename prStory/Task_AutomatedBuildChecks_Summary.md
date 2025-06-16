# Task: AutomatedBuildChecks
**Date:** 2025-06-14 00:57 UTC

## Problem
Compiling the EA requires manual use of MetaEditor, so errors can slip through without a continuous build. The repository lacked an automated compile check.

## Solution
- Added `scripts/compile.sh` which downloads MetaEditor and compiles `IntegratedPA_EA.mq5` using Wine.
- Created a GitHub Actions workflow `.github/workflows/compile.yml` to run the script on every push and pull request.

## Code (excerpt)
```bash
# scripts/compile.sh
wine "$COMPILER_EXE" /compile:"$EA_PATH" /log:"$LOG_FILE" /include:IntegratedPA_EA/MQL5/Include
```

## Manual Testing Instructions
- [ ] Ensure Wine is installed: `apt-get install wine`
- [ ] Run `scripts/compile.sh` and check `build/compile.log` for compile messages.

## Observations / Notes
- The script downloads MetaEditor each run if not present; adjust the path via `MQL5_COMPILER` if you already have the binary.
