//+------------------------------------------------------------------+
//| IndicatorHelper.mqh                                              |
//| Indicator utilities for ForexTradeAssistant EA                  |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Indicator Helper class                                          |
//+------------------------------------------------------------------+
class CIndicatorHelper
{
private:
   int m_handleMA;
   int m_handleRSI;
   int m_handleMACD;
   // Add more indicator handles as needed

public:
   CIndicatorHelper() : m_handleMA(INVALID_HANDLE), m_handleRSI(INVALID_HANDLE), m_handleMACD(INVALID_HANDLE) {}
   
   ~CIndicatorHelper()
   {
      if(m_handleMA != INVALID_HANDLE) IndicatorRelease(m_handleMA);
      if(m_handleRSI != INVALID_HANDLE) IndicatorRelease(m_handleRSI);
      if(m_handleMACD != INVALID_HANDLE) IndicatorRelease(m_handleMACD);
   }
   
   //+------------------------------------------------------------------+
   //| Initialize Moving Average                                      |
   //+------------------------------------------------------------------+
   bool InitMA(ENUM_TIMEFRAMES timeframe, int period, ENUM_MA_METHOD ma_method, int applied_price)
   {
      m_handleMA = iMA(_Symbol, timeframe, period, 0, ma_method, applied_price);
      return (m_handleMA != INVALID_HANDLE);
   }
   
   //+------------------------------------------------------------------+
   //| Get MA value                                                   |
   //+------------------------------------------------------------------+
   double GetMA(int shift = 0)
   {
      if(m_handleMA == INVALID_HANDLE) return 0;
      
      double buffer[];
      ArraySetAsSeries(buffer, true);
      
      if(CopyBuffer(m_handleMA, 0, shift, 1, buffer) <= 0)
         return 0;
      
      return buffer[0];
   }
   
   //+------------------------------------------------------------------+
   //| Initialize RSI                                                 |
   //+------------------------------------------------------------------+
   bool InitRSI(ENUM_TIMEFRAMES timeframe, int period, int applied_price)
   {
      m_handleRSI = iRSI(_Symbol, timeframe, period, applied_price);
      return (m_handleRSI != INVALID_HANDLE);
   }
   
   //+------------------------------------------------------------------+
   //| Get RSI value                                                  |
   //+------------------------------------------------------------------+
   double GetRSI(int shift = 0)
   {
      if(m_handleRSI == INVALID_HANDLE) return 50;
      
      double buffer[];
      ArraySetAsSeries(buffer, true);
      
      if(CopyBuffer(m_handleRSI, 0, shift, 1, buffer) <= 0)
         return 50;
      
      return buffer[0];
   }
   
   //+------------------------------------------------------------------+
   //| Initialize MACD                                                |
   //+------------------------------------------------------------------+
   bool InitMACD(ENUM_TIMEFRAMES timeframe, int fast_ema, int slow_ema, int signal_sma, int applied_price)
   {
      m_handleMACD = iMACD(_Symbol, timeframe, fast_ema, slow_ema, signal_sma, applied_price);
      return (m_handleMACD != INVALID_HANDLE);
   }
   
   //+------------------------------------------------------------------+
   //| Get MACD main line                                             |
   //+------------------------------------------------------------------+
   double GetMACDMain(int shift = 0)
   {
      if(m_handleMACD == INVALID_HANDLE) return 0;
      
      double buffer[];
      ArraySetAsSeries(buffer, true);
      
      if(CopyBuffer(m_handleMACD, 0, shift, 1, buffer) <= 0)
         return 0;
      
      return buffer[0];
   }
   
   //+------------------------------------------------------------------+
   //| Get MACD signal line                                           |
   //+------------------------------------------------------------------+
   double GetMACDSignal(int shift = 0)
   {
      if(m_handleMACD == INVALID_HANDLE) return 0;
      
      double buffer[];
      ArraySetAsSeries(buffer, true);
      
      if(CopyBuffer(m_handleMACD, 1, shift, 1, buffer) <= 0)
         return 0;
      
      return buffer[0];
   }
};

//+------------------------------------------------------------------+