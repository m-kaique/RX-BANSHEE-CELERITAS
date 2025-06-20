#ifndef INTEGRATEDPA_PULLBACKTOMA_MQH
#define INTEGRATEDPA_PULLBACKTOMA_MQH
#include "../Defs.mqh"
#include "../Utils.mqh"
#include "../MarketContext.mqh"

class PullbackToMA
{
public:
    PullbackToMA(){}
    ~PullbackToMA(){}

    bool Identify(const string symbol, ENUM_TIMEFRAMES tf,const AssetConfig &asset)
    {
        MarketContextAnalyzer ctx;
        if(ctx.DetectPhaseMTF(symbol,tf,asset.ctxTf,asset.rangeThreshold)!=PHASE_TREND)
            return false;
        // avoid entries when price is already near the 50-200 mean
        if(CheckMeanReversion50to200(symbol, tf))
            return false;

        double ema9  = GetEMA(symbol, tf, 9);
        double ema21 = GetEMA(symbol, tf, 21);
        double ema50 = GetEMA(symbol, tf, 50);

        double close0 = iClose(symbol, tf, 0);
        double close1 = iClose(symbol, tf, 1);

        bool up   = (ema9 > ema21 && ema21 > ema50);
        bool down = (ema9 < ema21 && ema21 < ema50);

        if(up && close1 < ema21 && close0 > ema21)
            return true;
        if(down && close1 > ema21 && close0 < ema21)
            return true;
        return false;
    }

    Signal GenerateSignal(const string symbol, ENUM_TIMEFRAMES tf,const AssetConfig &asset)
    {
        Signal s; s.valid = false;
        if(!Identify(symbol, tf, asset))
            return s;
        double ema21 = GetEMA(symbol, tf, 21);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

        double close0 = iClose(symbol, tf, 0);
        double low1   = iLow(symbol, tf, 1);
        double high1  = iHigh(symbol, tf, 1);

        double ema9  = GetEMA(symbol, tf, 9);
        double ema50 = GetEMA(symbol, tf, 50);

        bool up   = (ema9 > ema21 && ema21 > ema50);
        bool down = (ema9 < ema21 && ema21 < ema50);

       if(up && close0 > ema21)
       {
           s.valid = true;
           s.direction = SIGNAL_BUY;
           s.phase = PHASE_TREND;
           s.entry = close0;
            double stopPts = GuideStopPoints(symbol);
            double stop  = low1 - stopPts*point;
            double target = s.entry + (s.entry - stop)*2.0;
            s.stop  = stop;
            s.target = target;
           s.timestamp = TimeCurrent();
           s.strategy = "PullbackMA";
       }
       else if(down && close0 < ema21)
       {
           s.valid = true;
           s.direction = SIGNAL_SELL;
           s.phase = PHASE_TREND;
           s.entry = close0;
            double stopPts = GuideStopPoints(symbol);
            double stop  = high1 + stopPts*point;
            double target = s.entry - (stop - s.entry)*2.0;
            s.stop  = stop;
            s.target = target;
           s.timestamp = TimeCurrent();
           s.strategy = "PullbackMA";
       }
       const int lookback=20;
       double avgVol=0.0;
       for(int k=1;k<=lookback;k++)
           avgVol+=(double)iVolume(symbol,tf,k);
       avgVol/=lookback;
       double vol1=(double)iVolume(symbol,tf,1);
       double rr=(MathAbs(s.entry-s.stop)>0)?MathAbs(s.target-s.entry)/MathAbs(s.entry-s.stop):0.0;
       double vol_ratio=(avgVol>0.0)?vol1/avgVol:1.0;
       s.quality = EvaluateQuality(symbol,tf,rr, vol_ratio);
       return s;
   }

    SETUP_QUALITY ClassifyQuality(const string symbol, ENUM_TIMEFRAMES tf)
    {
        return SETUP_B;
    }
};

#endif // INTEGRATEDPA_PULLBACKTOMA_MQH
