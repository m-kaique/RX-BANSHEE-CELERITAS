#ifndef INTEGRATEDPA_UTILS_MQH
#define INTEGRATEDPA_UTILS_MQH
#include <Trade/SymbolInfo.mqh>
#include "Defs.mqh"

//+------------------------------------------------------------------+
//| Constantes                                                       |
//+------------------------------------------------------------------+
#define EMA_SONIC_PERIOD 9
#define EMA_FAST_PERIOD 20
#define EMA_MEDIUM_PERIOD 50
#define EMA_SLOW_PERIOD 200

//+------------------------------------------------------------------+
//| Funções auxiliares                                               |
//+------------------------------------------------------------------+


// structure to cache SMA indicator handles
struct SMAHandle
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   int period;
   int handle;
};

static SMAHandle g_smaHandles[];

// structure to cache EMA indicator handles
struct EMAHandle
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   int period;
   int handle;
};

// global array storing opened EMA handles
static EMAHandle g_emaHandles[];

// cache for simple VWAP calculations per day
struct VWAPCache
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   datetime day;
   double value;
};

static VWAPCache g_vwapCache[];

// structure to cache ATR indicator handles
struct ATRHandle
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   int period;
   int handle;
};

static ATRHandle g_atrHandles[];

// structure to cache Bollinger Bands indicator handles
struct BBHandle
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   int period;
   double deviation;
   int handle;
};

static BBHandle g_bbHandles[];

// structure to cache Stochastic indicator handles
struct StochHandle
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   int k;
   int d;
   int slowing;
   int handle;
};

static StochHandle g_stochHandles[];

// structure to cache RSI indicator handles
struct RSIHandle
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   int period;
   int handle;
};

static RSIHandle g_rsiHandles[];

// estrutura para cachear handles do indicador Money Flow Index
struct MFIHandle
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   int period;
   int handle;
};

static MFIHandle g_mfiHandles[];

// estrutura para cachear handles do indicador On Balance Volume
struct OBVHandle
{
   string symbol;
   ENUM_TIMEFRAMES tf;
   ENUM_APPLIED_VOLUME volumeType;
   int handle;
};

static OBVHandle g_obvHandles[];

/// return cached SMA indicator handle or create a new one
inline int GetSMAHandle(const string symbol, ENUM_TIMEFRAMES tf, int period)
{
   for (int i = 0; i < ArraySize(g_smaHandles); i++)
   {
      if (g_smaHandles[i].symbol == symbol && g_smaHandles[i].tf == tf && g_smaHandles[i].period == period)
         return g_smaHandles[i].handle;
   }

   int handle = iMA(symbol, tf, period, 0, MODE_SMA, PRICE_CLOSE);
   if (handle != INVALID_HANDLE)
   {
      int idx = ArraySize(g_smaHandles);
      ArrayResize(g_smaHandles, idx + 1);
      g_smaHandles[idx].symbol = symbol;
      g_smaHandles[idx].tf = tf;
      g_smaHandles[idx].period = period;
      g_smaHandles[idx].handle = handle;
   }
   return handle;
}

/// release all cached SMA indicator handles
inline void ReleaseSMAHandles()
{
   for (int i = 0; i < ArraySize(g_smaHandles); i++)
   {
      if (g_smaHandles[i].handle != INVALID_HANDLE)
         IndicatorRelease(g_smaHandles[i].handle);
   }
   ArrayResize(g_smaHandles, 0);
}


/// return cached EMA indicator handle or create a new one
inline int GetEMAHandle(const string symbol, ENUM_TIMEFRAMES tf, int period)
{
   for (int i = 0; i < ArraySize(g_emaHandles); i++)
   {
      if (g_emaHandles[i].symbol == symbol && g_emaHandles[i].tf == tf && g_emaHandles[i].period == period)
         return g_emaHandles[i].handle;
   }

   int handle = iMA(symbol, tf, period, 0, MODE_EMA, PRICE_CLOSE);
   if (handle != INVALID_HANDLE)
   {
      int idx = ArraySize(g_emaHandles);
      ArrayResize(g_emaHandles, idx + 1);
      g_emaHandles[idx].symbol = symbol;
      g_emaHandles[idx].tf = tf;
      g_emaHandles[idx].period = period;
      g_emaHandles[idx].handle = handle;
   }
   return handle;
}

/// release all cached EMA indicator handles
inline void ReleaseEMAHandles()
{
   for (int i = 0; i < ArraySize(g_emaHandles); i++)
   {
      if (g_emaHandles[i].handle != INVALID_HANDLE)
         IndicatorRelease(g_emaHandles[i].handle);
   }
   ArrayResize(g_emaHandles, 0);
}

/// release VWAP cache
inline void ReleaseVWAPCache()
{
   ArrayResize(g_vwapCache, 0);
}

