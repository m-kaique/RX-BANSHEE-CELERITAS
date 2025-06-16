# Task: SlippageHandling Improvement
**Date:** 2025-06-13 14:12 UTC

## Problem
Market orders used the close price from the signal which could differ from the
current bid/ask, increasing the chance of slippage.

## Solution
`RiskManager.BuildRequest` now sets the entry price from the current market bid
or ask and normalizes the stop and target prices. `TradeExecutor.Execute` uses
the latest price at execution time and sets a 10-point deviation allowance.

## Code (excerpt)
```mql5
// RiskManager.mqh
double current=(signal.direction==SIGNAL_BUY)?
               SymbolInfoDouble(symbol,SYMBOL_ASK):
               SymbolInfoDouble(symbol,SYMBOL_BID);
req.price=NormalizePrice(symbol,current);

// TradeExecutor.mqh
m_trade.SetDeviationInPoints(10);
double exec_price=(req.type==ORDER_TYPE_BUY)?
                   SymbolInfoDouble(req.symbol,SYMBOL_ASK):
                   SymbolInfoDouble(req.symbol,SYMBOL_BID);
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5`.
- [ ] Check that new orders open near the current market price without errors.
- [ ] Observe if partial exits and trailing stops continue to function.

## Observations / Notes
- The default 10-point deviation can be adjusted per asset if needed.
