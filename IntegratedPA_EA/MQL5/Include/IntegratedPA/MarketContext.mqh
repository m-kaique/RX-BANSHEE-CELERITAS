#ifndef INTEGRATEDPA_MARKETCONTEXT_MQH
#define INTEGRATEDPA_MARKETCONTEXT_MQH
#include "Utils.mqh"

/// Informacoes retornadas pela analise de contexto
struct PhaseInfo
{
   MARKET_PHASE phase; ///< fase detectada
   string desc;        ///< justificativa tecnica
};

// parametros padrao de indicadores
#define DEFAULT_RSI_PERIOD 14
#define DEFAULT_ATR_PERIOD 14

/// Classe responsavel por avaliar o contexto de mercado
class MarketContextAnalyzer
{
public:
   MarketContextAnalyzer() {}
   ~MarketContextAnalyzer() {}

private:
   // garante que ha historico suficiente
   bool EnsureHistory(const string symbol, ENUM_TIMEFRAMES tf, int bars)
   {
      MqlRates rates[];
      if (CopyRates(symbol, tf, 0, bars, rates) != bars)
         return false;
      return true;
   }

   // obtém valores do MACD (linha principal e sinal)
   bool GetMACD(const string symbol, ENUM_TIMEFRAMES tf, int fast, int slow, int signal,
                double &main, double &sig)
   {
      int handle = iMACD(symbol, tf, fast, slow, signal, PRICE_CLOSE);
      if (handle == INVALID_HANDLE)
         return false;
      double bufMain[1];
      double bufSig[1];
      bool ok = (CopyBuffer(handle, 0, 0, 1, bufMain) == 1 &&
                 CopyBuffer(handle, 1, 0, 1, bufSig) == 1);
      IndicatorRelease(handle);
      if (!ok)
         return false;
      main = bufMain[0];
      sig = bufSig[0];
      return true;
   }

   // detecta um pinbar simples
   bool IsPinbar(const string symbol, ENUM_TIMEFRAMES tf, int shift = 0)
   {
      double open = iOpen(symbol, tf, shift);
      double close = iClose(symbol, tf, shift);
      double high = iHigh(symbol, tf, shift);
      double low = iLow(symbol, tf, shift);
      double body = MathAbs(close - open);
      double range = high - low;
      if (range <= 0.0)
         return false;
      double upper = high - MathMax(open, close);
      double lower = MathMin(open, close) - low;
      return (body / range <= 0.3 &&
              ((upper >= 2 * body && upper >= 0.5 * range) ||
               (lower >= 2 * body && lower >= 0.5 * range)));
   }

   // detecta candle engulfing basico
   bool IsEngulfing(const string symbol, ENUM_TIMEFRAMES tf)
   {
      double o0 = iOpen(symbol, tf, 0);
      double c0 = iClose(symbol, tf, 0);
      double o1 = iOpen(symbol, tf, 1);
      double c1 = iClose(symbol, tf, 1);
      bool bull0 = c0 > o0;
      bool bull1 = c1 > o1;
      if (bull0 && !bull1 && c0 > o1 && o0 < c1)
         return true;
      if (!bull0 && bull1 && c0 < o1 && o0 > c1)
         return true;
      return false;
   }

   //================================================================================
   // Modificações para MarketContext.mqh - Função IsTrendPhase() otimizada
   //================================================================================
   bool IsTrendPhase(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr, string &desc)
   {

      double ema9 = GetEMA(symbol, tf, EMA_SONIC_PERIOD);
      double ema20 = GetEMA(symbol, tf, EMA_FAST_PERIOD);
      double ema50 = GetEMA(symbol, tf, EMA_MEDIUM_PERIOD);

      // Avalia a inclinação das EMAs para timeframes muito curtos
      double slope9  = GetEMASlope(symbol, tf, EMA_SONIC_PERIOD, 3);
      double slope20 = GetEMASlope(symbol, tf, EMA_FAST_PERIOD, 3);
      double slopeThr = AdaptiveSlopeThreshold(symbol, tf, 3);

      double rsi = GetRSI(symbol, tf, DEFAULT_RSI_PERIOD);

      double macdMain, macdSig;
      bool macdOk = GetMACD(symbol, tf, 10, 21, 7, macdMain, macdSig);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT); // WIN = 1.0

