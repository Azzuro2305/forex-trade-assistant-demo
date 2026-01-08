//+------------------------------------------------------------------+
//| HistoryParser.mqh                                                |
//| Trade history parser - LOCAL ONLY                               |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Core/Logger.mqh"

//+------------------------------------------------------------------+
//| History Parser class (Local Only - for review/analysis)         |
//+------------------------------------------------------------------+
// Note: This is for local review only, not used on VPS

class CHistoryParser
{
private:
   int      m_magicNumber;
   CLogger* m_logger;
   
public:
   CHistoryParser(int magic, CLogger* logger)
      : m_magicNumber(magic), m_logger(logger)
   {
   }
   
   //+------------------------------------------------------------------+
   //| Parse trade history                                             |
   //+------------------------------------------------------------------+
   int ParseHistory(datetime fromDate, datetime toDate)
   {
      int dealCount = 0;
      
      if(!HistorySelect(fromDate, toDate))
      {
         if(m_logger != NULL)
            m_logger.Error("Failed to select history");
         return 0;
      }
      
      int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket > 0)
         {
            if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == m_magicNumber)
            {
               dealCount++;
            }
         }
      }
      
      if(m_logger != NULL)
         m_logger.Info("Parsed " + IntegerToString(dealCount) + " deals from history");
      
      return dealCount;
   }
};

//+------------------------------------------------------------------+
