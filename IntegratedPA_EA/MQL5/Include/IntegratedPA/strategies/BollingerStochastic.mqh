#ifndef INTEGRATEDPA_BOLLINGERSTOCHASTIC_MQH
#define INTEGRATEDPA_BOLLINGERSTOCHASTIC_MQH
#include "../Defs.mqh"
#include "../Utils.mqh"

// Strategy combining Bollinger Bands context with Stochastic timing
class BollingerStochastic
{
private:
   bool m_buy;
public:
   BollingerStochastic():m_buy(false){}
   ~BollingerStochastic(){}

   // Identify setup according to guide lines 3600-3625
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf)
   {
      double ema9=GetEMA(symbol,tf,9);
      double ema50=GetEMA(symbol,tf,50);
      double vwap=GetVWAP(symbol,tf);
      double atr =GetATR(symbol,tf,14);
      double upper,middle,lower;
      if(!GetBB(symbol,tf,20,2.0,1,upper,middle,lower))
         return false;
      double width=upper-lower;
      if(atr>0.0 && width<2*atr) // Bollinger must be open
         return false;

      double kPrev,dPrev,kCur,dCur;
      if(!GetStochastic(symbol,tf,14,3,3,1,kPrev,dPrev))
         return false;
      if(!GetStochastic(symbol,tf,14,3,3,0,kCur,dCur))
         return false;

      double close0=iClose(symbol,tf,0);

      // bullish scenario
      if(close0>ema9 && close0>ema50 && close0>vwap && kPrev<20 && kCur>kPrev && kCur>20)
      {
         m_buy=true;
         return true;
      }
      // bearish scenario
      if(close0<ema9 && close0<ema50 && close0<vwap && kPrev>80 && kCur<kPrev && kCur<80)
      {
         m_buy=false;
         return true;
      }
      return false;
   }

   Signal GenerateSignal(const string symbol,ENUM_TIMEFRAMES tf)
   {
      Signal s; s.valid=false;
      if(!Identify(symbol,tf))
         return s;

      double ema9 =GetEMA(symbol,tf,9);
      double ema50=GetEMA(symbol,tf,50);
      double upper,middle,lower;
      GetBB(symbol,tf,20,2.0,0,upper,middle,lower);
      double entry=iClose(symbol,tf,0);
      double stop, target;

      if(m_buy)
      {
         stop=MathMin(iLow(symbol,tf,1),ema9);
         target=MathMax(ema50,middle);
         if(target<entry) target=upper;
         s.direction=SIGNAL_BUY;
      }
      else
      {
         stop=MathMax(iHigh(symbol,tf,1),ema9);
         target=MathMin(ema50,middle);
         if(target>entry) target=lower;
         s.direction=SIGNAL_SELL;
      }

      s.valid=true;
      s.phase=PHASE_TREND;
      s.entry=entry;
      s.stop=stop;
      s.target=target;
      s.timestamp=TimeCurrent();
      s.strategy="BollStoch";

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
};

#endif // INTEGRATEDPA_BOLLINGERSTOCHASTIC_MQH