      double diff9_20 = MathAbs(ema9 - ema20) / point;
      double diff20_50 = MathAbs(ema20 - ema50) / point;


      bool slopeUpOk = true;
      bool slopeDownOk = true;
      if (tf == PERIOD_M3)
      {
         slopeUpOk = (slope9 > slopeThr && slope20 > slopeThr * 0.5);
         slopeDownOk = (slope9 < -slopeThr && slope20 < -slopeThr * 0.5);
      }

      bool upTrendEMAs = (ema9 > ema20 && diff9_20 > rangeThr &&
                          ema20 > ema50 && diff20_50 > rangeThr && slopeUpOk);

      // MACD: força recente de alta (main acima da signal).
      // RSI > 60: viés comprador está ativo, mas ainda não em sobrecompra (>70).
      bool upTrendIndicators = (macdOk && macdMain > macdSig && rsi > 60);

      if (upTrendEMAs && upTrendIndicators)
      {
         // Confirmar com OBV
         bool obvConfirm = CheckOBVTrendConfirmation(symbol, tf, true);
         bool bollingerConfirm = BollingerTrendConfirm(symbol, tf, true);

         if (obvConfirm && bollingerConfirm)
         {
            double obv = GetOBV(symbol, tf, VOLUME_REAL);
            double obvSma = GetOBVSMA(symbol, tf, 14);
            desc = "Tendência de Alta: EMAs alinhadas, MACD>signal, RSI=" +
                   DoubleToString(rsi, 1);
            if (tf == PERIOD_M3)
               desc += ", slope=" + DoubleToString(slope9, 2);
            desc += ", OBV confirmando (" +
                    DoubleToString(obv, 0) + " vs SMA=" + DoubleToString(obvSma, 0) + ")";

            Print("diff9_20 ->>>>>>>>>> " + (string)diff9_20);
            Print("diff20_50 ->>>>>>>>>> " + (string)diff20_50);
            Print(desc);
            return true;
         }
      }

      // Verificação de tendência de baixa
      bool downTrendEMAs = (ema9 < ema20 && diff9_20 > rangeThr &&
                            ema20 < ema50 && diff20_50 > rangeThr && slopeDownOk);
      bool downTrendIndicators = (macdOk && macdMain < macdSig && rsi < 40);

      if (downTrendEMAs && downTrendIndicators)
      {
         // Confirmar com OBV
         bool obvConfirm = CheckOBVTrendConfirmation(symbol, tf, false);
         bool bollingerConfirm = BollingerTrendConfirm(symbol, tf, false);

         if (obvConfirm && bollingerConfirm)
         {
            double obv = GetOBV(symbol, tf, VOLUME_REAL);
            double obvSma = GetOBVSMA(symbol, tf, 14);
            desc = "Tendência de Baixa: EMAs alinhadas, MACD<signal, RSI=" +
                   DoubleToString(rsi, 1);
            if (tf == PERIOD_M3)
               desc += ", slope=" + DoubleToString(slope9, 2);
            desc += ", OBV confirmando (" +
                    DoubleToString(obv, 0) + " vs SMA=" + DoubleToString(obvSma, 0) + ")";
            Print(desc);
            return true;
         }
      }
      
