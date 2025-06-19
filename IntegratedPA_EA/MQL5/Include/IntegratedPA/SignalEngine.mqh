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
   Signal Generate(const AssetConfig &asset, MARKET_PHASE phase, ENUM_TIMEFRAMES tf)
   {
      const string symbol = asset.symbol;
      Signal s; s.valid=false;
      switch(phase)
      {
         case PHASE_TREND:
            s=GenerateTrendSignals(asset,tf);
            break;
         // case PHASE_RANGE:
         //    s=GenerateRangeSignals(asset,tf);
         //    break;
         // case PHASE_REVERSAL:
         //    s=GenerateReversalSignals(symbol,tf);
         //    break;
         default:
            break;
      }
      return s;
   }

private:
   // Estratégias de tendência
   Signal GenerateTrendSignals(const AssetConfig &asset, ENUM_TIMEFRAMES tf)
   {
      const string symbol = asset.symbol;
      Signal s; s.valid=false;
      // Prefer Spike and Channel detection before other trend strategies
      SpikeAndChannel sac;
      if(UseSpikeAndChannel && sac.Identify(symbol,tf))
         return sac.GenerateSignal(symbol,tf);

      // PullbackToMA pb;
      // if(UsePullbackMA && pb.Identify(symbol,tf))
      //    return pb.GenerateSignal(symbol,tf);

      // FibonacciRetrace fr;
      // if(UseFibonacciRetrace && fr.Identify(symbol,tf))
      //    return fr.GenerateSignal(symbol,tf);

      // BollingerStochastic bs;
      // if(UseBollingerStochastic && bs.Identify(symbol,tf))
      //    return bs.GenerateSignal(symbol,tf);

      // TrendRangeDay trd;
      // if(UseTrendRangeDay && trd.Identify(symbol,tf))
      //    return trd.GenerateSignal(symbol,tf);

      return s;
   }

   // Estratégias de range
   Signal GenerateRangeSignals(const AssetConfig &asset, ENUM_TIMEFRAMES tf)
   {
      const string symbol = asset.symbol;
      Signal s; s.valid=false;
      RangeBreakout br;
      if(UseRangeBreakout && br.Identify(symbol,tf))
         return br.GenerateSignal(symbol,tf,asset.srLookback);

      RangeFade rf;
      if(UseRangeFade && rf.Identify(symbol,tf))
         return rf.GenerateSignal(symbol,tf,asset.srLookback);

      return s;
   }

   // Estratégias de reversão
  Signal GenerateReversalSignals(const AssetConfig &asset, ENUM_TIMEFRAMES tf)
  {
      const string symbol = asset.symbol;
      Signal s; s.valid=false;
      WedgeReversal wr;
      bool isRising=false;
      if(UseWedgeReversal && wr.Identify(symbol,tf,isRising))
         return wr.GenerateSignal(symbol,tf);

      MeanReversion50to200 mr;
      bool buy=false;
      if(UseMeanReversion50200 && mr.Identify(symbol,tf,buy))
         return mr.GenerateSignal(symbol,tf);

      VWAPReversion vr;
      bool buy2=false;
      if(UseVWAPReversion && vr.Identify(symbol,tf,buy2))
         return vr.GenerateSignal(symbol,tf);

      return s;
  }
};

#endif // INTEGRATEDPA_SIGNALENGINE_MQH