/// return cached ATR indicator handle or create a new one
inline int GetATRHandle(const string symbol, ENUM_TIMEFRAMES tf, int period)
{
   for (int i = 0; i < ArraySize(g_atrHandles); i++)
   {
      if (g_atrHandles[i].symbol == symbol && g_atrHandles[i].tf == tf && g_atrHandles[i].period == period)
         return g_atrHandles[i].handle;
   }

   int handle = iATR(symbol, tf, period);
   if (handle != INVALID_HANDLE)
   {
      int idx = ArraySize(g_atrHandles);
      ArrayResize(g_atrHandles, idx + 1);
      g_atrHandles[idx].symbol = symbol;
      g_atrHandles[idx].tf = tf;
      g_atrHandles[idx].period = period;
      g_atrHandles[idx].handle = handle;
   }
   return handle;
}

/// release all cached ATR indicator handles
inline void ReleaseATRHandles()
{
   for (int i = 0; i < ArraySize(g_atrHandles); i++)
   {
      if (g_atrHandles[i].handle != INVALID_HANDLE)
         IndicatorRelease(g_atrHandles[i].handle);
   }
   ArrayResize(g_atrHandles, 0);
}

/// return cached Bollinger Bands handle or create a new one
inline int GetBBHandle(const string symbol, ENUM_TIMEFRAMES tf, int period, double deviation)
{
   for (int i = 0; i < ArraySize(g_bbHandles); i++)
   {
      if (g_bbHandles[i].symbol == symbol && g_bbHandles[i].tf == tf && g_bbHandles[i].period == period && MathAbs(g_bbHandles[i].deviation - deviation) < 0.0001)
         return g_bbHandles[i].handle;
   }

   // iBands has signature iBands(symbol,tf,period,bands_shift,deviation,applied_price)
   // provide zero shift and PRICE_CLOSE as recommended
   int handle = iBands(symbol, tf, period, 0, deviation, PRICE_CLOSE);
   if (handle != INVALID_HANDLE)
   {
      int idx = ArraySize(g_bbHandles);
      ArrayResize(g_bbHandles, idx + 1);
      g_bbHandles[idx].symbol = symbol;
      g_bbHandles[idx].tf = tf;
      g_bbHandles[idx].period = period;
      g_bbHandles[idx].deviation = deviation;
      g_bbHandles[idx].handle = handle;
   }
   return handle;
}

/// release all cached Bollinger Bands handles
inline void ReleaseBBHandles()
{
   for (int i = 0; i < ArraySize(g_bbHandles); i++)
   {
      if (g_bbHandles[i].handle != INVALID_HANDLE)
         IndicatorRelease(g_bbHandles[i].handle);
   }
   ArrayResize(g_bbHandles, 0);
}

/// obtain Bollinger values (upper, middle, lower)
inline bool GetBB(const string symbol, ENUM_TIMEFRAMES tf, int period, double deviation, int shift, double &upper, double &middle, double &lower)
{
   int handle = GetBBHandle(symbol, tf, period, deviation);
   if (handle == INVALID_HANDLE)
      return false;
   double bufU[1];
   double bufL[1];
   double bufM[1];
   if (CopyBuffer(handle, 0, shift, 1, bufU) != 1)
      return false;
   if (CopyBuffer(handle, 1, shift, 1, bufL) != 1)
      return false;
   if (CopyBuffer(handle, 2, shift, 1, bufM) != 1)
      return false;
   upper = bufU[0];
   lower = bufL[0];
   middle = bufM[0];
   return true;
}

/// return cached Stochastic handle or create a new one
inline int GetStochasticHandle(const string symbol, ENUM_TIMEFRAMES tf, int k, int d, int slowing)
{
   for (int i = 0; i < ArraySize(g_stochHandles); i++)
   {
      if (g_stochHandles[i].symbol == symbol && g_stochHandles[i].tf == tf && g_stochHandles[i].k == k && g_stochHandles[i].d == d && g_stochHandles[i].slowing == slowing)
         return g_stochHandles[i].handle;
   }

   int handle = iStochastic(symbol, tf, k, d, slowing, MODE_SMA, STO_LOWHIGH);
   if (handle != INVALID_HANDLE)
   {
      int idx = ArraySize(g_stochHandles);
      ArrayResize(g_stochHandles, idx + 1);
      g_stochHandles[idx].symbol = symbol;
      g_stochHandles[idx].tf = tf;
      g_stochHandles[idx].k = k;
      g_stochHandles[idx].d = d;
      g_stochHandles[idx].slowing = slowing;
      g_stochHandles[idx].handle = handle;
   }
   return handle;
}

/// release all cached Stochastic handles
inline void ReleaseStochasticHandles()
{
   for (int i = 0; i < ArraySize(g_stochHandles); i++)
   {
      if (g_stochHandles[i].handle != INVALID_HANDLE)
         IndicatorRelease(g_stochHandles[i].handle);
   }
   ArrayResize(g_stochHandles, 0);
}

