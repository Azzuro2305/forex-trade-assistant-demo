//+------------------------------------------------------------------+
//| TradeManager.mqh                                                 |
//| Order management - VPS-SAFE ONLY                                |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"
#include "../Core/MathRisk.mqh"
#include "../Core/SymbolUtils.mqh"
#include "../Core/Logger.mqh"

//+------------------------------------------------------------------+
//| Trade Manager class                                             |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
   int      m_magicNumber;
   string   m_tradeComment;
   int      m_slippage;
   CLogger* m_logger;
   
   //+------------------------------------------------------------------+
   //| Get supported filling mode                                      |
   //+------------------------------------------------------------------+
   ENUM_ORDER_TYPE_FILLING GetFillingMode(string symbol = NULL)
   {
      if(symbol == NULL) symbol = _Symbol;
      int filling = (int)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
      
      // Check which filling modes are supported (bitmask)
      // Bit 0 (1) = FOK, Bit 1 (2) = IOC, Bit 2 (4) = RETURN
      if((filling & 1) == 1)  // FOK
         return ORDER_FILLING_FOK;
      else if((filling & 2) == 2)  // IOC
         return ORDER_FILLING_IOC;
      else if((filling & 4) == 4)  // RETURN
         return ORDER_FILLING_RETURN;
      
      // Default fallback
      return ORDER_FILLING_FOK;
   }