      return false;
   }

   bool IsRangePhase(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr, string &desc)
   {
      double ema20 = GetEMA(symbol, tf, EMA_FAST_PERIOD);
      double ema50 = GetEMA(symbol, tf, EMA_MEDIUM_PERIOD);
      double sma200 = GetEMA(symbol, tf, EMA_SLOW_PERIOD);
      double rsi = GetRSI(symbol, tf, DEFAULT_RSI_PERIOD);
      double atr = GetATR(symbol, tf, DEFAULT_ATR_PERIOD);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double diff20_50 = MathAbs(ema20 - ema50) / point;
      double diff50_200 = MathAbs(ema50 - sma200) / point;
      bool emaClose = (diff20_50 <= rangeThr && diff50_200 <= rangeThr);
      bool rsiMid = (rsi >= 40 && rsi <= 60);
      bool atrLow = (atr / point <= rangeThr);
      if (emaClose && rsiMid && atrLow)
      {
         desc = "EMAs proximas, RSI=" + DoubleToString(rsi, 1) + ", ATR baixo";
         return true;
      }
      return false;
   }

   bool IsReversalPhase(const string symbol, ENUM_TIMEFRAMES tf, string &desc)
   {
      double rsi0 = GetRSI(symbol, tf, DEFAULT_RSI_PERIOD, 0);
      double rsi1 = GetRSI(symbol, tf, DEFAULT_RSI_PERIOD, 1);
      double price0 = iClose(symbol, tf, 0);
      double price1 = iClose(symbol, tf, 1);
      bool bearishDiv = (price0 > price1 && rsi0 < rsi1 && rsi0 > 70);
      bool bullishDiv = (price0 < price1 && rsi0 > rsi1 && rsi0 < 30);
      bool overbought = (rsi0 > 75);
      bool oversold = (rsi0 < 25);
      bool candle = (IsPinbar(symbol, tf) || IsEngulfing(symbol, tf));
      if ((bearishDiv && overbought) || (bullishDiv && oversold) || ((overbought || oversold) && candle))
      {
         desc = "Divergencia RSI e candle de reversao";
         return true;
      }
      return false;
   }

public:
   /// Analisa apenas um timeframe
   PhaseInfo DetectPhaseSingle(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr = 10.0)
   {
      PhaseInfo info;
      info.phase = PHASE_UNDEFINED;
      info.desc = "";
      if (!EnsureHistory(symbol, tf, 200))
      {
         info.desc = "historico insuficiente";
         return info;
      }
      string d;
      if (IsTrendPhase(symbol, tf, rangeThr, d))
      {
         info.phase = PHASE_TREND;
         info.desc = d;
         return info;
      }
      // if (IsRangePhase(symbol, tf, rangeThr, d))
      // {
      //    info.phase = PHASE_RANGE;
      //    info.desc = d;
      //    return info;
      // }
      // if (IsReversalPhase(symbol, tf, d))
      // {
      //    info.phase = PHASE_REVERSAL;
      //    info.desc = d;
      //    return info;
      // }
      info.desc = "condicoes neutras";
      return info;
   }

   /// Analise multi-timeframe ate 4 periodos
   PhaseInfo DetectPhaseMTF(const string symbol, const ENUM_TIMEFRAMES &tfs[], int count,
                            double rangeThr = 10.0)
   {
      PhaseInfo localInfos[4];
      string details = "";
      int use = (count > 4) ? 4 : count;
      for (int i = 0; i < use; i++)
      {
         localInfos[i] = DetectPhaseSingle(symbol, tfs[i], rangeThr);
         details += EnumToString(tfs[i]) + ":" + localInfos[i].desc + " ";
      }
      MARKET_PHASE phase = localInfos[use - 1].phase; // comeca pelo timeframe mais alto fornecido
      for (int j = use - 2; j >= 0; j--)
      {
         MARKET_PHASE ctx = phase;
         MARKET_PHASE local = localInfos[j].phase;
         if (ctx == local)
            phase = local;
         else if (ctx != PHASE_UNDEFINED)
            phase = ctx;
         else
            phase = local;
      }
      PhaseInfo res;
      res.phase = phase;
      res.desc = details;
      return res;
   }

   // versoes compativeis com a implementacao antiga
   MARKET_PHASE DetectPhase(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr = 10.0)
   {
      return DetectPhaseSingle(symbol, tf, rangeThr).phase;
   }

  MARKET_PHASE DetectPhaseMTF(const string symbol, ENUM_TIMEFRAMES tf, ENUM_TIMEFRAMES ctxTf, double rangeThr = 10.0)
  {
     ENUM_TIMEFRAMES arr[2];
     arr[0] = tf;
     arr[1] = ctxTf;
     return DetectPhaseMTF(symbol, arr, 2, rangeThr).phase;
  }
};

//---------------------------------------------------------------------------
// Support/Resistance zone detection helpers
//---------------------------------------------------------------------------