/// obtain Stochastic values %K and %D
inline bool GetStochastic(const string symbol, ENUM_TIMEFRAMES tf, int k, int d, int slowing, int shift, double &outK, double &outD)
{
   int handle = GetStochasticHandle(symbol, tf, k, d, slowing);
   if (handle == INVALID_HANDLE)
      return false;
   double bufK[1];
   double bufD[1];
   if (CopyBuffer(handle, 0, shift, 1, bufK) != 1)
      return false;
   if (CopyBuffer(handle, 1, shift, 1, bufD) != 1)
      return false;
   outK = bufK[0];
   outD = bufD[0];
   return true;
}

/// return cached RSI handle or create a new one
inline int GetRSIHandle(const string symbol, ENUM_TIMEFRAMES tf, int period)
{
   for (int i = 0; i < ArraySize(g_rsiHandles); i++)
   {
      if (g_rsiHandles[i].symbol == symbol && g_rsiHandles[i].tf == tf && g_rsiHandles[i].period == period)
         return g_rsiHandles[i].handle;
   }

   int handle = iRSI(symbol, tf, period, PRICE_CLOSE);
   if (handle != INVALID_HANDLE)
   {
      int idx = ArraySize(g_rsiHandles);
      ArrayResize(g_rsiHandles, idx + 1);
      g_rsiHandles[idx].symbol = symbol;
      g_rsiHandles[idx].tf = tf;
      g_rsiHandles[idx].period = period;
      g_rsiHandles[idx].handle = handle;
   }
   return handle;
}

/// release all cached RSI handles
inline void ReleaseRSIHandles()
{
   for (int i = 0; i < ArraySize(g_rsiHandles); i++)
   {
      if (g_rsiHandles[i].handle != INVALID_HANDLE)
         IndicatorRelease(g_rsiHandles[i].handle);
   }
   ArrayResize(g_rsiHandles, 0);
}

/// retorna handle do MFI ou cria um novo
inline int GetMFIHandle(const string symbol, ENUM_TIMEFRAMES tf, int period)
{
   for (int i = 0; i < ArraySize(g_mfiHandles); i++)
   {
      if (g_mfiHandles[i].symbol == symbol && g_mfiHandles[i].tf == tf && g_mfiHandles[i].period == period)
         return g_mfiHandles[i].handle;
   }
   // iMFI requer especificar o tipo de volume (doc MQL5)
   int handle = iMFI(symbol, tf, period, VOLUME_REAL);
   if (handle != INVALID_HANDLE)
   {
      int idx = ArraySize(g_mfiHandles);
      ArrayResize(g_mfiHandles, idx + 1);
      g_mfiHandles[idx].symbol = symbol;
      g_mfiHandles[idx].tf = tf;
      g_mfiHandles[idx].period = period;
      g_mfiHandles[idx].handle = handle;
   }
   return handle;
}

/// libera handles do MFI
inline void ReleaseMFIHandles()
{
   for (int i = 0; i < ArraySize(g_mfiHandles); i++)
   {
      if (g_mfiHandles[i].handle != INVALID_HANDLE)
         IndicatorRelease(g_mfiHandles[i].handle);
   }
   ArrayResize(g_mfiHandles, 0);
}

/// obtém valor do MFI
inline double GetMFI(const string symbol, ENUM_TIMEFRAMES tf, int period, int shift = 0)
{
   int handle = GetMFIHandle(symbol, tf, period);
   if (handle == INVALID_HANDLE)
      return 0.0;
   double buf[1];
   if (CopyBuffer(handle, 0, shift, 1, buf) != 1)
      return 0.0;
   return buf[0];
}

/// retorna handle do OBV ou cria um novo
inline int GetOBVHandle(const string symbol, ENUM_TIMEFRAMES tf, ENUM_APPLIED_VOLUME volType = VOLUME_REAL)
{
   for (int i = 0; i < ArraySize(g_obvHandles); i++)
   {
      if (g_obvHandles[i].symbol == symbol && g_obvHandles[i].tf == tf && g_obvHandles[i].volumeType == volType)
         return g_obvHandles[i].handle;
   }
   int handle = iOBV(symbol, tf, volType);
   if (handle != INVALID_HANDLE)
   {
      int idx = ArraySize(g_obvHandles);
      ArrayResize(g_obvHandles, idx + 1);
      g_obvHandles[idx].symbol = symbol;
      g_obvHandles[idx].tf = tf;
      g_obvHandles[idx].volumeType = volType;
      g_obvHandles[idx].handle = handle;
   }
   return handle;
}

/// libera handles do OBV
inline void ReleaseOBVHandles()
{
   for (int i = 0; i < ArraySize(g_obvHandles); i++)
   {
      if (g_obvHandles[i].handle != INVALID_HANDLE)
         IndicatorRelease(g_obvHandles[i].handle);
   }
   ArrayResize(g_obvHandles, 0);
}

