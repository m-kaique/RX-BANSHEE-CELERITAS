#ifndef INTEGRATEDPA_TRENDRANGEDAY_MQH
#define INTEGRATEDPA_TRENDRANGEDAY_MQH
#include "../Defs.mqh"
#include "../Utils.mqh"

class TrendRangeDay
{
public:
   TrendRangeDay(){}
   ~TrendRangeDay(){}

   // Identify a Trending Trading Range Day pattern
   // Based on guide lines 3955-3970 describing consecutive ranges
   // moving in the direction of the trend
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf)
   {
      // do not trade trend setups if price is mean reverting to the 50-200 zone
      if(CheckMeanReversion50to200(symbol,tf))
         return false;

      double ema20=GetEMA(symbol,tf,20);
      double ema50=GetEMA(symbol,tf,50);
      double close0=iClose(symbol,tf,0);

      bool up   = (ema20>ema50 && close0>ema20);
      bool down = (ema20<ema50 && close0<ema20);
      if(!up && !down)
         return false;

      // average range of last 10 bars
      double avg=0.0;
      for(int i=1;i<=10;i++)
         avg+=iHigh(symbol,tf,i)-iLow(symbol,tf,i);
      avg/=10.0;

      int small=0;
      for(int i=1;i<=10;i++)
      {
         double range=iHigh(symbol,tf,i)-iLow(symbol,tf,i);
         if(range<=avg*0.6)
            small++;              // counts consolidation bars
      }

      return(small>=3);           // at least three small ranges
   }

   // Generate breakout signal from the last range
   Signal GenerateSignal(const string symbol,ENUM_TIMEFRAMES tf)
   {
      Signal s; s.valid=false;

      if(!Identify(symbol,tf))
         return s;

      double ema20=GetEMA(symbol,tf,20);
      double ema50=GetEMA(symbol,tf,50);
      double close0=iClose(symbol,tf,0);
      double high1=iHigh(symbol,tf,1);
      double low1 =iLow(symbol,tf,1);
      double range=high1-low1;

      bool up   = (ema20>ema50 && close0>ema20);
      bool down = (ema20<ema50 && close0<ema20);

      if(up)
      {
         s.valid=true;
         s.direction=SIGNAL_BUY;
         s.phase=PHASE_TREND;
         s.entry=close0;
         double stop  = low1-range*0.5;            // stop inside range
         double target=s.entry+(s.entry-stop)*2.0;
         s.stop = stop;
         s.target= target;
         s.timestamp=TimeCurrent();
         s.strategy="TrendRangeDay";
      }
      else if(down)
      {
         s.valid=true;
         s.direction=SIGNAL_SELL;
         s.phase=PHASE_TREND;
         s.entry=close0;
         double stop  = high1+range*0.5;
         double target=s.entry-(stop-s.entry)*2.0;
         s.stop = stop;
         s.target= target;
         s.timestamp=TimeCurrent();
         s.strategy="TrendRangeDay";
      }

      const int lookback=20;
      double avgVol=0.0;
      for(int k=1;k<=lookback;k++)
         avgVol+=(double)iVolume(symbol,tf,k);
      avgVol/=lookback;
      double vol1=(double)iVolume(symbol,tf,1);
      double rr=(MathAbs(s.entry-s.stop)>0)?MathAbs(s.target-s.entry)/MathAbs(s.entry-s.stop):0.0;
      double vol_ratio=(avgVol>0.0)?vol1/avgVol:1.0;
      s.quality=EvaluateQuality(symbol,tf,rr,vol_ratio);
      return s;
   }

   SETUP_QUALITY ClassifyQuality(const string symbol,ENUM_TIMEFRAMES tf)
   {
      return SETUP_B;
   }
};

#endif // INTEGRATEDPA_TRENDRANGEDAY_MQH
