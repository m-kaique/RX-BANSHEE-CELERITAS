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

   //==============================================================
   // Algoritmos importados de new_MarketContext.mqh
   //==============================================================

   bool CheckMovingAveragesAlignment(const string symbol, ENUM_TIMEFRAMES tf)
   {
      int h9 = GetEMAHandle(symbol, tf, 9);
      int h21 = GetEMAHandle(symbol, tf, 21);
      int h50 = GetEMAHandle(symbol, tf, 50);
      int h200 = GetEMAHandle(symbol, tf, 200);
      if (h9 == INVALID_HANDLE || h21 == INVALID_HANDLE ||
          h50 == INVALID_HANDLE || h200 == INVALID_HANDLE)
         return false;

      double b9[], b21[], b50[], b200[];
      ArraySetAsSeries(b9, true);
      ArraySetAsSeries(b21, true);
      ArraySetAsSeries(b50, true);
      ArraySetAsSeries(b200, true);

      if (CopyBuffer(h9, 0, 0, 1, b9) <= 0 || CopyBuffer(h21, 0, 0, 1, b21) <= 0 ||
          CopyBuffer(h50, 0, 0, 1, b50) <= 0 || CopyBuffer(h200, 0, 0, 1, b200) <= 0)
         return false;

      bool up = (b9[0] > b21[0] && b21[0] > b50[0] && b50[0] > b200[0]);
      bool down = (b9[0] < b21[0] && b21[0] < b50[0] && b50[0] < b200[0]);
      return (up || down);
   }

   bool CheckMomentum(const string symbol, ENUM_TIMEFRAMES tf)
   {
      double macdMain, macdSig;
      if (!GetMACD(symbol, tf, 12, 26, 9, macdMain, macdSig))
         return false;
      if (macdMain > macdSig && macdMain > 0)
         return true;
      if (macdMain < macdSig && macdMain < 0)
         return true;
      return false;
   }

   int CheckTrendDirection(const string symbol, ENUM_TIMEFRAMES tf)
   {
      int h9 = GetEMAHandle(symbol, tf, 9);
      int h21 = GetEMAHandle(symbol, tf, 21);
      int h50 = GetEMAHandle(symbol, tf, 50);
      int h200 = GetEMAHandle(symbol, tf, 200);
      if (h9 == INVALID_HANDLE || h21 == INVALID_HANDLE ||
          h50 == INVALID_HANDLE || h200 == INVALID_HANDLE)
         return 0;

      double b9[], b21[], b50[], b200[];
      ArraySetAsSeries(b9, true);
      ArraySetAsSeries(b21, true);
      ArraySetAsSeries(b50, true);
      ArraySetAsSeries(b200, true);

      if (CopyBuffer(h9, 0, 0, 1, b9) <= 0 || CopyBuffer(h21, 0, 0, 1, b21) <= 0 ||
          CopyBuffer(h50, 0, 0, 1, b50) <= 0 || CopyBuffer(h200, 0, 0, 1, b200) <= 0)
         return 0;

      if (b9[0] > b21[0] && b21[0] > b50[0] && b50[0] > b200[0])
         return 1;
      if (b9[0] < b21[0] && b21[0] < b50[0] && b50[0] < b200[0])
         return -1;
      return 0;
   }

   bool IsTrendPhase(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr, string &desc)
   {
      if (!CheckMovingAveragesAlignment(symbol, tf))
         return false;
      if (!CheckMomentum(symbol, tf))
         return false;

      int rsiHandle = GetRSIHandle(symbol, tf, DEFAULT_RSI_PERIOD);
      if (rsiHandle == INVALID_HANDLE)
         return false;

      double rsiBuf[1];
      if (CopyBuffer(rsiHandle, 0, 0, 1, rsiBuf) <= 0)
         return false;

      double rsi = rsiBuf[0];
      int dir = CheckTrendDirection(symbol, tf);
      if (dir > 0 && rsi < 60)
         return false;
      if (dir < 0 && rsi > 40)
         return false;


      SRZone near_supp = FindNearestSupport(_Symbol, PERIOD_M3, 50);
      SRZone near_ress = FindNearestResistance(_Symbol, PERIOD_M3, 50);
      DrawSupportResistanceLines(_Symbol, PERIOD_M3, near_supp, near_ress);
      desc = "Trend";
      if (dir > 0)
         desc += " up";
      else if (dir < 0)
         desc += " down";
      desc += ", RSI=" + DoubleToString(rsi, 1);
      Print("Near Supp: "+DoubleToString(near_supp.lower, _Digits)+ "-"+
            DoubleToString(near_supp.upper, _Digits)+
            " , Near Ress: " +
            DoubleToString(near_ress.lower, _Digits)+ "-"+
            DoubleToString(near_ress.upper, _Digits));
      Print("#####   " + desc + "  #####   ");
      return true;
   }

   bool IsRangePhase(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr, string &desc)
   {
      int h9 = GetEMAHandle(symbol, tf, 9);
      int h21 = GetEMAHandle(symbol, tf, 21);
      int h50 = GetEMAHandle(symbol, tf, 50);
      int hAtr = GetATRHandle(symbol, tf, DEFAULT_ATR_PERIOD);
      int hRsi = GetRSIHandle(symbol, tf, DEFAULT_RSI_PERIOD);
      if (h9 == INVALID_HANDLE || h21 == INVALID_HANDLE || h50 == INVALID_HANDLE ||
          hAtr == INVALID_HANDLE || hRsi == INVALID_HANDLE)
         return false;

      double b9[], b21[], b50[], atrBuf[], rsiBuf[];
      ArraySetAsSeries(b9, true);
      ArraySetAsSeries(b21, true);
      ArraySetAsSeries(b50, true);
      ArraySetAsSeries(atrBuf, true);
      ArraySetAsSeries(rsiBuf, true);

      if (CopyBuffer(h9, 0, 0, 3, b9) <= 0 || CopyBuffer(h21, 0, 0, 3, b21) <= 0 ||
          CopyBuffer(h50, 0, 0, 3, b50) <= 0 || CopyBuffer(hAtr, 0, 0, 1, atrBuf) <= 0 ||
          CopyBuffer(hRsi, 0, 0, 1, rsiBuf) <= 0)
         return false;

      double distance1 = MathAbs(b9[0] - b21[0]);
      double distance2 = MathAbs(b21[0] - b50[0]);
      double atr = atrBuf[0];
      double n1 = distance1 / atr;
      double n2 = distance2 / atr;
      if (n1 > 0.5 || n2 > 1.0)
         return false;

      double rsi = rsiBuf[0];
      if (rsi < 40 || rsi > 60)
         return false;

      desc = "Range: RSI=" + DoubleToString(rsi, 1);
      return true;
   }

   bool IsReversalPhase(const string symbol, ENUM_TIMEFRAMES tf, string &desc)
   {
      int rsiHandle = GetRSIHandle(symbol, tf, DEFAULT_RSI_PERIOD);
      int ema9Handle = GetEMAHandle(symbol, tf, 9);
      int ema21Handle = GetEMAHandle(symbol, tf, 21);
      if (rsiHandle == INVALID_HANDLE || ema9Handle == INVALID_HANDLE || ema21Handle == INVALID_HANDLE)
         return false;

      double rsiBuf[];
      double closeBuf[];
      double ema9Buf[];
      double ema21Buf[];
      ArrayResize(rsiBuf, 10);
      ArrayResize(closeBuf, 10);
      ArrayResize(ema9Buf, 3);
      ArrayResize(ema21Buf, 3);
      ArraySetAsSeries(rsiBuf, true);
      ArraySetAsSeries(closeBuf, true);
      ArraySetAsSeries(ema9Buf, true);
      ArraySetAsSeries(ema21Buf, true);

      if (CopyBuffer(rsiHandle, 0, 0, 10, rsiBuf) != 10 ||
          CopyClose(symbol, tf, 0, 10, closeBuf) != 10 ||
          CopyBuffer(ema9Handle, 0, 0, 3, ema9Buf) != 3 ||
          CopyBuffer(ema21Handle, 0, 0, 3, ema21Buf) != 3)
         return false;

      double rsi0 = rsiBuf[0];
      double rsi1 = rsiBuf[1];
      double price0 = closeBuf[0];
      double price1 = closeBuf[1];

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
   /// Find nearest support zone below the current price
   SRZone FindNearestSupport(const string symbol, ENUM_TIMEFRAMES tf,
                             int lookback)
   {
      SRZone zone;
      if (!EnsureHistory(symbol, tf, lookback + 1))
         return zone;
      double lows[];
      ArraySetAsSeries(lows, true);
      if (CopyLow(symbol, tf, 1, lookback, lows) != lookback)
         return zone;
      double price = iClose(symbol, tf, 0);
      double level = 0.0;
      bool found = false;
      double pivots[3];
      int pcount = 0;
      for (int i = 1; i < lookback - 1 && pcount < 3; i++)
      {
         double prev = iLow(symbol, tf, i + 1);
         double curr = iLow(symbol, tf, i);
         double next = iLow(symbol, tf, i - 1);
         if (curr <= prev && curr <= next && curr < price)
         {
            pivots[pcount++] = curr;
            if (!found || curr > level)
            {
               level = curr;
               found = true;
            }
         }
      }
      if (!found)
      {
         int idx = ArrayMinimum(lows);
         level = lows[idx];
         pivots[0] = level;
         pcount = 1;
      }
      double avg = 0.0;
      for (int j = 0; j < pcount; j++)
         avg += pivots[j];
      avg /= pcount;
      double tol = GetATR(symbol, tf, 14) * 0.25;
      if (tol <= 0.0)
         tol = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
      zone.upper = avg + tol;
      zone.lower = avg - tol;
      return zone;
   }

   /// Find nearest resistance zone above the current price
   SRZone FindNearestResistance(const string symbol, ENUM_TIMEFRAMES tf,
                                int lookback)
   {
      SRZone zone;
      if (!EnsureHistory(symbol, tf, lookback + 1))
         return zone;
      double highs[];
      ArraySetAsSeries(highs, true);
      if (CopyHigh(symbol, tf, 1, lookback, highs) != lookback)
         return zone;
      double price = iClose(symbol, tf, 0);
      double level = 0.0;
      bool found = false;
      double pivots[3];
      int pcount = 0;
      for (int i = 1; i < lookback - 1 && pcount < 3; i++)
      {
         double prev = iHigh(symbol, tf, i + 1);
         double curr = iHigh(symbol, tf, i);
         double next = iHigh(symbol, tf, i - 1);
         if (curr >= prev && curr >= next && curr > price)
         {
            pivots[pcount++] = curr;
            if (!found || curr < level)
            {
               level = curr;
               found = true;
            }
         }
      }
      if (!found)
      {
         int idx = ArrayMaximum(highs);
         level = highs[idx];
         pivots[0] = level;
         pcount = 1;
      }
      double avg = 0.0;
      for (int j = 0; j < pcount; j++)
         avg += pivots[j];
      avg /= pcount;
      double tol = GetATR(symbol, tf, 14) * 0.25;
      if (tol <= 0.0)
         tol = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
      zone.upper = avg + tol;
      zone.lower = avg - tol;
      return zone;
   }

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

// compatibilidade com nome antigo
#define MarketContext MarketContextAnalyzer

#endif // INTEGRATEDPA_MARKETCONTEXT_MQH