/// obtém valor do OBV
inline double GetOBV(const string symbol, ENUM_TIMEFRAMES tf, ENUM_APPLIED_VOLUME volType = VOLUME_REAL)
{
   int handle = GetOBVHandle(symbol, tf, volType);
   if (handle == INVALID_HANDLE)
      return 0.0;
   double buf[1];
   if (CopyBuffer(handle, 0, 0, 1, buf) != 1)
      return 0.0;
   return buf[0];
}

/// get RSI value for a given period
inline double GetRSI(const string symbol, ENUM_TIMEFRAMES tf, int period, int shift = 0)
{
   int handle = GetRSIHandle(symbol, tf, period);
   if (handle == INVALID_HANDLE)
      return 0.0;
   double buf[1];
   if (CopyBuffer(handle, 0, shift, 1, buf) != 1)
      return 0.0;
   return buf[0];
}

/// Obtém o valor atual do ATR
inline double GetATR(const string symbol, ENUM_TIMEFRAMES tf, int period, int shift = 0)
{
   int handle = GetATRHandle(symbol, tf, period);
   if (handle == INVALID_HANDLE)
      return 0.0;
   double buf[1];
   if (CopyBuffer(handle, 0, shift, 1, buf) != 1)
      return 0.0;
   return buf[0];
}

/// Obtém o valor atual de uma EMA
inline double GetEMA(const string symbol, ENUM_TIMEFRAMES tf, int period, int shift = 0)
{
   int handle = GetEMAHandle(symbol, tf, period);
   if (handle == INVALID_HANDLE)
      return 0.0;
   double buf[1];
   if (CopyBuffer(handle, 0, shift, 1, buf) != 1)
      return 0.0;
   return buf[0];
}

/// Obtém o valor atual de uma SMA
inline double GetSMA(const string symbol, ENUM_TIMEFRAMES tf, int period, int shift = 0)
{
   int handle = GetSMAHandle(symbol, tf, period);
   if (handle == INVALID_HANDLE)
      return 0.0;
   double buf[1];
   if (CopyBuffer(handle, 0, shift, 1, buf) != 1)
      return 0.0;
   return buf[0];
}


/// Calcula o VWAP simples do dia atual
inline double GetVWAP(const string symbol, ENUM_TIMEFRAMES tf)
{
   datetime dayStart = iTime(symbol, PERIOD_D1, 0);
   // check cached value
   for (int i = 0; i < ArraySize(g_vwapCache); i++)
   {
      if (g_vwapCache[i].symbol == symbol && g_vwapCache[i].tf == tf)
      {
         if (g_vwapCache[i].day == dayStart)
            return g_vwapCache[i].value;
         break; // found entry but outdated
      }
   }

   int start = iBarShift(symbol, tf, dayStart, true);
   if (start < 0)
      start = iBars(symbol, tf) - 1;
   double sumPV = 0.0, sumV = 0.0;
   for (int j = start; j >= 0; j--)
   {
      double typical = (iHigh(symbol, tf, j) + iLow(symbol, tf, j) + iClose(symbol, tf, j)) / 3.0;
      long vol_long = iVolume(symbol, tf, j);
      double vol = (double)vol_long; // explicit cast to avoid long->double warning
      sumPV += typical * vol;
      sumV += vol;
   }
   double vwap = (sumV == 0.0) ? iClose(symbol, tf, 0) : (sumPV / sumV);

   // store in cache (replace or append)
   bool stored = false;
   for (int k = 0; k < ArraySize(g_vwapCache); k++)
   {
      if (g_vwapCache[k].symbol == symbol && g_vwapCache[k].tf == tf)
      {
         g_vwapCache[k].day = dayStart;
         g_vwapCache[k].value = vwap;
         stored = true;
         break;
      }
   }
   if (!stored)
   {
      int idx = ArraySize(g_vwapCache);
      ArrayResize(g_vwapCache, idx + 1);
      g_vwapCache[idx].symbol = symbol;
      g_vwapCache[idx].tf = tf;
      g_vwapCache[idx].day = dayStart;
      g_vwapCache[idx].value = vwap;
   }
   return vwap;
}

/// Converte um timeframe para minutos
inline int TimeframeToMinutes(ENUM_TIMEFRAMES tf)
{
   switch (tf)
   {
   case PERIOD_M1:
      return 1;
   case PERIOD_M5:
      return 5;
   case PERIOD_M15:
      return 15;
   case PERIOD_M30:
      return 30;
   case PERIOD_H1:
      return 60;
   case PERIOD_H4:
      return 240;
   case PERIOD_D1:
      return 1440;
   default:
      return 0;
   }
}

/// Normaliza um preço de acordo com o tick do ativo
/// Normalize price according to the asset tick size
inline double NormalizePrice(const string symbol, double price)
{
   double tick = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   if (tick > 0.0)
   {
      // round to the nearest multiple of tick size
      price = MathRound(price / tick) * tick;
   }

   return (NormalizeDouble(price, digits));
}

/// Calcula o valor de um pip para um determinado ativo
inline double CalculatePipValue(const string symbol)
{
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   if (tickSize == 0.0)
      return (0.0);
  return (tickValue / tickSize);
}