/// Find support zones on the last `bars` completed candles. Zones are grouped
/// within +/-0.5 ATR of each other. Returns the number of detected zones and
/// fills the `zones` array with the zone center prices sorted ascending.
/// Sort helper used when ArraySort constants are unavailable
inline void SortDoubleArray(double &arr[], int count, bool ascend)
{
   for(int i=0;i<count-1;i++)
   {
      for(int j=i+1;j<count;j++)
      {
         if((ascend && arr[i]>arr[j]) || (!ascend && arr[i]<arr[j]))
         {
            double tmp=arr[i];
            arr[i]=arr[j];
            arr[j]=tmp;
         }
      }
   }
}

inline int FindSupportZones(const string symbol, ENUM_TIMEFRAMES tf,
                            int bars, double &zones[])
{
   double lows[];
   if (CopyLow(symbol, tf, 1, bars, lows) != bars)
      return 0;

   double atr = GetATR(symbol, tf, DEFAULT_ATR_PERIOD);
   double thr = atr * 0.5;

   int count = 0;
   for (int i = 1; i < bars - 1; i++)
   {
      if (lows[i] <= lows[i - 1] && lows[i] <= lows[i + 1])
      {
         double lvl = lows[i];
         bool merged = false;
         for (int j = 0; j < count; j++)
         {
            if (MathAbs(lvl - zones[j]) <= thr)
            {
               zones[j] = (zones[j] + lvl) / 2.0;
               merged = true;
               break;
            }
         }
         if (!merged)
         {
            ArrayResize(zones, count + 1);
            zones[count++] = lvl;
         }
      }
   }
   SortDoubleArray(zones, count, true);
   return count;
}

/// Find resistance zones on the last `bars` completed candles. Zones are
/// grouped within +/-0.5 ATR of each other. Returns the number of detected
/// zones and fills the `zones` array with the zone center prices sorted
/// descending.
inline int FindResistanceZones(const string symbol, ENUM_TIMEFRAMES tf,
                               int bars, double &zones[])
{
   double highs[];
   if (CopyHigh(symbol, tf, 1, bars, highs) != bars)
      return 0;

   double atr = GetATR(symbol, tf, DEFAULT_ATR_PERIOD);
   double thr = atr * 0.5;

   int count = 0;
   for (int i = 1; i < bars - 1; i++)
   {
      if (highs[i] >= highs[i - 1] && highs[i] >= highs[i + 1])
      {
         double lvl = highs[i];
         bool merged = false;
         for (int j = 0; j < count; j++)
         {
            if (MathAbs(lvl - zones[j]) <= thr)
            {
               zones[j] = (zones[j] + lvl) / 2.0;
               merged = true;
               break;
            }
         }
         if (!merged)
         {
            ArrayResize(zones, count + 1);
            zones[count++] = lvl;
         }
      }
   }
   SortDoubleArray(zones, count, false);
   return count;
}

/// Helper to obtain the nearest value in `zones` to `price`.
inline double NearestZoneValue(const double &zones[], int count, double price)
{
   if (count <= 0)
      return 0.0;
   double best = zones[0];
   double dist = MathAbs(price - best);
   for (int i = 1; i < count; i++)
   {
      double d = MathAbs(price - zones[i]);
      if (d < dist)
      {
         dist = d;
         best = zones[i];
      }
   }
   return best;
}

/// Return the nearest support zone price from the last `bars` candles.
inline double FindNearestSupport(const string symbol, ENUM_TIMEFRAMES tf,
                                 int bars)
{
   double zones[];
   int cnt = FindSupportZones(symbol, tf, bars, zones);
   double price = iClose(symbol, tf, 1);
   return NearestZoneValue(zones, cnt, price);
}

/// Return the nearest resistance zone price from the last `bars` candles.
inline double FindNearestResistance(const string symbol, ENUM_TIMEFRAMES tf,
                                    int bars)
{
   double zones[];
   int cnt = FindResistanceZones(symbol, tf, bars, zones);
   double price = iClose(symbol, tf, 1);
   return NearestZoneValue(zones, cnt, price);
}

// compatibilidade com nome antigo
#define MarketContext MarketContextAnalyzer

#endif // INTEGRATEDPA_MARKETCONTEXT_MQH
