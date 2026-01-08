//+------------------------------------------------------------------+
//| TimeUtils.mqh                                                    |
//| Time and bar utilities - VPS-safe                                |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Check if new bar                                                 |
//+------------------------------------------------------------------+
bool IsNewBar(ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   
   static datetime lastBarTime = 0;
   static string lastSymbol = "";
   static ENUM_TIMEFRAMES lastTimeframe = PERIOD_CURRENT;
   
   // Reset if symbol or timeframe changed
   if(symbol != lastSymbol || timeframe != lastTimeframe)
   {
      lastBarTime = 0;
      lastSymbol = symbol;
      lastTimeframe = timeframe;
   }
   
   datetime currentBarTime = iTime(symbol, timeframe, 0);
   
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Get bar time                                                      |
//+------------------------------------------------------------------+
datetime GetBarTime(int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   return iTime(symbol, timeframe, shift);
}

//+------------------------------------------------------------------+
//| Check if market is open (basic check)                            |
//+------------------------------------------------------------------+
bool IsMarketOpen(string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   
   // Basic check - can be enhanced with session times
   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   
   // Simple check: exclude weekends (Saturday = 6, Sunday = 0)
   if(dt.day_of_week == 0 || dt.day_of_week == 6)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Get time string for logging                                       |
//+------------------------------------------------------------------+
string GetTimeString(datetime time = 0)
{
   if(time == 0) time = TimeCurrent();
   return TimeToString(time, TIME_DATE|TIME_MINUTES);
}

//+------------------------------------------------------------------+
//| Check if it's a new trading day                                  |
//+------------------------------------------------------------------+
bool IsNewTradingDay()
{
   static datetime lastDay = 0;
   datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   
   if(today != lastDay)
   {
      lastDay = today;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