/// Retorna o numero de casas decimais do volume para um simbolo
inline int GetVolumeDigits(string symbol)
{
   double step;
   if(!SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP, step))
   {
      Print("Erro ao obter SYMBOL_VOLUME_STEP para o símbolo: ", symbol);
      return 0;
   }

   for(int digits = 0; digits <= 8; digits++)
   {
      double multiplier = MathPow(10.0, digits);
      double adjusted   = step * multiplier;
      if(MathAbs(adjusted - MathRound(adjusted)) < 1e-8)
         return digits;
   }

   return 8;
}

/// Verifica se há nova barra em determinado timeframe
inline bool IsNewBar(const string symbol, ENUM_TIMEFRAMES tf, datetime &last)
{
   datetime current = iTime(symbol, tf, 0);
   if (current != last)
   {
      last = current;
      return true;
   }
   return false;
}

/// Verifica se o preço retorna à média entre as EMAs de 50 e 200
inline bool CheckMeanReversion50to200(const string symbol, ENUM_TIMEFRAMES tf)
{
   double ema50 = GetEMA(symbol, tf, 50);
   double ema200 = GetSMA(symbol, tf, 200);
   double price = iClose(symbol, tf, 0);
   double avg = (ema50 + ema200) / 2.0;
   return (MathAbs(price - avg) <= 3 * SymbolInfoDouble(symbol, SYMBOL_POINT));
}

/// Calcula níveis de Fibonacci entre swingHigh e swingLow
inline void GetFibLevels(double swingHigh, double swingLow, double &levels[])
{
   ArrayResize(levels, 9);
   if (swingHigh < swingLow)
   {
      double tmp = swingHigh;
      swingHigh = swingLow;
      swingLow = tmp;
   }
   double diff = swingHigh - swingLow;
   levels[0] = swingLow;                 // 0.0
   levels[1] = swingLow + diff * 0.236;  // 23.6%
   levels[2] = swingLow + diff * 0.382;  // 38.2%
   levels[3] = swingLow + diff * 0.5;    // 50%
   levels[4] = swingLow + diff * 0.618;  // 61.8%
   levels[5] = swingLow + diff * 0.786;  // 78.6%
   levels[6] = swingHigh;                // 100%
   levels[7] = swingHigh + diff * 0.272; // 127.2%
   levels[8] = swingHigh + diff * 0.618; // 161.8%
}

/// Avalia a qualidade do setup com base na relacao risco/retorno e volume
// avalia a qualidade do setup considerando RR e indicadores de volume
inline SETUP_QUALITY EvaluateQuality(const string symbol, ENUM_TIMEFRAMES tf, double rr, double vol_ratio)
{
   // referencia: Guia_Completo_de_Trading_Versao_Final.pdf linhas 2399-2406
   // minimo 1:2, ideal 1:3 com confirmacao de volume
   double volumeScore = vol_ratio;
   double mfi = GetMFI(symbol, tf, 14);
   if (mfi > 60.0 || mfi < 40.0)
      volumeScore += 0.5;
   double obv_now = GetOBV(symbol, tf, 0);
   double obv_prev = GetOBV(symbol, tf, 1);
   if (obv_now > obv_prev)
      volumeScore += 0.5;
   else if (obv_now < obv_prev)
      volumeScore -= 0.5;

   if (rr >= 3.0 && volumeScore >= 2.0)
      return SETUP_A_PLUS;
   if (rr >= 2.0 && volumeScore >= 1.0)
      return SETUP_A;
   if (rr >= 1.5 && volumeScore >= 0.5)
      return SETUP_B;
   return SETUP_C;
}

/// Suggested stop distance in points for common assets
/// Based on trading guide lines 4165-4376 describing typical
/// stop levels for WIN, WDO and Bitcoin futures
inline double GuideStopPoints(const string symbol)
{
   if (StringFind(symbol, "WDO") == 0)
      return 7.0; // Dollar futures typical stop 5-7 pts
   if (StringFind(symbol, "WIN") == 0)
      return 200.0; // Index futures around 150-200 pts
   if (StringFind(symbol, "BTC") == 0)
      return 1000.0; // Bitcoin futures around $800-1200
   return 10.0;      // default for other instruments
}

/// Check RSI momentum alignment according to trading guide lines 5467
inline bool CheckRSIMomentum(const string symbol, ENUM_TIMEFRAMES tf, SIGNAL_DIRECTION dir)
{
   double rsi = GetRSI(symbol, tf, 14);
   if (dir == SIGNAL_BUY)
      return (rsi > 50.0 && rsi < 70.0);
   if (dir == SIGNAL_SELL)
      return (rsi < 50.0 && rsi > 30.0);
   return true;
}

