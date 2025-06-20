# Task: Persistent Market Context per Strategy
**Date:** 2025-06-20 18:47 UTC

## Problem
The EA previously created a new `MarketContextAnalyzer` each time a strategy was called. This repeated instantiation increased processing overhead and prevented context information from persisting across ticks.

## Solution
Strategies now hold a private `MarketContextAnalyzer` instance. `SignalEngine` stores each strategy as a member so the same object—and therefore the same context—is reused on every tick. `OnTick` simply calls `g_engine.Generate` without recreating strategies.

### Code (excerpt)
```mql5
// SignalEngine.mqh
Signal Generate(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
{
    if(UseSpikeAndChannel)
    {
        if(m_spikeAndChannel.Identify(symbol,tf,asset))
            return m_spikeAndChannel.GenerateSignal(symbol,tf,asset);
    }
    ...
}

private:
    SpikeAndChannel      m_spikeAndChannel;
    PullbackToMA         m_pullbackMA;
    ...
```
```mql5
// SpikeAndChannel.mqh
class SpikeAndChannel
{
private:
    MarketContextAnalyzer m_ctx;
public:
    bool Identify(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
    {
        if(m_ctx.DetectPhaseMTF(symbol,tf,asset.ctxTf,asset.rangeThreshold)!=PHASE_TREND)
            return false;
        ...
    }
};
```

## Manual Testing Instructions
- [ ] Compile the EA in MetaEditor and check for errors.
- [ ] Run the EA on a demo account and verify that log messages show strategies being reused across ticks without recreation.

