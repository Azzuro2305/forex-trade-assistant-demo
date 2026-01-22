//+------------------------------------------------------------------+
//| MathRisk.mqh                                                     |
//| Risk calculation utilities - VPS-safe                          |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"

//+------------------------------------------------------------------+
//| Normalize lot size                                               |
//+------------------------------------------------------------------+
double NormalizeLot(double lot, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   if(lot < minLot) return minLot;
   if(lot > maxLot) return maxLot;
   
   return MathFloor(lot / lotStep) * lotStep;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                     |
//+------------------------------------------------------------------+
double CalculateLotSizeByRisk(double riskPercent, int stopLossPoints, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   if(stopLossPoints <= 0 || riskPercent <= 0) return InpLotSize;
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (riskPercent / 100.0);
   
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pointValueInCurrency = tickValue * (pointValue / tickSize);
   
   double lotSize = riskAmount / (stopLossPoints * pointValueInCurrency);
   
   return NormalizeLot(lotSize, symbol);
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk amount in currency             |
//+------------------------------------------------------------------+
double CalculateLotSizeByCurrency(double riskAmount, int stopLossPoints, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   if(stopLossPoints <= 0 || riskAmount <= 0) return InpLotSize;
   
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pointValueInCurrency = tickValue * (pointValue / tickSize);
   
   double lotSize = riskAmount / (stopLossPoints * pointValueInCurrency);
   
   return NormalizeLot(lotSize, symbol);
}

//+------------------------------------------------------------------+
//| Calculate risk amount from lot size and stop loss               |
//+------------------------------------------------------------------+
double CalculateRiskAmount(double lotSize, int stopLossPoints, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   if(stopLossPoints <= 0 || lotSize <= 0) return 0;
   
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pointValueInCurrency = tickValue * (pointValue / tickSize);
   
   return lotSize * stopLossPoints * pointValueInCurrency;
}

//+------------------------------------------------------------------+
//| Calculate profit amount from lot size and take profit            |
//+------------------------------------------------------------------+
double CalculateProfitAmount(double lotSize, int takeProfitPoints, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   if(takeProfitPoints <= 0 || lotSize <= 0) return 0;
   
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pointValueInCurrency = tickValue * (pointValue / tickSize);
   
   return lotSize * takeProfitPoints * pointValueInCurrency;
}

//+------------------------------------------------------------------+
//| Calculate risk percentage from lot size and stop loss           |
//+------------------------------------------------------------------+
double CalculateRiskPercent(double lotSize, int stopLossPoints, string symbol = NULL)
{
   if(symbol == NULL) symbol = _Symbol;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0) return 0;
   
   double riskAmount = CalculateRiskAmount(lotSize, stopLossPoints, symbol);
   return (riskAmount / balance) * 100.0;
}
//+------------------------------------------------------------------+