/// Calculate Pearson correlation of closing prices for two symbols
/// using the last 'bars' completed bars on the given timeframe
inline double GetCorrelation(const string sym1, const string sym2,
                             ENUM_TIMEFRAMES tf, int bars)
{
   double a1[], a2[];
   if (CopyClose(sym1, tf, 1, bars, a1) != bars)
      return 0.0;
   if (CopyClose(sym2, tf, 1, bars, a2) != bars)
      return 0.0;
   double mean1 = 0.0, mean2 = 0.0;
   for (int i = 0; i < bars; i++)
   {
      mean1 += a1[i];
      mean2 += a2[i];
   }
   mean1 /= bars;
   mean2 /= bars;
   double cov = 0.0, var1 = 0.0, var2 = 0.0;
   for (int i = 0; i < bars; i++)
   {
      double d1 = a1[i] - mean1;
      double d2 = a2[i] - mean2;
      cov += d1 * d2;
      var1 += d1 * d1;
      var2 += d2 * d2;
   }
   if (var1 == 0.0 || var2 == 0.0)
      return 0.0;
   return cov / MathSqrt(var1 * var2);
}

/// Confirm WIN/WDO trades only when correlation remains negative
/// and the two markets diverge as expected (PDF lines 2854-2925)
inline bool CheckDollarIndexCorrelation(const string tradeSymbol,
                                        const string dollarSym,
                                        const string indexSym,
                                        SIGNAL_DIRECTION dir,
                                        ENUM_TIMEFRAMES tf)
{
   double corr = GetCorrelation(dollarSym, indexSym, tf, 20);
   double wdoChange = iClose(dollarSym, tf, 1) - iClose(dollarSym, tf, 2);
   double winChange = iClose(indexSym, tf, 1) - iClose(indexSym, tf, 2);

   if (StringFind(tradeSymbol, "WIN") == 0)
   {
      if (dir == SIGNAL_BUY)
         return (corr < -0.2 && wdoChange < 0.0);
      if (dir == SIGNAL_SELL)
         return (corr < -0.2 && wdoChange > 0.0);
   }
   if (StringFind(tradeSymbol, "WDO") == 0)
   {
      if (dir == SIGNAL_BUY)
         return (corr < -0.2 && winChange < 0.0);
      if (dir == SIGNAL_SELL)
         return (corr < -0.2 && winChange > 0.0);
   }
   return true;
}

/// Helper to locate WIN/WDO in the asset list and validate the correlation
/// filter for the given trade symbol (review comment)
inline bool ValidateDollarIndexCorrelation(const string tradeSymbol,
                                           SIGNAL_DIRECTION dir,
                                           const AssetConfig &assets[], int count,
                                           ENUM_TIMEFRAMES tf)
{
   string wdo = "", win = "";
   for (int i = 0; i < count; i++)
   {
      if (StringFind(assets[i].symbol, "WDO") == 0)
         wdo = assets[i].symbol;
      if (StringFind(assets[i].symbol, "WIN") == 0)
         win = assets[i].symbol;
   }
   if ((tradeSymbol == wdo || tradeSymbol == win))
      return CheckDollarIndexCorrelation(tradeSymbol, wdo, win, dir, tf);
   return true;
}

inline ENUM_TIMEFRAMES TfFromString(string txt, ENUM_TIMEFRAMES mainTf)
{
   StringToUpper(txt); // modifies txt in place
   if (txt == "MAIN")
      return mainTf;
   if (txt == "M1")
      return PERIOD_M1;
   if (txt == "M5")
      return PERIOD_M5;
   if (txt == "M15")
      return PERIOD_M15;
   if (txt == "M30")
      return PERIOD_M30;
   if (txt == "H1")
      return PERIOD_H1;
   if (txt == "H4")
      return PERIOD_H4;
   if (txt == "D1")
      return PERIOD_D1;
   return mainTf; // default fallback
}

