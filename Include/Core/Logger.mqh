//+------------------------------------------------------------------+
//| Logger.mqh                                                       |
//| Logging utilities - VPS-safe                                     |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Log levels                                                       |
//+------------------------------------------------------------------+
enum ENUM_LOG_LEVEL
{
   LOG_LEVEL_DEBUG = 0,
   LOG_LEVEL_INFO  = 1,
   LOG_LEVEL_WARN  = 2,
   LOG_LEVEL_ERROR = 3
};

//+------------------------------------------------------------------+
//| Logger class                                                     |
//+------------------------------------------------------------------+
class CLogger
{
private:
   ENUM_LOG_LEVEL m_logLevel;
   string         m_prefix;

public:
   CLogger(string prefix = "EA") : m_prefix(prefix), m_logLevel(LOG_LEVEL_INFO) {}
   
   void SetLogLevel(ENUM_LOG_LEVEL level) { m_logLevel = level; }
   
   void Debug(string message) 
   { 
      if(m_logLevel <= LOG_LEVEL_DEBUG) 
         Print("[DEBUG] ", m_prefix, ": ", message); 
   }
   
   void Info(string message) 
   { 
      if(m_logLevel <= LOG_LEVEL_INFO) 
         Print("[INFO] ", m_prefix, ": ", message); 
   }
   
   void Warn(string message) 
   { 
      if(m_logLevel <= LOG_LEVEL_WARN) 
         Print("[WARN] ", m_prefix, ": ", message); 
   }
   
   void Error(string message) 
   { 
      if(m_logLevel <= LOG_LEVEL_ERROR) 
         Print("[ERROR] ", m_prefix, ": ", message); 
   }
};

//+------------------------------------------------------------------+
