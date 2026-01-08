//+------------------------------------------------------------------+
//| SymbolUtils.mqh                                                  |
//| Symbol and price utilities - VPS-safe                           |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Normalize price                                                  |
//+------------------------------------------------------------------+
double NormalizePrice(double price, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   return MathRound(price / tickSize) * tickSize;
}

//+------------------------------------------------------------------+
//| Get point value                                                  |
//+------------------------------------------------------------------+
double GetPointValue(string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   return SymbolInfoDouble(symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Convert points to price                                          |
//+------------------------------------------------------------------+
double PointsToPrice(int points, string symbol = NULL)
{
   return points * GetPointValue(symbol);
}

//+------------------------------------------------------------------+
//| Convert price difference to points                              |
//+------------------------------------------------------------------+
int PriceToPoints(double priceDiff, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   double pointValue = GetPointValue(symbol);
   if(pointValue <= 0) return 0;
   return (int)MathRound(priceDiff / pointValue);
}

//+------------------------------------------------------------------+
//| Get spread in points                                            |
//+------------------------------------------------------------------+
int GetSpreadPoints(string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   return PriceToPoints(ask - bid, symbol);
}

//+------------------------------------------------------------------+
//| Get stop level in points                                         |
//+------------------------------------------------------------------+
int GetStopLevel(string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   return (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
}

//+------------------------------------------------------------------+
//| Check if price is valid for order                                |
//+------------------------------------------------------------------+
bool IsValidOrderPrice(double price, ENUM_ORDER_TYPE orderType, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   int stopLevel = GetStopLevel(symbol);
   double pointValue = GetPointValue(symbol);
   double minDistance = stopLevel * pointValue;
   
   switch(orderType)
   {
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_BUY_LIMIT:
      case ORDER_TYPE_BUY_STOP:
         if(orderType == ORDER_TYPE_BUY_LIMIT && price >= ask - minDistance)
            return false;
         if(orderType == ORDER_TYPE_BUY_STOP && price <= ask + minDistance)
            return false;
         break;
         
      case ORDER_TYPE_SELL:
      case ORDER_TYPE_SELL_LIMIT:
      case ORDER_TYPE_SELL_STOP:
         if(orderType == ORDER_TYPE_SELL_LIMIT && price <= bid + minDistance)
            return false;
         if(orderType == ORDER_TYPE_SELL_STOP && price >= bid - minDistance)
            return false;
         break;
   }
   
   return true;
}

//+------------------------------------------------------------------+