/// Load asset parameters from a CSV file to simplify adjustments
inline bool LoadAssetCsv(const string path, ENUM_TIMEFRAMES mainTf, AssetConfig &dest[])
{
   int handle = FileOpen(path, FILE_READ | FILE_CSV);
   if (handle == INVALID_HANDLE)
      return false;

   ArrayResize(dest, 0);
   bool first = true;
   while (!FileIsEnding(handle))
   {
      string symbol = FileReadString(handle);
      if (symbol == "" && FileIsEnding(handle))
         break;

      string upperSymbol = symbol;
      StringToUpper(upperSymbol);
      if (first && upperSymbol == "SYMBOL")

      {
         // discard header line
         for (int i = 0; i < 13; i++)
            FileReadString(handle);
         first = false;
         continue;
      }

      string enabledStr = FileReadString(handle);
      double minLot = FileReadNumber(handle);
      double maxLot = FileReadNumber(handle);
      double lotStep = FileReadNumber(handle);
      double rangeThr = FileReadNumber(handle);
      double minStop = FileReadNumber(handle);
      double riskPct = FileReadNumber(handle);
      string ctxTfStr = FileReadString(handle);
      string atrTfStr = FileReadString(handle);
      int atrPeriod = (int)FileReadNumber(handle);
      int srLookback = (int)FileReadNumber(handle);
      double trailStart = FileReadNumber(handle);
      double trailDist  = FileReadNumber(handle);

      AssetConfig cfg;
      cfg.symbol = symbol;
      string upper = enabledStr;
      StringToUpper(upper);
      cfg.enabled = (upper == "TRUE" || StringToInteger(enabledStr) > 0);
      cfg.minLot = minLot;
      cfg.maxLot = maxLot;
      cfg.lotStep = lotStep;
      cfg.tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      cfg.digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      cfg.rangeThreshold = rangeThr;
      cfg.lastBar = 0;
      cfg.minStop = minStop;
      cfg.riskPercent = riskPct;
      cfg.trailStart  = trailStart;
      cfg.trailDist   = trailDist;
      cfg.ctxTf = TfFromString(ctxTfStr, mainTf);
      cfg.atrTf = TfFromString(atrTfStr, mainTf);
      cfg.atrPeriod = atrPeriod;
      cfg.srLookback = srLookback;
      cfg.prevHigh = 0.0;
      cfg.prevLow = 0.0;
      cfg.dailyBias = BIAS_NEUTRAL;

      int idx = ArraySize(dest);
      ArrayResize(dest, idx + 1);
      dest[idx] = cfg;
      first = false;
   }
   FileClose(handle);
   return (ArraySize(dest) > 0);
}

// OBV AS FILTER - TREND //
/// Calcula a média móvel simples do OBV
inline double GetOBVSMA(const string symbol, ENUM_TIMEFRAMES tf, int period, int shift = 0)
{
   double obvValues[];
   ArraySetAsSeries(obvValues, true);
   
   // Coleta valores do OBV para o período especificado
   if (ArrayResize(obvValues, period + shift) == -1)
      return 0.0;
   
   int obvHandle = GetOBVHandle(symbol, tf, VOLUME_REAL);
   if (obvHandle == INVALID_HANDLE)
      return 0.0;
   
   if (CopyBuffer(obvHandle, 0, shift, period, obvValues) != period)
      return 0.0;
   
   // Calcula a média
   double sum = 0.0;
   for (int i = 0; i < period; i++)
   {
      sum += obvValues[i];
   }
   
   return sum / period;
}

/// Verifica confirmação de tendência pelo OBV
inline bool CheckOBVTrendConfirmation(const string symbol, ENUM_TIMEFRAMES tf, bool isUpTrend)
{
   double obv_current = GetOBV(symbol, tf, VOLUME_REAL);
   
   // Obter valor anterior do OBV usando shift
   int obvHandle = GetOBVHandle(symbol, tf, VOLUME_REAL);
   if (obvHandle == INVALID_HANDLE)
      return false;
   
   double obvPrev[1];
   if (CopyBuffer(obvHandle, 0, 1, 1, obvPrev) != 1)
      return false;
   
   double obv_sma = GetOBVSMA(symbol, tf, 14);
   
   if (isUpTrend)
   {
      // Para tendência de alta: OBV deve estar subindo OU acima da média
      return (obv_current > obvPrev[0]) || (obv_current > obv_sma);
   }
   else
   {
      // Para tendência de baixa: OBV deve estar caindo OU abaixo da média
      return (obv_current < obvPrev[0]) || (obv_current < obv_sma);
   }
}

/// Calcula o slope (inclinação) da EMA entre o valor atual e N barras atrás
inline double GetEMASlope(const string symbol, ENUM_TIMEFRAMES tf, int period, int barsBack)
{
   if (barsBack <= 0)
      return 0.0;
   double now  = GetEMA(symbol, tf, period, 0);
   double past = GetEMA(symbol, tf, period, barsBack);
   return (now - past) / barsBack;
}

/// Threshold adaptativo baseado no ATR para avaliação do slope para verificação de tendencia
// Retorna um threshold adaptativo para slope baseado em volatilidade e mínimo estatístico
inline double AdaptiveSlopeThreshold(const string symbol, ENUM_TIMEFRAMES tf, int barsBack)
{
   // Obter o ATR de 14 períodos
   double atr = GetATR(symbol, tf, 14);
   if (atr <= 0.0)
      return 34.0; // fallback padrão

   // Garantir precisão dos pontos
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if (point <= 0.0)
      point = 1.0;

   // Base mínima confiável identificada pela estatística do WIN M3
   const double baseThr = 34.0;

   // ATR médio estimado para o timeframe (ajuste conforme necessidade real)
   const double atrMedio = 400.0;

   // Ajuste adaptativo proporcional à volatilidade atual
   double fator = atr / atrMedio;

   // Valor final ajustado, nunca inferior a 34
   return baseThr * MathMax(fator, 1.0);
}

