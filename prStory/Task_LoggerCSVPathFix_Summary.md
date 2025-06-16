# Task: LoggerCSVPathFix
**Date:** 2025-06-13 14:00 UTC

## Problem
CSV logs were saved to the terminal's common files directory. The project requires
CSV output in the same folder as the compiled EA to simplify access and sharing.

## Solution
Updated `Logger` to derive the EA's folder using `MQLInfoString(MQL_PROGRAM_PATH)`
and open both the text and CSV log files directly in that directory.
This removes the `FILE_COMMON` flag and keeps logs beside the `.ex5` file.

## Code (excerpt)
```mql5
string exePath=MQLInfoString(MQL_PROGRAM_PATH);
string folder=exePath;
for(int i=StringLen(folder)-1;i>=0;i--)
{
    ushort c=StringGetCharacter(folder,i);
    if(c=='\\' || c=='/')
    {
        folder=StringSubstr(folder,0,i+1);
        break;
    }
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` ensuring the Logger compiles without errors.
- [ ] Run the EA and confirm that `<prefix>_log.csv` appears next to the
  `IntegratedPA_EA.ex5` file instead of the common data folder.
- [ ] Verify that log entries are appended correctly during EA operation.

## Observations / Notes
- Existing logs in the common directory are no longer updated; move them
  manually if needed.
