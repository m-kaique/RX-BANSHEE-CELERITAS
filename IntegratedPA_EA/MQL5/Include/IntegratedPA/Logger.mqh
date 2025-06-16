#ifndef INTEGRATEDPA_LOGGER_MQH
#define INTEGRATEDPA_LOGGER_MQH
#include "Defs.mqh"

//+------------------------------------------------------------------+
//| Níveis de log                                                    |
//+------------------------------------------------------------------+
enum LOG_LEVEL
{
   LOG_INFO=0,
   LOG_WARNING,
   LOG_ERROR,
   LOG_DEBUG
};

//+------------------------------------------------------------------+
//| Classe de registro                                               |
//+------------------------------------------------------------------+
class Logger
{
private:
   string  m_prefix;     // prefix for log files
   string  m_file;       // text log file
   string  m_csv;        // csv log file
   int     m_handle;     // handle for text log
   int     m_csv_handle; // handle for csv log

public:
   Logger(const string prefix)
   {
      m_prefix=prefix;
      string exePath=MQLInfoString(MQL_PROGRAM_PATH);
      string folder=exePath;
      for(int i=StringLen(folder)-1;i>=0;i--)
      {
         ushort c=StringGetCharacter(folder,i);
         if(c=='\\' || c=='/')
         {
            folder=StringSubstr(folder,0,i+1);
            break;
         }
      }
      m_file=folder+prefix+".log";
      m_csv =folder+prefix+"_log.csv";
      m_handle=FileOpen(m_file,FILE_WRITE|FILE_TXT);
      m_csv_handle=FileOpen(m_csv,FILE_READ|FILE_WRITE|FILE_CSV);
      if(m_csv_handle!=INVALID_HANDLE)
      {
         FileSeek(m_csv_handle,0,SEEK_END);
         if(FileSize(m_csv_handle)==0)
            FileWrite(m_csv_handle,"timestamp","level","message");
      }
   }

   ~Logger()
   {
      if(m_handle!=INVALID_HANDLE)
         FileClose(m_handle);
      if(m_csv_handle!=INVALID_HANDLE)
         FileClose(m_csv_handle);
   }

   void Log(LOG_LEVEL level,const string text)
   {
      string lvl;
      switch(level)
      {
         case LOG_INFO:    lvl="INFO";    break;
         case LOG_WARNING: lvl="WARNING"; break;
         case LOG_ERROR:   lvl="ERROR";   break;
         case LOG_DEBUG:   lvl="DEBUG";   break;
         default:          lvl="LOG";     break;
      }
      string msg=TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS)+" "+lvl+" : "+text;
      Print(m_prefix+": "+msg);
      if(m_handle!=INVALID_HANDLE)
         FileWrite(m_handle,msg);
      if(m_csv_handle!=INVALID_HANDLE)
         FileWrite(m_csv_handle,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),lvl,text);
   }

   void LogSignal(const string symbol,const Signal &sig)
   {
      string dir=(sig.direction==SIGNAL_BUY?"BUY":"SELL");
      string txt=StringFormat("Signal %s %s entry=%.2f stop=%.2f target=%.2f",symbol,dir,sig.entry,sig.stop,sig.target);
      Log(LOG_INFO,txt);
   }

   void LogTrade(const string action,const OrderRequest &req,bool success)
   {
      string txt=StringFormat("%s %s %.2f @ %.2f %s",action,req.symbol,req.volume,req.price,(success?"OK":"FAIL"));
      Log(success?LOG_INFO:LOG_ERROR,txt);
   }

   void ExportToCSV()
   {
      // csv is updated on every log; nothing additional required
   }
};

#endif // INTEGRATEDPA_LOGGER_MQH