/// Busca suporte significativo examinando os pivôs mais recentes
/// Referência: guia_completo_trading_v5.md linhas 410-415 destacam
/// a importância psicológica dos extremos de range.
inline double GetSupportLevel(const string symbol, ENUM_TIMEFRAMES tf, int lookback)
{
   if (lookback < 5)
      lookback = 5;
   int bars = iBars(symbol, tf);
   int limit = MathMin(lookback, bars - 1);
   double best = 0.0;
   bool found = false;
   for (int i = limit; i >= 2; i--)
   {
      double prev = iLow(symbol, tf, i + 1);
      double curr = iLow(symbol, tf, i);
      double next = iLow(symbol, tf, i - 1);
      if (curr <= prev && curr <= next)
      {
         if (!found || curr < best)
         {
            best = curr;
            found = true;
         }
      }
   }
   if (found)
      return best;
   int idx = iLowest(symbol, tf, MODE_LOW, limit, 1);
   return (idx >= 0) ? iLow(symbol, tf, idx) : 0.0;
}

/// Busca resistência significativa examinando os pivôs recentes
/// Conforme descrito no guia, traders observam os extremos anteriores
/// como zonas prováveis de reação de preço
inline double GetResistanceLevel(const string symbol, ENUM_TIMEFRAMES tf, int lookback)
{
   if (lookback < 5)
      lookback = 5;
   int bars = iBars(symbol, tf);
   int limit = MathMin(lookback, bars - 1);
   double best = 0.0;
   bool found = false;
   for (int i = limit; i >= 2; i--)
   {
      double prev = iHigh(symbol, tf, i + 1);
      double curr = iHigh(symbol, tf, i);
      double next = iHigh(symbol, tf, i - 1);
      if (curr >= prev && curr >= next)
      {
         if (!found || curr > best)
         {
            best = curr;
            found = true;
         }
      }
   }
   if (found)
      return best;
   int idx = iHighest(symbol, tf, MODE_HIGH, limit, 1);
   return (idx >= 0) ? iHigh(symbol, tf, idx) : 0.0;
}

//+------------------------------------------------------------------+
//| Verifica se o preço caminha pelas bandas de Bollinger           |
//| Retorna true se o fechamento atual confirma a tendência ativa   |
//+------------------------------------------------------------------+
bool BollingerTrendConfirm(const string symbol, ENUM_TIMEFRAMES tf, bool isUpTrend)
{
   int period = 20;
   double deviation = 2.0;
   int handle = iBands(symbol, tf, period, 0, deviation, PRICE_CLOSE);
   if (handle == INVALID_HANDLE)
      return false;

   double upper[], middle[], lower[];
   if (CopyBuffer(handle, 0, 0, 1, upper) <= 0 ||
       CopyBuffer(handle, 1, 0, 1, middle) <= 0 ||
       CopyBuffer(handle, 2, 0, 1, lower) <= 0)
      return false;

   double close = iClose(symbol, tf, 0);
   double range = upper[0] - lower[0];

   if (isUpTrend)
      return (close > middle[0] && (upper[0] - close) <= range * 0.2);
   else
      return (close < middle[0] && (close - lower[0]) <= range * 0.2);
}

/// Draw or update support and resistance horizontal lines
inline void DrawSupportResistanceLines(const string symbol, ENUM_TIMEFRAMES tf, 
                                       double supportLevel, double resistanceLevel, string codename)
{
   string supportName = codename + "SR_Support_" + symbol + "_" + EnumToString(tf);
   string resistanceName = codename + "SR_Resistance_" + symbol + "_" + EnumToString(tf);
   
   // Support line
   if (ObjectFind(0, supportName) < 0)
   {
      ObjectCreate(0, supportName, OBJ_HLINE, 0, 0, supportLevel);
      ObjectSetInteger(0, supportName, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(0, supportName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, supportName, OBJPROP_WIDTH, 2);
      ObjectSetString(0, supportName, OBJPROP_TEXT, "Support: " + DoubleToString(supportLevel, _Digits));
   }
   else
   {
      ObjectSetDouble(0, supportName, OBJPROP_PRICE, supportLevel);
      ObjectSetString(0, supportName, OBJPROP_TEXT, "Support: " + DoubleToString(supportLevel, _Digits));
   }
   
   // Resistance line
   if (ObjectFind(0, resistanceName) < 0)
   {
      ObjectCreate(0, resistanceName, OBJ_HLINE, 0, 0, resistanceLevel);
      ObjectSetInteger(0, resistanceName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, resistanceName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, resistanceName, OBJPROP_WIDTH, 2);
      ObjectSetString(0, resistanceName, OBJPROP_TEXT, "Resistance: " + DoubleToString(resistanceLevel, _Digits));
   }
   else
   {
      ObjectSetDouble(0, resistanceName, OBJPROP_PRICE, resistanceLevel);
      ObjectSetString(0, resistanceName, OBJPROP_TEXT, "Resistance: " + DoubleToString(resistanceLevel, _Digits));
   }
   
   ChartRedraw(0);
}
#endif // INTEGRATEDPA_UTILS_MQH

