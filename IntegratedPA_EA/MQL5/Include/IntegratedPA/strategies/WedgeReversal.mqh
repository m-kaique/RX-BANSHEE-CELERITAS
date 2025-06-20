#ifndef INTEGRATEDPA_WEDGEREVERSAL_MQH
#define INTEGRATEDPA_WEDGEREVERSAL_MQH
#include "../Defs.mqh"
#include "../MarketContext.mqh"

class WedgeReversal
{
public:
   WedgeReversal(){}
   ~WedgeReversal(){}

   // Identify rising/falling wedge as described in guide lines 4316-4379
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf,bool &isRising,const AssetConfig &asset)
   {
      MarketContextAnalyzer ctx;
      if(ctx.DetectPhaseMTF(symbol,tf,asset.ctxTf,asset.rangeThreshold)!=PHASE_REVERSAL)
         return false;
      isRising=false;

      double h1=iHigh(symbol,tf,1);
      double h3=iHigh(symbol,tf,3);
      double h5=iHigh(symbol,tf,5);
      double l1=iLow(symbol,tf,1);
      double l3=iLow(symbol,tf,3);
      double l5=iLow(symbol,tf,5);

      // simple converging trendlines check
      bool risingHighs = (h1>h3 && h3>h5);
      bool risingLows  = (l1>l3 && l3>l5);
      bool fallingHighs= (h1<h3 && h3<h5);
      bool fallingLows = (l1<l3 && l3<l5);

      if(risingHighs && risingLows && ( (h1-h3)<(h3-h5) || (l1-l3)<(l3-l5) ))
      {
         isRising=true; // rising wedge -> bearish
         return true;
      }
      if(fallingHighs && fallingLows && ( (h3-h1)<(h5-h3) || (l3-l1)<(l5-l3) ))
      {
         isRising=false; // falling wedge -> bullish
         return true;
      }
      return false;
   }

   // Generate reversal signal on breakout of the wedge
   Signal GenerateSignal(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
   {
      Signal s; s.valid=false;
      bool rising=false;
      if(!Identify(symbol,tf,rising,asset))
         return s;

      double close0=iClose(symbol,tf,0);
      double high1=iHigh(symbol,tf,1);
      double low1 =iLow(symbol,tf,1);
      double high5=MathMax(MathMax(high1,iHigh(symbol,tf,3)),iHigh(symbol,tf,5));
      double low5 =MathMin(MathMin(low1 ,iLow(symbol,tf,3)), iLow(symbol,tf,5));
      double height=high5-low5;
      if(height<=0.0) height=iHigh(symbol,tf,1)-iLow(symbol,tf,1);

      if(rising && close0<low1)            // breakout below wedge
      {
         s.valid=true;
         s.direction=SIGNAL_SELL;
         s.phase=PHASE_REVERSAL;
         s.entry=close0;
         double stop  = high1+height*0.25;        // stop inside wedge
         double target= s.entry-height;          // target equal to wedge height
         s.stop=stop;
         s.target=target;
         s.timestamp=TimeCurrent();
         s.strategy="WedgeRev";
      }
      else if(!rising && close0>high1)     // breakout above wedge
      {
         s.valid=true;
         s.direction=SIGNAL_BUY;
         s.phase=PHASE_REVERSAL;
         s.entry=close0;
         double stop  = low1 - height*0.25;
         double target= s.entry+height;
         s.stop=stop;
         s.target=target;
         s.timestamp=TimeCurrent();
         s.strategy="WedgeRev";
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

#endif // INTEGRATEDPA_WEDGEREVERSAL_MQH
