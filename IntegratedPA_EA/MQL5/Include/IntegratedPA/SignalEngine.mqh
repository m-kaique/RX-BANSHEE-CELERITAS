// Definições padrão para evitar erros do linter
// Estas serão sobrescritas pelos valores reais quando incluído no EA principal
#ifndef HAS_USE_SPIKE_AND_CHANNEL
   #define UseSpikeAndChannel false
#endif

#ifndef HAS_USE_RANGE_BREAKOUT
   #define UseRangeBreakout false
#endif

#ifndef HAS_USE_RANGE_FADE
   #define UseRangeFade false
#endif

#ifndef HAS_USE_WEDGE_REVERSAL
   #define UseWedgeReversal false
#endif

#ifndef HAS_USE_MEAN_REV_50200
   #define UseMeanReversion50200 false
#endif

#ifndef HAS_USE_VWAP_REVERSION
   #define UseVWAPReversion false
#endif

#ifndef HAS_USE_PULLBACK_MA
   #define UsePullbackMA false
#endif

#ifndef HAS_USE_FIBONACCI_RETRACE
   #define UseFibonacciRetrace false
#endif

#ifndef HAS_USE_BOLLINGER_STOCH
   #define UseBollingerStochastic false
#endif

#ifndef HAS_USE_TREND_RANGE_DAY
   #define UseTrendRangeDay false
#endif

#ifndef INTEGRATEDPA_SIGNALENGINE_MQH
#define INTEGRATEDPA_SIGNALENGINE_MQH
#include "Defs.mqh"
#include "Utils.mqh"
#include "strategies/TrendRangeDay.mqh"
#include "strategies/WedgeReversal.mqh"
#include "strategies/SpikeAndChannel.mqh"
#include "strategies/PullbackToMA.mqh"
#include "strategies/RangeFade.mqh"
#include "strategies/RangeBreakout.mqh"
#include "strategies/MeanReversion50to200.mqh"
#include "strategies/VWAPReversion.mqh"
#include "strategies/BollingerStochastic.mqh"
#include "strategies/FibonacciRetrace.mqh"
 

class SignalEngine
{
public:
   SignalEngine(){}
   ~SignalEngine(){}

   // Gera sinal principal
   Signal Generate(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
   {
      Signal s; s.valid=false;

      if(UseSpikeAndChannel)
      {
         SpikeAndChannel sac;
         if(sac.Identify(symbol,tf,asset))
            return sac.GenerateSignal(symbol,tf,asset);
      }

      if(UsePullbackMA)
      {
         PullbackToMA pb;
         if(pb.Identify(symbol,tf,asset))
            return pb.GenerateSignal(symbol,tf,asset);
      }

      if(UseFibonacciRetrace)
      {
         FibonacciRetrace fr;
         if(fr.Identify(symbol,tf,asset))
            return fr.GenerateSignal(symbol,tf,asset);
      }

      if(UseBollingerStochastic)
      {
         BollingerStochastic bs;
         if(bs.Identify(symbol,tf,asset))
            return bs.GenerateSignal(symbol,tf,asset);
      }

      if(UseTrendRangeDay)
      {
         TrendRangeDay trd;
         if(trd.Identify(symbol,tf,asset))
            return trd.GenerateSignal(symbol,tf,asset);
      }

      if(UseRangeBreakout)
      {
         RangeBreakout br;
         if(br.Identify(symbol,tf,asset))
            return br.GenerateSignal(symbol,tf,asset);
      }

      if(UseRangeFade)
      {
         RangeFade rf;
         if(rf.Identify(symbol,tf,asset))
            return rf.GenerateSignal(symbol,tf,asset);
      }

      if(UseWedgeReversal)
      {
         WedgeReversal wr;
         bool rising=false;
         if(wr.Identify(symbol,tf,rising,asset))
            return wr.GenerateSignal(symbol,tf,asset);
      }

      if(UseMeanReversion50200)
      {
         MeanReversion50to200 mr;
         bool buy=false;
         if(mr.Identify(symbol,tf,buy,asset))
            return mr.GenerateSignal(symbol,tf,asset);
      }

      if(UseVWAPReversion)
      {
         VWAPReversion vr;
         bool buy2=false;
         if(vr.Identify(symbol,tf,buy2,asset))
            return vr.GenerateSignal(symbol,tf,asset);
      }

      return s;
   }
};

#endif // INTEGRATEDPA_SIGNALENGINE_MQH