public:
   CTradeManager(int magic, string comment, CLogger* logger) 
      : m_magicNumber(magic), m_tradeComment(comment), m_slippage(InpSlippage)
   {
      m_logger = logger;
   }
   
   //+------------------------------------------------------------------+
   //| Open buy order                                                 |
   //+------------------------------------------------------------------+
   bool OpenBuy(double lotSize, int stopLoss = 0, int takeProfit = 0, string symbol = NULL)
   {
      if(symbol == NULL) symbol = _Symbol;
      
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double sl = (stopLoss > 0) ? NormalizePrice(ask - PointsToPrice(stopLoss, symbol), symbol) : 0;
      double tp = (takeProfit > 0) ? NormalizePrice(ask + PointsToPrice(takeProfit, symbol), symbol) : 0;
      
      lotSize = NormalizeLot(lotSize, symbol);
      
      MqlTradeRequest request = {};
      MqlTradeResult  result = {};
      
      request.action = TRADE_ACTION_DEAL;
      request.symbol = symbol;
      request.volume = lotSize;
      request.type = ORDER_TYPE_BUY;
      request.price = ask;
      request.sl = sl;
      request.tp = tp;
      request.deviation = m_slippage;
      request.magic = m_magicNumber;
      request.comment = m_tradeComment;
      request.type_filling = GetFillingMode(symbol);
      
      if(!OrderSend(request, result))
      {
         // If filling mode failed, try alternative filling modes
         if(result.retcode == 10030 || result.retcode == TRADE_RETCODE_INVALID_FILL)
         {
            int filling = (int)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
            
            // Try IOC if FOK failed
            if((filling & 2) == 2)  // IOC
            {
               request.type_filling = ORDER_FILLING_IOC;
               if(OrderSend(request, result))
               {
                  if(m_logger != NULL)
                     m_logger.Info("Buy order opened (IOC): Ticket " + IntegerToString(result.order) + ", Lot: " + DoubleToString(lotSize, 2));
                  return true;
               }
            }
            
            // Try RETURN if IOC failed
            if((filling & 4) == 4)  // RETURN
            {
               request.type_filling = ORDER_FILLING_RETURN;
               if(OrderSend(request, result))
               {
                  if(m_logger != NULL)
                     m_logger.Info("Buy order opened (RETURN): Ticket " + IntegerToString(result.order) + ", Lot: " + DoubleToString(lotSize, 2));
                  return true;
               }
            }
         }
         
         if(m_logger != NULL)
            m_logger.Error("Buy order failed: " + IntegerToString(result.retcode) + " - " + result.comment);
         return false;
      }
      
      if(m_logger != NULL)
         m_logger.Info("Buy order opened: Ticket " + IntegerToString(result.order) + ", Lot: " + DoubleToString(lotSize, 2));
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Open sell order                                                |
   //+------------------------------------------------------------------+
   bool OpenSell(double lotSize, int stopLoss = 0, int takeProfit = 0, string symbol = NULL)
   {
      if(symbol == NULL) symbol = _Symbol;
      
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double sl = (stopLoss > 0) ? NormalizePrice(bid + PointsToPrice(stopLoss, symbol), symbol) : 0;
      double tp = (takeProfit > 0) ? NormalizePrice(bid - PointsToPrice(takeProfit, symbol), symbol) : 0;
      
      lotSize = NormalizeLot(lotSize, symbol);
      
      MqlTradeRequest request = {};
      MqlTradeResult  result = {};
      
      request.action = TRADE_ACTION_DEAL;
      request.symbol = symbol;
      request.volume = lotSize;
      request.type = ORDER_TYPE_SELL;
      request.price = bid;
      request.sl = sl;
      request.tp = tp;
      request.deviation = m_slippage;
      request.magic = m_magicNumber;
      request.comment = m_tradeComment;
      request.type_filling = GetFillingMode(symbol);
      
      if(!OrderSend(request, result))
      {
         // If filling mode failed, try alternative filling modes
         if(result.retcode == 10030 || result.retcode == TRADE_RETCODE_INVALID_FILL)
         {
            int filling = (int)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
            
            // Try IOC if FOK failed
            if((filling & 2) == 2)  // IOC
            {
               request.type_filling = ORDER_FILLING_IOC;
               if(OrderSend(request, result))
               {
                  if(m_logger != NULL)
                     m_logger.Info("Sell order opened (IOC): Ticket " + IntegerToString(result.order) + ", Lot: " + DoubleToString(lotSize, 2));
                  return true;
               }
            }
            
            // Try RETURN if IOC failed
            if((filling & 4) == 4)  // RETURN
            {
               request.type_filling = ORDER_FILLING_RETURN;
               if(OrderSend(request, result))
               {
                  if(m_logger != NULL)
                     m_logger.Info("Sell order opened (RETURN): Ticket " + IntegerToString(result.order) + ", Lot: " + DoubleToString(lotSize, 2));
                  return true;
               }
            }
         }
         
         if(m_logger != NULL)
            m_logger.Error("Sell order failed: " + IntegerToString(result.retcode) + " - " + result.comment);
         return false;
      }
      
      if(m_logger != NULL)
         m_logger.Info("Sell order opened: Ticket " + IntegerToString(result.order) + ", Lot: " + DoubleToString(lotSize, 2));
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Open buy limit order                                           |
   //+------------------------------------------------------------------+
   bool OpenBuyLimit(double price, double lotSize, int stopLoss = 0, int takeProfit = 0, string symbol = NULL)
   {
      if(symbol == NULL) symbol = _Symbol;
      
      double sl = (stopLoss > 0) ? NormalizePrice(price - PointsToPrice(stopLoss, symbol), symbol) : 0;
      double tp = (takeProfit > 0) ? NormalizePrice(price + PointsToPrice(takeProfit, symbol), symbol) : 0;
      
      lotSize = NormalizeLot(lotSize, symbol);
      
      MqlTradeRequest request = {};
      MqlTradeResult  result = {};
      
      request.action = TRADE_ACTION_PENDING;
      request.symbol = symbol;
      request.volume = lotSize;
      request.type = ORDER_TYPE_BUY_LIMIT;
      request.price = NormalizePrice(price, symbol);
      request.sl = sl;
      request.tp = tp;
      request.magic = m_magicNumber;
      request.comment = m_tradeComment;
      
      if(!OrderSend(request, result))
      {
         if(m_logger != NULL)
            m_logger.Error("Buy limit order failed: " + IntegerToString(result.retcode) + " - " + result.comment);
         return false;
      }
      
      if(m_logger != NULL)
         m_logger.Info("Buy limit order placed: Ticket " + IntegerToString(result.order) + ", Price: " + DoubleToString(price, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Open buy stop order                                            |
   //+------------------------------------------------------------------+
   bool OpenBuyStop(double price, double lotSize, int stopLoss = 0, int takeProfit = 0, string symbol = NULL)
   {
      if(symbol == NULL) symbol = _Symbol;
      
      double currentAsk = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double minPrice = currentAsk;
      int stopLevel = GetStopLevel(symbol);
      
      // Add minimum stop level distance if required
      if(stopLevel > 0)
      {
         minPrice = currentAsk + PointsToPrice(stopLevel, symbol);
      }
      else
      {
         // Even without stop level, add a small buffer (1 point minimum)
         double point = GetPointValue(symbol);
         minPrice = currentAsk + point;
      }
      
      // Ensure price is normalized and above minimum
      double adjustedPrice = NormalizePrice(price, symbol);
      if(adjustedPrice <= minPrice)
      {
         adjustedPrice = NormalizePrice(minPrice, symbol);
         if(m_logger != NULL)
            m_logger.Warn("Buy stop price adjusted from " + DoubleToString(price, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + " to " + DoubleToString(adjustedPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
      }
      
      double sl = (stopLoss > 0) ? NormalizePrice(adjustedPrice - PointsToPrice(stopLoss, symbol), symbol) : 0;
      double tp = (takeProfit > 0) ? NormalizePrice(adjustedPrice + PointsToPrice(takeProfit, symbol), symbol) : 0;
      
      lotSize = NormalizeLot(lotSize, symbol);
      
      MqlTradeRequest request = {};
      MqlTradeResult  result = {};
      
      request.action = TRADE_ACTION_PENDING;
      request.symbol = symbol;
      request.volume = lotSize;
      request.type = ORDER_TYPE_BUY_STOP;
      request.price = adjustedPrice;
      request.sl = sl;
      request.tp = tp;
      request.magic = m_magicNumber;
      request.comment = m_tradeComment;
      
      if(!OrderSend(request, result))
      {
         if(m_logger != NULL)
            m_logger.Error("Buy stop order failed: " + IntegerToString(result.retcode) + " - " + result.comment);
         return false;
      }
      
      if(m_logger != NULL)
         m_logger.Info("Buy stop order placed: Ticket " + IntegerToString(result.order) + ", Price: " + DoubleToString(adjustedPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Open sell limit order                                          |
   //+------------------------------------------------------------------+
   bool OpenSellLimit(double price, double lotSize, int stopLoss = 0, int takeProfit = 0, string symbol = NULL)
   {
      if(symbol == NULL) symbol = _Symbol;
      
      double sl = (stopLoss > 0) ? NormalizePrice(price + PointsToPrice(stopLoss, symbol), symbol) : 0;
      double tp = (takeProfit > 0) ? NormalizePrice(price - PointsToPrice(takeProfit, symbol), symbol) : 0;
      
      lotSize = NormalizeLot(lotSize, symbol);
      
      MqlTradeRequest request = {};
      MqlTradeResult  result = {};
      
      request.action = TRADE_ACTION_PENDING;
      request.symbol = symbol;
      request.volume = lotSize;
      request.type = ORDER_TYPE_SELL_LIMIT;
      request.price = NormalizePrice(price, symbol);
      request.sl = sl;
      request.tp = tp;
      request.magic = m_magicNumber;
      request.comment = m_tradeComment;
      
      if(!OrderSend(request, result))
      {
         if(m_logger != NULL)
            m_logger.Error("Sell limit order failed: " + IntegerToString(result.retcode) + " - " + result.comment);
         return false;
      }
      
      if(m_logger != NULL)
         m_logger.Info("Sell limit order placed: Ticket " + IntegerToString(result.order) + ", Price: " + DoubleToString(price, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Open sell stop order                                           |
   //+------------------------------------------------------------------+
   bool OpenSellStop(double price, double lotSize, int stopLoss = 0, int takeProfit = 0, string symbol = NULL)
   {
      if(symbol == NULL) symbol = _Symbol;
      
      double sl = (stopLoss > 0) ? NormalizePrice(price + PointsToPrice(stopLoss, symbol), symbol) : 0;
      double tp = (takeProfit > 0) ? NormalizePrice(price - PointsToPrice(takeProfit, symbol), symbol) : 0;
      
      lotSize = NormalizeLot(lotSize, symbol);
      
      MqlTradeRequest request = {};
      MqlTradeResult  result = {};
      
      request.action = TRADE_ACTION_PENDING;
      request.symbol = symbol;
      request.volume = lotSize;
      request.type = ORDER_TYPE_SELL_STOP;
      request.price = NormalizePrice(price, symbol);
      request.sl = sl;
      request.tp = tp;
      request.magic = m_magicNumber;
      request.comment = m_tradeComment;
      
      if(!OrderSend(request, result))
      {
         if(m_logger != NULL)
            m_logger.Error("Sell stop order failed: " + IntegerToString(result.retcode) + " - " + result.comment);
         return false;
      }
      
      if(m_logger != NULL)
         m_logger.Info("Sell stop order placed: Ticket " + IntegerToString(result.order) + ", Price: " + DoubleToString(price, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Close all positions                                            |
   //+------------------------------------------------------------------+
   bool CloseAllPositions(string symbol = NULL)
   {
      if(symbol == NULL) symbol = _Symbol;
      
      bool closed = false;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == symbol && 
            PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
         {
            if(ClosePosition(ticket))
               closed = true;
         }
      }
      return closed;
   }
   
   //+------------------------------------------------------------------+
   //| Close position by ticket                                       |
   //+------------------------------------------------------------------+
   bool ClosePosition(ulong ticket)
   {
      if(!PositionSelectByTicket(ticket))
         return false;
      
      string symbol = PositionGetString(POSITION_SYMBOL);
      
      MqlTradeRequest request = {};
      MqlTradeResult  result = {};
      
      request.action = TRADE_ACTION_DEAL;
      request.position = ticket;
      request.symbol = symbol;
      request.volume = PositionGetDouble(POSITION_VOLUME);
      request.deviation = m_slippage;
      request.magic = m_magicNumber;
      
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         request.type = ORDER_TYPE_SELL;
         request.price = SymbolInfoDouble(symbol, SYMBOL_BID);
      }
      else
      {
         request.type = ORDER_TYPE_BUY;
         request.price = SymbolInfoDouble(symbol, SYMBOL_ASK);
      }
      
      request.type_filling = GetFillingMode(symbol);
      
      if(!OrderSend(request, result))
      {
         if(m_logger != NULL)
            m_logger.Error("Close position failed: " + IntegerToString(result.retcode));
         return false;
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Get number of open positions                                   |
   //+------------------------------------------------------------------+
   int GetOpenPositionsCount(string symbol = NULL)
   {
      if(symbol == NULL) symbol = _Symbol;
      
      int count = 0;
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionGetTicket(i) > 0 && 
            PositionGetString(POSITION_SYMBOL) == symbol && 
            PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
         {
            count++;
         }
      }
      return count;
   }
   
   //+------------------------------------------------------------------+
   //| Modify position SL/TP                                          |
   //+------------------------------------------------------------------+
   bool ModifyPosition(ulong ticket, double sl, double tp)
   {
      if(!PositionSelectByTicket(ticket))
         return false;
      
      string symbol = PositionGetString(POSITION_SYMBOL);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      
      // Normalize prices
      sl = (sl > 0) ? NormalizePrice(sl, symbol) : 0;
      tp = (tp > 0) ? NormalizePrice(tp, symbol) : 0;
      
      // Check if modification is needed
      if(MathAbs(sl - currentSL) < GetPointValue(symbol) && 
         MathAbs(tp - currentTP) < GetPointValue(symbol))
         return true; // No change needed
      
      MqlTradeRequest request = {};
      MqlTradeResult  result = {};
      
      request.action = TRADE_ACTION_SLTP;
      request.position = ticket;
      request.symbol = symbol;
      request.sl = sl;
      request.tp = tp;
      request.magic = m_magicNumber;
      
      if(!OrderSend(request, result))
      {
         if(m_logger != NULL)
            m_logger.Error("Modify position failed: " + IntegerToString(result.retcode));
         return false;
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Get magic number                                               |
   //+------------------------------------------------------------------+
   int GetMagicNumber() const { return m_magicNumber; }
};

//+------------------------------------------------------------------+
