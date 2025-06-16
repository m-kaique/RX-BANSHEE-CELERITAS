# Task: OnDeinit Cleanup Call Fix
**Date:** 2025-06-13 19:37 UTC

## Problem
The EA called `CleanupStageVariables` using the arrow operator (`->`) which is invalid syntax in MQL5 when invoking methods on an object pointer.

## Solution
Replaced `g_exec->CleanupStageVariables()` with `g_exec.CleanupStageVariables()` in `OnDeinit` so the method is called correctly before deleting the executor object.

## Code Snippet
```mql5
if(g_exec){g_exec.CleanupStageVariables(); delete g_exec; g_exec=NULL;}
```

## Manual Testing Instructions
- [ ] Compile the EA to ensure no syntax errors.
- [ ] Run the EA and verify it deinitializes without errors and global variables are cleaned up.

## Observations / Notes
- MQL5 does not support the `->` operator; methods on pointers use the dot syntax.
