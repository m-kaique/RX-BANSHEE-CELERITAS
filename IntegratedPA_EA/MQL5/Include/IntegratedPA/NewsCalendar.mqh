#ifndef INTEGRATEDPA_NEWSCALENDAR_MQH
#define INTEGRATEDPA_NEWSCALENDAR_MQH

#include "Defs.mqh"              // includes SessionRange definition
#include "Calendar/Calendar.mqh" // base calendar utilities

/// g_news is declared in the EA to share news blackout windows
extern SessionRange g_news[];

/// Simple wrapper around the complex CALENDAR class provided in
/// Calendar.mqh. It loads economic events for the configured currencies
/// and exposes helper functions for the EA.
class NewsCalendar
{
private:
   CALENDAR m_cal;            ///< internal calendar storage
   string   m_currencies;     ///< comma separated list of currencies to query
   string   m_symbols[];      ///< active trading symbols used for filtering

public:
   NewsCalendar():m_currencies(""){}

   /// Define which currencies should be requested from the MetaTrader calendar
   void SetCurrencies(const string currencies)
   {
      m_currencies = currencies;
   }

   /// Store active symbols so events can be filtered by relevance
   void SetActiveSymbols(string &symbols[])
   {
      ArrayCopy(m_symbols, symbols);
   }

   /// Remove all previously loaded events and clear the global news ranges
   void Clear()
   {
      m_cal = CALENDAR();
      ArrayResize(g_news, 0);
   }

   /// Load events in the given time range and populate g_news
   void LoadRange(datetime from, datetime to)
   {
      ArrayResize(g_news, 0);
      // use configured currencies, falling back to currencies from symbols
      string curr[];
      int cnt = StringSplit(m_currencies, ',', curr);
      if(cnt==0)
      {
         for(int i=0;i<ArraySize(m_symbols);i++)
         {
            string c1=SymbolInfoString(m_symbols[i],SYMBOL_CURRENCY_BASE);
            string c2=SymbolInfoString(m_symbols[i],SYMBOL_CURRENCY_PROFIT);
            if(c1!="") {ArrayResize(curr,ArraySize(curr)+1); curr[ArraySize(curr)-1]=c1;}
            if(c2!="" && c2!=c1){ArrayResize(curr,ArraySize(curr)+1); curr[ArraySize(curr)-1]=c2;}
         }
      }

      // reset internal calendar list
      m_cal = CALENDAR();
      // load all events for the currencies into the internal calendar
      m_cal.Set(curr, CALENDAR_IMPORTANCE_MODERATE, from, to);

      EVENT ev[];
      m_cal.GetEvents(ev);

      int idx=0;
      for(int i=0;i<ArraySize(ev);i++)
      {
         bool isRelevant=false;
         // STRING4 to string conversion using operator[]
         string evCurr = ev[i].Currency[];
         for(int j=0;j<ArraySize(m_symbols);j++)
         {
            // check if the event currency appears inside the trading symbol
            if(StringFind(m_symbols[j],evCurr)!=-1)
            {
               isRelevant=true;
               break;
            }
         }
         if(!isRelevant)
            continue;

         MqlDateTime tm; TimeToStruct(ev[i].time,tm);
         int start=tm.hour*60+tm.min;
         ArrayResize(g_news,idx+1);
         g_news[idx].start=start-5; // 5 min before
         if(g_news[idx].start<0) g_news[idx].start=0;
         g_news[idx].end = start+30; // block 30 min window
         idx++;
      }
   }

   /// Convenience method for loading only today's events
   void LoadToday()
   {
      MqlDateTime tm; TimeToStruct(TimeCurrent(),tm); tm.hour=0; tm.min=0; tm.sec=0;
      datetime from=StructToTime(tm);
      LoadRange(from,from+24*60*60);
   }

   /// Returns true when current time is within any loaded news window
   bool IsNewsNow()
   {
      MqlDateTime tm; TimeToStruct(TimeCurrent(),tm);
      int cur=tm.hour*60+tm.min;
      for(int i=0;i<ArraySize(g_news);i++)
         if(cur>=g_news[i].start && cur<=g_news[i].end)
            return true;
      return false;
   }

   /// Print events containing USD just for debugging
   void PrintUSDNewsToday()
   {
      EVENT ev[];
      m_cal.GetEvents(ev);
      for(int i=0;i<ArraySize(ev);i++)
      {
           // Print only events where currency contains USD
           if(StringFind(ev[i].Currency[],"USD")!=-1)
              Print(TimeToString(ev[i].time)," ",ev[i].Currency[]);
      }
   }
};

#endif // INTEGRATEDPA_NEWSCALENDAR_MQH
