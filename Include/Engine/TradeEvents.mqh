//+------------------------------------------------------------------+
//| TradeEvents.mqh                                                  |
//| Trade event handler - VPS-SAFE ONLY                             |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Core/Logger.mqh"

//+------------------------------------------------------------------+
//| Trade Events Handler class                                      |
//+------------------------------------------------------------------+
class CTradeEvents
{
private:
   int      m_magicNumber;
   CLogger* m_logger;
   
public:
   CTradeEvents(int magic, CLogger* logger)
      : m_magicNumber(magic), m_logger(logger)
   {
   }
   
   //+------------------------------------------------------------------+
   //| Handle trade transaction event                                 |
   //+------------------------------------------------------------------+
   void OnTradeTransaction(const MqlTradeTransaction& trans,
                          const MqlTradeRequest& request,
                          const MqlTradeResult& result)
   {
      // Check magic number based on transaction type
      bool isOurTransaction = false;
      
      // First, check request.magic (most reliable for new transactions)
      if(request.magic == m_magicNumber)
      {
         isOurTransaction = true;
      }
      else if(trans.deal > 0)
      {
         // For deal transactions, check deal magic number
         if(HistoryDealSelect(trans.deal))
         {
            long dealMagic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
            if(dealMagic == m_magicNumber)
               isOurTransaction = true;
         }
      }
      else if(trans.order > 0)
      {
         // For order transactions, try to get from history first
         if(HistoryOrderSelect(trans.order))
         {
            long orderMagic = HistoryOrderGetInteger(trans.order, ORDER_MAGIC);
            if(orderMagic == m_magicNumber)
               isOurTransaction = true;
         }
         else
         {
            // If not in history, check active orders by iterating
            for(int i = 0; i < OrdersTotal(); i++)
            {
               ulong ticket = OrderGetTicket(i);
               if(ticket == trans.order)
               {
                  long orderMagic = OrderGetInteger(ORDER_MAGIC);
                  if(orderMagic == m_magicNumber)
                     isOurTransaction = true;
                  break;
               }
            }
         }
      }
      else if(trans.position > 0)
      {
         // For position transactions, check position magic number
         if(PositionSelectByTicket(trans.position))
         {
            long posMagic = PositionGetInteger(POSITION_MAGIC);
            if(posMagic == m_magicNumber)
               isOurTransaction = true;
         }
      }
      
      // Only process transactions for our magic number
      if(!isOurTransaction)
         return;
      
      // Log different transaction types
      switch(trans.type)
      {
         case TRADE_TRANSACTION_DEAL_ADD:
            if(m_logger != NULL)
            {
               string dealType = "";
               if(trans.deal_type == DEAL_TYPE_BUY)
                  dealType = "BUY";
               else if(trans.deal_type == DEAL_TYPE_SELL)
                  dealType = "SELL";
               else if(trans.deal_type == DEAL_TYPE_BALANCE)
                  dealType = "BALANCE";
               else if(trans.deal_type == DEAL_TYPE_COMMISSION)
                  dealType = "COMMISSION";
               else if(trans.deal_type == DEAL_TYPE_COMMISSION_DAILY)
                  dealType = "COMMISSION_DAILY";
               else if(trans.deal_type == DEAL_TYPE_COMMISSION_MONTHLY)
                  dealType = "COMMISSION_MONTHLY";
               else if(trans.deal_type == DEAL_TYPE_COMMISSION_AGENT_DAILY)
                  dealType = "COMMISSION_AGENT_DAILY";
               else if(trans.deal_type == DEAL_TYPE_COMMISSION_AGENT_MONTHLY)
                  dealType = "COMMISSION_AGENT_MONTHLY";
               else if(trans.deal_type == DEAL_TYPE_INTEREST)
                  dealType = "INTEREST";
               else if(trans.deal_type == DEAL_TYPE_BUY_CANCELED)
                  dealType = "BUY_CANCELED";
               else if(trans.deal_type == DEAL_TYPE_SELL_CANCELED)
                  dealType = "SELL_CANCELED";
               else if(trans.deal_type == DEAL_DIVIDEND)
                  dealType = "DIVIDEND";
               else if(trans.deal_type == DEAL_DIVIDEND_FRANKED)
                  dealType = "DIVIDEND_FRANKED";
               else if(trans.deal_type == DEAL_TAX)
                  dealType = "TAX";
               
               m_logger.Info("Deal added: " + dealType + " | Ticket: " + IntegerToString(trans.deal) + 
                            " | Volume: " + DoubleToString(trans.volume, 2) + 
                            " | Price: " + DoubleToString(trans.price, 5));
            }
            break;
            
         case TRADE_TRANSACTION_POSITION:
            if(m_logger != NULL)
            {
               m_logger.Info("Position updated: Ticket " + IntegerToString(trans.position) + 
                            " | Volume: " + DoubleToString(trans.volume, 2));
            }
            break;
            
         case TRADE_TRANSACTION_ORDER_ADD:
            if(m_logger != NULL)
            {
               m_logger.Info("Order added: Ticket " + IntegerToString(trans.order) + 
                            " | Type: " + EnumToString((ENUM_ORDER_TYPE)trans.order_type));
            }
            break;
            
         case TRADE_TRANSACTION_ORDER_UPDATE:
            if(m_logger != NULL)
            {
               m_logger.Debug("Order updated: Ticket " + IntegerToString(trans.order));
            }
            break;
            
         case TRADE_TRANSACTION_ORDER_DELETE:
            if(m_logger != NULL)
            {
               m_logger.Info("Order deleted: Ticket " + IntegerToString(trans.order));
            }
            break;
            
         case TRADE_TRANSACTION_HISTORY_ADD:
            if(m_logger != NULL)
            {
               m_logger.Debug("History added: Deal " + IntegerToString(trans.deal));
            }
            break;
            
         case TRADE_TRANSACTION_HISTORY_UPDATE:
            if(m_logger != NULL)
            {
               m_logger.Debug("History updated: Deal " + IntegerToString(trans.deal));
            }
            break;
            
         case TRADE_TRANSACTION_HISTORY_DELETE:
            if(m_logger != NULL)
            {
               m_logger.Debug("History deleted: Deal " + IntegerToString(trans.deal));
            }
            break;
      }
   }
};

//+------------------------------------------------------------------+
