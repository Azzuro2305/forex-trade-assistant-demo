//+------------------------------------------------------------------+
//| DrawManager.mqh                                                  |
//| Chart drawing utilities - LOCAL ONLY                            |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"
#include "ObjectNames.mqh"

//+------------------------------------------------------------------+
//| Draw Manager class (Local Only - not for VPS)                   |
//+------------------------------------------------------------------+
// Note: This uses ObjectCreate which is not available on VPS
// All drawing operations should be wrapped with EnableUI checks

class CDrawManager
{
private:
   bool m_enabled;
   
public:
   CDrawManager(bool enabled = true) : m_enabled(enabled) {}
   
   void SetEnabled(bool enabled) { m_enabled = enabled; }
   bool IsEnabled() const { return m_enabled; }
   
   //+------------------------------------------------------------------+
   //| Draw line (wrapped with enabled check)                        |
   //+------------------------------------------------------------------+
   bool DrawLine(string name, double price, color lineColor, int width = 1, int style = STYLE_SOLID)
   {
      if(!m_enabled) return false;
      
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      
      if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, price))
         return false;
      
      ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_STYLE, style);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      
      ChartRedraw();
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Delete line                                                     |
   //+------------------------------------------------------------------+
   void DeleteLine(string name)
   {
      if(!m_enabled) return;
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      ChartRedraw();
   }
};

//+------------------------------------------------------------------+
