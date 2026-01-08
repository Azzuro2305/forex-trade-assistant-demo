//+------------------------------------------------------------------+
//| VisualTradeLines.mqh                                             |
//| Draggable visual trading lines for chart                        |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"
#include "../Core/SymbolUtils.mqh"
#include "../Core/MathRisk.mqh"
#include "../Utils/Helpers.mqh"

//+------------------------------------------------------------------+
//| Helper: Convert Y coordinate to price                            |
//+------------------------------------------------------------------+
double YToPrice(int y)
{
   long chartHeight = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   
   // Get visible price range
   double maxPrice = ChartGetDouble(0, CHART_PRICE_MAX, 0);
   double minPrice = ChartGetDouble(0, CHART_PRICE_MIN, 0);
   
   if(maxPrice <= minPrice) return (maxPrice + minPrice) / 2.0;
   
   // Calculate price from Y position (reverse of PriceToY)
   // Y=0 is at top (max price), Y=chartHeight is at bottom (min price)
   double priceRange = maxPrice - minPrice;
   double yRatio = (double)(chartHeight - y) / (double)chartHeight;
   double price = minPrice + (priceRange * yRatio);
   
   return price;
}

//+------------------------------------------------------------------+
//| Visual Trade Line class                                          |
//+------------------------------------------------------------------+
class CVisualTradeLine
{
private:
   string   m_name;
   string   m_labelName;
   string   m_inputName;
   string   m_buttonName;
   string   m_orderTypeLabelName;
   double   m_price;
   color    m_lineColor;
   int      m_lineWidth;
   int      m_lineStyle;
   bool     m_isDragging;
   bool     m_isSelected;
   bool     m_isEntryLine;
   datetime m_time1;
   datetime m_time2;
   ENUM_LINE_STYLE m_style;
   
public:
   CVisualTradeLine(string name, color lineColor, int width = 2, int style = STYLE_SOLID, bool isEntry = false)
   {
      m_name = name;
      m_labelName = name + "_Label";
      m_inputName = name + "_Input";
      m_buttonName = name + "_Button";
      m_orderTypeLabelName = name + "_OrderType";
      m_lineColor = lineColor;
      m_lineWidth = width;
      m_lineStyle = style;
      m_price = 0;
      m_isDragging = false;
      m_isSelected = false;
      m_isEntryLine = isEntry;
      m_time1 = 0;
      m_time2 = 0;
      m_style = (ENUM_LINE_STYLE)style;
   }
   
   ~CVisualTradeLine()
   {
      DeleteLine();
      DeleteLabel();
      DeleteInput();
      DeleteButton();
      DeleteOrderTypeLabel();
   }
   
   //+------------------------------------------------------------------+
   //| Create line on chart                                            |
   //+------------------------------------------------------------------+
   bool CreateLine(double price, datetime time1 = 0, datetime time2 = 0)
   {
      if(time1 == 0) time1 = iTime(_Symbol, PERIOD_CURRENT, 0);
      if(time2 == 0) time2 = iTime(_Symbol, PERIOD_CURRENT, PeriodSeconds(PERIOD_CURRENT) * 100);
      
      m_price = NormalizePrice(price);
      m_time1 = time1;
      m_time2 = time2;
      
      if(ObjectFind(0, m_name) >= 0)
         ObjectDelete(0, m_name);
      
      if(!ObjectCreate(0, m_name, OBJ_HLINE, 0, 0, m_price))
         return false;
      
      ObjectSetInteger(0, m_name, OBJPROP_COLOR, m_lineColor);
      ObjectSetInteger(0, m_name, OBJPROP_WIDTH, m_lineWidth);
      ObjectSetInteger(0, m_name, OBJPROP_STYLE, m_lineStyle);
      ObjectSetInteger(0, m_name, OBJPROP_BACK, false);
      ObjectSetInteger(0, m_name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, m_name, OBJPROP_SELECTED, true); // Pre-select for immediate dragging
      ObjectSetInteger(0, m_name, OBJPROP_HIDDEN, false);
      ObjectSetInteger(0, m_name, OBJPROP_ZORDER, 0); // Make sure lines are on top
      ObjectSetString(0, m_name, OBJPROP_TOOLTIP, m_name + ": " + DoubleToString(m_price, _Digits));
      
      CreateLabel();
      CreateInput();
      if(m_isEntryLine)
      {
         CreateOpenButton();
         CreateOrderTypeLabel();
      }
      
      ChartRedraw();
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create label                                                    |
   //+------------------------------------------------------------------+
   void CreateLabel()
   {
      if(ObjectFind(0, m_labelName) >= 0)
         ObjectDelete(0, m_labelName);
      
      int x = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - 150;
      int y = PriceToY(m_price);
      
      if(!ObjectCreate(0, m_labelName, OBJ_LABEL, 0, 0, 0))
         return;
      
      ObjectSetInteger(0, m_labelName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, m_labelName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, m_labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, m_labelName, OBJPROP_TEXT, m_name + ": " + DoubleToString(m_price, _Digits));
      ObjectSetInteger(0, m_labelName, OBJPROP_COLOR, m_lineColor);
      ObjectSetInteger(0, m_labelName, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, m_labelName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, m_labelName, OBJPROP_BACK, false);
      ObjectSetInteger(0, m_labelName, OBJPROP_SELECTABLE, false);
   }
   
   //+------------------------------------------------------------------+
   //| Create input box                                                |
   //+------------------------------------------------------------------+
   void CreateInput()
   {
      if(ObjectFind(0, m_inputName) >= 0)
         ObjectDelete(0, m_inputName);
      
      int x = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - 80;
      int y = PriceToY(m_price) + 15;
      
      if(!ObjectCreate(0, m_inputName, OBJ_EDIT, 0, 0, 0))
         return;
      
      ObjectSetInteger(0, m_inputName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, m_inputName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, m_inputName, OBJPROP_XSIZE, 70);
      ObjectSetInteger(0, m_inputName, OBJPROP_YSIZE, 20);
      ObjectSetInteger(0, m_inputName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, m_inputName, OBJPROP_TEXT, DoubleToString(m_price, _Digits));
      ObjectSetInteger(0, m_inputName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, m_inputName, OBJPROP_BGCOLOR, clrDarkSlateGray);
      ObjectSetInteger(0, m_inputName, OBJPROP_BORDER_COLOR, m_lineColor);
      ObjectSetInteger(0, m_inputName, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, m_inputName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, m_inputName, OBJPROP_READONLY, false);
      ObjectSetString(0, m_inputName, OBJPROP_TOOLTIP, "Enter price or points (prefix with 'p' for points)");
   }
   
   //+------------------------------------------------------------------+
   //| Create open button (for entry line only)                        |
   //+------------------------------------------------------------------+
   void CreateOpenButton()
   {
      if(!m_isEntryLine) return;
      
      if(ObjectFind(0, m_buttonName) >= 0)
         ObjectDelete(0, m_buttonName);
      
      int x = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - 160;
      int y = PriceToY(m_price);
      
      if(!ObjectCreate(0, m_buttonName, OBJ_BUTTON, 0, 0, 0))
         return;
      
      ObjectSetInteger(0, m_buttonName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, m_buttonName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, m_buttonName, OBJPROP_XSIZE, 60);
      ObjectSetInteger(0, m_buttonName, OBJPROP_YSIZE, 22);
      ObjectSetInteger(0, m_buttonName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, m_buttonName, OBJPROP_TEXT, "Open");
      ObjectSetInteger(0, m_buttonName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, m_buttonName, OBJPROP_BGCOLOR, clrLimeGreen);
      ObjectSetInteger(0, m_buttonName, OBJPROP_BORDER_COLOR, clrWhite);
      ObjectSetInteger(0, m_buttonName, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, m_buttonName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, m_buttonName, OBJPROP_BACK, false);
      ObjectSetInteger(0, m_buttonName, OBJPROP_SELECTABLE, false);
   }
   
   //+------------------------------------------------------------------+
   //| Create order type label (for entry line only)                   |
   //+------------------------------------------------------------------+
   void CreateOrderTypeLabel()
   {
      if(!m_isEntryLine) return;
      
      if(ObjectFind(0, m_orderTypeLabelName) >= 0)
         ObjectDelete(0, m_orderTypeLabelName);
      
      int x = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - 230;
      int y = PriceToY(m_price) - 12;
      
      string orderTypeText = GetOrderTypeText();
      
      if(!ObjectCreate(0, m_orderTypeLabelName, OBJ_LABEL, 0, 0, 0))
         return;
      
      ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, m_orderTypeLabelName, OBJPROP_TEXT, orderTypeText);
      ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, m_orderTypeLabelName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_BACK, false);
      ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_SELECTABLE, false);
   }
   
   //+------------------------------------------------------------------+
   //| Get order type text                                             |
   //+------------------------------------------------------------------+
   string GetOrderTypeText()
   {
      if(!m_isEntryLine) return "";
      
      double entryPrice = m_price;
      // Determine if buy or sell based on line color (buy = blue, sell = red)
      bool isBuy = (m_lineColor == clrDodgerBlue || m_lineColor == InpBuyLineColor);
      
      double currentPrice = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double pointValue = GetPointValue();
      
      // If entry is far from current price, it's a pending order
      if(MathAbs(entryPrice - currentPrice) > pointValue * 10)
      {
         if(isBuy)
            return (entryPrice < currentPrice) ? "BUY LIMIT" : "BUY STOP";
         else
            return (entryPrice > currentPrice) ? "SELL LIMIT" : "SELL STOP";
      }
      
      return ""; // Market order - no label needed
   }
   
   //+------------------------------------------------------------------+
   //| Update order type label                                         |
   //+------------------------------------------------------------------+
   void UpdateOrderTypeLabel()
   {
      if(!m_isEntryLine || ObjectFind(0, m_orderTypeLabelName) < 0)
         return;
      
      int y = PriceToY(m_price) - 12;
      ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_YDISTANCE, y);
      
      string orderTypeText = GetOrderTypeText();
      ObjectSetString(0, m_orderTypeLabelName, OBJPROP_TEXT, orderTypeText);
      
      // Hide label if market order
      if(StringLen(orderTypeText) == 0)
         ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
      else
         ObjectSetInteger(0, m_orderTypeLabelName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   
   //+------------------------------------------------------------------+
   //| Handle input change                                             |
   //+------------------------------------------------------------------+
   bool HandleInputChange(string inputText, double referencePrice = 0)
   {
      if(StringLen(inputText) == 0) return false;
      
      // Check if input is points (starts with 'p' or 'P')
      if(StringGetCharacter(inputText, 0) == 'p' || StringGetCharacter(inputText, 0) == 'P')
      {
         string pointsStr = StringSubstr(inputText, 1);
         int points = (int)StringToInteger(pointsStr);
         
         if(referencePrice > 0)
         {
            double newPrice = referencePrice + (points * GetPointValue());
            if(StringFind(m_name, "SL") >= 0 || StringFind(m_name, "TP") >= 0)
            {
               // For SL/TP, determine direction based on line type
               if(StringFind(m_name, "SL") >= 0)
               {
                  // SL is below entry for buy, above for sell
                  // This will be handled by the manager
               }
            }
            UpdatePrice(newPrice);
            return true;
         }
      }
      else
      {
         // Direct price input
         double newPrice = StringToDouble(inputText);
         if(newPrice > 0)
         {
            UpdatePrice(newPrice);
            return true;
         }
      }
      
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Update line price                                               |
   //+------------------------------------------------------------------+
   bool UpdatePrice(double newPrice)
   {
      m_price = NormalizePrice(newPrice);
      
      if(ObjectFind(0, m_name) < 0)
         return false;
      
      ObjectSetDouble(0, m_name, OBJPROP_PRICE, m_price);
      UpdateLabel();
      UpdateInput();
      if(m_isEntryLine)
      {
         UpdateButton();
         UpdateOrderTypeLabel();
      }
      ChartRedraw();
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Update label                                                    |
   //+------------------------------------------------------------------+
   void UpdateLabel()
   {
      if(ObjectFind(0, m_labelName) < 0)
         return;
      
      int y = PriceToY(m_price);
      ObjectSetInteger(0, m_labelName, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, m_labelName, OBJPROP_TEXT, m_name + ": " + DoubleToString(m_price, _Digits));
   }
   
   //+------------------------------------------------------------------+
   //| Update input                                                    |
   //+------------------------------------------------------------------+
   void UpdateInput()
   {
      if(ObjectFind(0, m_inputName) < 0)
         return;
      
      int y = PriceToY(m_price) + 15;
      ObjectSetInteger(0, m_inputName, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, m_inputName, OBJPROP_TEXT, DoubleToString(m_price, _Digits));
   }
   
   //+------------------------------------------------------------------+
   //| Update button                                                    |
   //+------------------------------------------------------------------+
   void UpdateButton()
   {
      if(!m_isEntryLine || ObjectFind(0, m_buttonName) < 0)
         return;
      
      int y = PriceToY(m_price);
      ObjectSetInteger(0, m_buttonName, OBJPROP_YDISTANCE, y);
   }
   
   //+------------------------------------------------------------------+
   //| Get current price                                              |
   //+------------------------------------------------------------------+
   double GetPrice() { return m_price; }
   
   //+------------------------------------------------------------------+
   //| Get price in points from reference                             |
   //+------------------------------------------------------------------+
   int GetPriceInPoints(double referencePrice)
   {
      return (int)MathRound(MathAbs(m_price - referencePrice) / GetPointValue());
   }
   
   //+------------------------------------------------------------------+
   //| Check if clicked                                               |
   //+------------------------------------------------------------------+
   bool IsClicked(int x, int y)
   {
      if(ObjectFind(0, m_name) < 0) return false;
      
      double price = YToPrice(y);
      double linePrice = ObjectGetDouble(0, m_name, OBJPROP_PRICE);
      double pointValue = GetPointValue();
      
      // Check if click is within 5 points of line
      if(MathAbs(price - linePrice) <= pointValue * 5)
      {
         m_isSelected = true;
         ObjectSetInteger(0, m_name, OBJPROP_SELECTED, true);
         ChartRedraw();
         return true;
      }
      
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Delete line                                                     |
   //+------------------------------------------------------------------+
   void DeleteLine()
   {
      if(ObjectFind(0, m_name) >= 0)
         ObjectDelete(0, m_name);
   }
   
   //+------------------------------------------------------------------+
   //| Delete label                                                    |
   //+------------------------------------------------------------------+
   void DeleteLabel()
   {
      if(ObjectFind(0, m_labelName) >= 0)
         ObjectDelete(0, m_labelName);
   }
   
   //+------------------------------------------------------------------+
   //| Delete input                                                    |
   //+------------------------------------------------------------------+
   void DeleteInput()
   {
      if(ObjectFind(0, m_inputName) >= 0)
         ObjectDelete(0, m_inputName);
   }
   
   //+------------------------------------------------------------------+
   //| Delete button                                                   |
   //+------------------------------------------------------------------+
   void DeleteButton()
   {
      if(ObjectFind(0, m_buttonName) >= 0)
         ObjectDelete(0, m_buttonName);
   }
   
   //+------------------------------------------------------------------+
   //| Delete order type label                                         |
   //+------------------------------------------------------------------+
   void DeleteOrderTypeLabel()
   {
      if(ObjectFind(0, m_orderTypeLabelName) >= 0)
         ObjectDelete(0, m_orderTypeLabelName);
   }
   
   //+------------------------------------------------------------------+
   //| Get button name                                                 |
   //+------------------------------------------------------------------+
   string GetButtonName() { return m_buttonName; }
   
   //+------------------------------------------------------------------+
   //| Set selected state                                             |
   //+------------------------------------------------------------------+
   void SetSelected(bool selected)
   {
      m_isSelected = selected;
      if(ObjectFind(0, m_name) >= 0)
         ObjectSetInteger(0, m_name, OBJPROP_SELECTED, selected);
   }
   
   //+------------------------------------------------------------------+
   //| Get name                                                        |
   //+------------------------------------------------------------------+
   string GetName() { return m_name; }
};

//+------------------------------------------------------------------+
//| Visual Trade Lines Manager                                       |
//+------------------------------------------------------------------+
class CVisualTradeLines
{
private:
   CVisualTradeLine* m_entryLine;
   CVisualTradeLine* m_tpLine;
   CVisualTradeLine* m_slLine;
   string            m_tpAreaName;
   string            m_slAreaName;
   bool              m_isActive;
   bool              m_isBuy;
   string            m_baseName;
   color             m_buyColor;
   color             m_sellColor;
   color             m_tpColor;
   color             m_slColor;
   int               m_lineWidth;
   int               m_lineStyle;
   
   //+------------------------------------------------------------------+
   //| Create shaded areas                                             |
   //+------------------------------------------------------------------+
   void CreateShadedAreas()
   {
      if(!m_isActive) return;
      
      m_tpAreaName = m_baseName + "_TPArea";
      m_slAreaName = m_baseName + "_SLArea";
      
      UpdateShadedAreas();
   }
   
   //+------------------------------------------------------------------+
   //| Update shaded areas                                             |
   //+------------------------------------------------------------------+
   // void UpdateShadedAreas()
   // {
   //    if(!m_isActive || m_entryLine == NULL || m_tpLine == NULL || m_slLine == NULL)
   //       return;
      
   //    double entryPrice = m_entryLine.GetPrice();
   //    double tpPrice = m_tpLine.GetPrice();
   //    double slPrice = m_slLine.GetPrice();
      
   //    datetime time1 = iTime(_Symbol, PERIOD_CURRENT, 0);
   //    datetime time2 = iTime(_Symbol, PERIOD_CURRENT, PeriodSeconds(PERIOD_CURRENT) * 200);
      
   //    // TP area (green - profit zone)
   //    if(ObjectFind(0, m_tpAreaName) >= 0)
   //       ObjectDelete(0, m_tpAreaName);
      
   //    if(m_isBuy && tpPrice > entryPrice)
   //    {
   //       if(ObjectCreate(0, m_tpAreaName, OBJ_RECTANGLE, 0, time1, entryPrice, time2, tpPrice))
   //       {
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_COLOR, C'0,128,0');
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_STYLE, STYLE_SOLID);
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_WIDTH, 1);
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_BACK, true);
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_FILL, true);
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_BGCOLOR, C'0,128,0');
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_SELECTABLE, false);
   //       }
   //    }
   //    else if(!m_isBuy && tpPrice < entryPrice)
   //    {
   //       if(ObjectCreate(0, m_tpAreaName, OBJ_RECTANGLE, 0, time1, tpPrice, time2, entryPrice))
   //       {
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_COLOR, C'0,128,0');
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_STYLE, STYLE_SOLID);
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_WIDTH, 1);
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_BACK, true);
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_FILL, true);
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_BGCOLOR, C'0,128,0');
   //          ObjectSetInteger(0, m_tpAreaName, OBJPROP_SELECTABLE, false);
   //       }
   //    }
      
   //    // SL area (red - loss zone)
   //    if(ObjectFind(0, m_slAreaName) >= 0)
   //       ObjectDelete(0, m_slAreaName);
      
   //    if(m_isBuy && slPrice < entryPrice)
   //    {
   //       if(ObjectCreate(0, m_slAreaName, OBJ_RECTANGLE, 0, time1, slPrice, time2, entryPrice))
   //       {
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_COLOR, C'128,0,0');
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_STYLE, STYLE_SOLID);
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_WIDTH, 1);
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_BACK, true);
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_FILL, true);
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_BGCOLOR, C'128,0,0');
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_SELECTABLE, false);
   //       }
   //    }
   //    else if(!m_isBuy && slPrice > entryPrice)
   //    {
   //       if(ObjectCreate(0, m_slAreaName, OBJ_RECTANGLE, 0, time1, entryPrice, time2, slPrice))
   //       {
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_COLOR, C'128,0,0');
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_STYLE, STYLE_SOLID);
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_WIDTH, 1);
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_BACK, true);
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_FILL, true);
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_BGCOLOR, C'128,0,0');
   //          ObjectSetInteger(0, m_slAreaName, OBJPROP_SELECTABLE, false);
   //       }
   //    }
   // }

   void UpdateShadedAreas()
   {
      if(!m_isActive || m_entryLine == NULL || m_tpLine == NULL || m_slLine == NULL)
         return;
   
      double entry = m_entryLine.GetPrice();
      double tp    = m_tpLine.GetPrice();
      double sl    = m_slLine.GetPrice();
   
      // TP
      if(ObjectFind(0, m_tpAreaName) >= 0)
         ObjectDelete(0, m_tpAreaName);
   
      if(m_isBuy && tp > entry)
         CreateShadeLabel(m_tpAreaName, entry, tp, C'0,128,0');
      else if(!m_isBuy && tp < entry)
         CreateShadeLabel(m_tpAreaName, tp, entry, C'0,128,0');
   
      // SL
      if(ObjectFind(0, m_slAreaName) >= 0)
         ObjectDelete(0, m_slAreaName);
   
      if(m_isBuy && sl < entry)
         CreateShadeLabel(m_slAreaName, sl, entry, C'128,0,0');
      else if(!m_isBuy && sl > entry)
         CreateShadeLabel(m_slAreaName, entry, sl, C'128,0,0');
   }
   

   
public:
   CVisualTradeLines()
   {
      m_entryLine = NULL;
      m_tpLine = NULL;
      m_slLine = NULL;
      m_isActive = false;
      m_isBuy = true;
      m_baseName = "VTL_" + IntegerToString(GetTickCount());
      m_buyColor = InpBuyLineColor;
      m_sellColor = InpSellLineColor;
      m_tpColor = InpTPLineColor;
      m_slColor = InpSLLineColor;
      m_lineWidth = InpLineWidth;
      m_lineStyle = InpLineStyle;
   }
   
   ~CVisualTradeLines()
   {
      DeleteAll();
   }
   
   //+------------------------------------------------------------------+
   //| Create buy setup                                                |
   //+------------------------------------------------------------------+
   bool CreateBuySetup(double entryPrice = 0, double tpPrice = 0, double slPrice = 0)
   {
      if(m_isActive) DeleteAll();
      
      if(entryPrice == 0) entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      // Use fixed RR if enabled, otherwise use default spacing
      if(InpUseFixedRR && InpFixedRR > 0)
      {
         int slPoints = InpStopLoss;
         int tpPoints = (int)MathRound(slPoints * InpFixedRR);
         if(tpPrice == 0) tpPrice = entryPrice + PointsToPrice(tpPoints);
         if(slPrice == 0) slPrice = entryPrice - PointsToPrice(slPoints);
      }
      else
      {
         // Use price gaps: TP = 30.00, SL = 10.00
         if(tpPrice == 0) tpPrice = NormalizePrice(entryPrice + 30.00);
         if(slPrice == 0) slPrice = NormalizePrice(entryPrice - 10.00);
      }
      
      m_isBuy = true;
      m_isActive = true;
      
      m_entryLine = new CVisualTradeLine(m_baseName + "_Entry", m_buyColor, m_lineWidth, m_lineStyle, true);
      m_tpLine = new CVisualTradeLine(m_baseName + "_TP", m_tpColor, m_lineWidth, m_lineStyle, false);
      m_slLine = new CVisualTradeLine(m_baseName + "_SL", m_slColor, m_lineWidth, m_lineStyle, false);
      
      CreateShadedAreas();
      
      if(!m_entryLine.CreateLine(entryPrice) || 
         !m_tpLine.CreateLine(tpPrice) || 
         !m_slLine.CreateLine(slPrice))
      {
         DeleteAll();
         return false;
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create sell setup                                               |
   //+------------------------------------------------------------------+
   bool CreateSellSetup(double entryPrice = 0, double tpPrice = 0, double slPrice = 0)
   {
      if(m_isActive) DeleteAll();
      
      if(entryPrice == 0) entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      // Use fixed RR if enabled, otherwise use default spacing
      if(InpUseFixedRR && InpFixedRR > 0)
      {
         int slPoints = InpStopLoss;
         int tpPoints = (int)MathRound(slPoints * InpFixedRR);
         if(tpPrice == 0) tpPrice = entryPrice - PointsToPrice(tpPoints);
         if(slPrice == 0) slPrice = entryPrice + PointsToPrice(slPoints);
      }
      else
      {
         // Use price gaps: TP = 30.00, SL = 10.00
         if(tpPrice == 0) tpPrice = NormalizePrice(entryPrice - 30.00);
         if(slPrice == 0) slPrice = NormalizePrice(entryPrice + 10.00);
      }
      
      m_isBuy = false;
      m_isActive = true;
      
      m_entryLine = new CVisualTradeLine(m_baseName + "_Entry", m_sellColor, m_lineWidth, m_lineStyle, true);
      m_tpLine = new CVisualTradeLine(m_baseName + "_TP", m_tpColor, m_lineWidth, m_lineStyle, false);
      m_slLine = new CVisualTradeLine(m_baseName + "_SL", m_slColor, m_lineWidth, m_lineStyle, false);
      
      CreateShadedAreas();
      
      if(!m_entryLine.CreateLine(entryPrice) || 
         !m_tpLine.CreateLine(tpPrice) || 
         !m_slLine.CreateLine(slPrice))
      {
         DeleteAll();
         return false;
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Update all lines                                                |
   //+------------------------------------------------------------------+
   void Update()
   {
      // #region agent log
      static int updateCount = 0;
      updateCount++;
      string dataJson0 = "{\"hypothesisId\":\"D\",\"updateCount\":" + IntegerToString(updateCount) + ",\"isActive\":" + (m_isActive ? "true" : "false") + "}";
      WriteDebugLog("VisualTradeLines.mqh:747", "Update() called", dataJson0);
      // #endregion agent log
      
      if(!m_isActive) return;
      
      bool needsUpdate = false;
      
      // Auto-update entry line based on current market price (only for market orders)
      if(m_entryLine != NULL)
      {
         double currentEntryPrice = m_entryLine.GetPrice();
         double currentMarketPrice = m_isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double pointValue = GetPointValue();
         
         // #region agent log
         string dataJson = "{\"hypothesisId\":\"A,B,C,D\",\"currentEntryPrice\":" + DoubleToString(currentEntryPrice, 8) + ",\"currentMarketPrice\":" + DoubleToString(currentMarketPrice, 8) + ",\"pointValue\":" + DoubleToString(pointValue, 8) + ",\"isBuy\":" + (m_isBuy ? "true" : "false") + ",\"priceDiff\":" + DoubleToString(MathAbs(currentEntryPrice - currentMarketPrice), 8) + "}";
         WriteDebugLog("VisualTradeLines.mqh:756", "Update entry line check", dataJson);
         // #endregion agent log
         
         // Check if it's a market order (entry is close to current market price)
         // Use a larger threshold (20 points) to account for price movement
         bool isMarketOrder = (MathAbs(currentEntryPrice - currentMarketPrice) <= pointValue * 20);
         
         // #region agent log
         string dataJson2 = "{\"hypothesisId\":\"A,B,C,D\",\"isMarketOrder\":" + (isMarketOrder ? "true" : "false") + ",\"threshold\":" + DoubleToString(pointValue * 20, 8) + ",\"distance\":" + DoubleToString(MathAbs(currentEntryPrice - currentMarketPrice), 8) + "}";
         WriteDebugLog("VisualTradeLines.mqh:762", "Market order check result", dataJson2);
         // #endregion agent log
         
         if(isMarketOrder)
         {
            // Always update entry line to follow market price for market orders
            double newEntryPrice = NormalizePrice(currentMarketPrice);
            double priceChange = MathAbs(newEntryPrice - currentEntryPrice);
            
            // #region agent log
            string dataJson3 = "{\"hypothesisId\":\"A,B,C,D\",\"newEntryPrice\":" + DoubleToString(newEntryPrice, 8) + ",\"currentEntryPrice\":" + DoubleToString(currentEntryPrice, 8) + ",\"priceChange\":" + DoubleToString(priceChange, 8) + ",\"threshold\":" + DoubleToString(pointValue * 0.01, 8) + ",\"willUpdate\":" + (priceChange > pointValue * 0.01 ? "true" : "false") + "}";
            WriteDebugLog("VisualTradeLines.mqh:770", "Price change check", dataJson3);
            // #endregion agent log
            
            // Always update to current market price when it's a market order (remove threshold check)
            // This ensures the entry line always tracks the market price exactly
            if(priceChange > 0) // Update if there's any change at all
            {
               // Calculate TP and SL offsets from current entry before updating
               double tpOffset = 0;
               double slOffset = 0;
               
               if(m_tpLine != NULL)
                  tpOffset = m_tpLine.GetPrice() - currentEntryPrice;
               
               if(m_slLine != NULL)
                  slOffset = m_slLine.GetPrice() - currentEntryPrice;
               
               // #region agent log
               string dataJson4 = "{\"hypothesisId\":\"A,B,C,D\",\"tpOffset\":" + DoubleToString(tpOffset, 8) + ",\"slOffset\":" + DoubleToString(slOffset, 8) + "}";
               WriteDebugLog("VisualTradeLines.mqh:785", "Before updating entry line", dataJson4);
               // #endregion agent log
               
               // Update entry line to current market price
               m_entryLine.UpdatePrice(newEntryPrice);
               
               // Update TP and SL to maintain their relative positions
               if(m_tpLine != NULL)
                  m_tpLine.UpdatePrice(NormalizePrice(newEntryPrice + tpOffset));
               
               if(m_slLine != NULL)
                  m_slLine.UpdatePrice(NormalizePrice(newEntryPrice + slOffset));
               
               needsUpdate = true;
               
               // #region agent log
               string dataJson5 = "{\"hypothesisId\":\"A,B,C,D\",\"updated\":true,\"newEntryPrice\":" + DoubleToString(newEntryPrice, 8) + "}";
               WriteDebugLog("VisualTradeLines.mqh:792", "Entry line updated", dataJson5);
               // #endregion agent log
            }
         }
         else
         {
            // For pending orders, check if user manually moved the line
            double price = ObjectGetDouble(0, m_entryLine.GetName(), OBJPROP_PRICE);
            if(MathAbs(price - currentEntryPrice) > pointValue * 0.01)
            {
               m_entryLine.UpdatePrice(price);
               needsUpdate = true;
            }
         }
      }
      
      // Update order type label when entry line moves
      if(m_entryLine != NULL && needsUpdate)
      {
         m_entryLine.UpdateOrderTypeLabel();
      }
      
      // Check for manual TP/SL line movements
      if(m_tpLine != NULL)
      {
         double price = ObjectGetDouble(0, m_tpLine.GetName(), OBJPROP_PRICE);
         if(price != m_tpLine.GetPrice())
         {
            m_tpLine.UpdatePrice(price);
            needsUpdate = true;
         }
      }
      
      if(m_slLine != NULL)
      {
         double price = ObjectGetDouble(0, m_slLine.GetName(), OBJPROP_PRICE);
         if(price != m_slLine.GetPrice())
         {
            m_slLine.UpdatePrice(price);
            needsUpdate = true;
         }
      }
      
      if(needsUpdate)
         UpdateShadedAreas();
   }
   
   //+------------------------------------------------------------------+
   //| Check if open button clicked                                   |
   //+------------------------------------------------------------------+
   bool IsOpenButtonClicked(const string& sparam)
   {
      if(!m_isActive || m_entryLine == NULL) return false;
      return (sparam == m_entryLine.GetButtonName());
   }
   
   //+------------------------------------------------------------------+
   //| Handle input box edit                                           |
   //+------------------------------------------------------------------+
   bool HandleInputEdit(string inputName, string inputText)
   {
      if(!m_isActive) return false;
      
      double referencePrice = GetEntryPrice();
      
      if(StringFind(inputName, "Entry") >= 0 && m_entryLine != NULL)
      {
         return m_entryLine.HandleInputChange(inputText, 0);
      }
      else if(StringFind(inputName, "TP") >= 0 && m_tpLine != NULL)
      {
         return m_tpLine.HandleInputChange(inputText, referencePrice);
      }
      else if(StringFind(inputName, "SL") >= 0 && m_slLine != NULL)
      {
         return m_slLine.HandleInputChange(inputText, referencePrice);
      }
      
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Get entry price                                                 |
   //+------------------------------------------------------------------+
   double GetEntryPrice()
   {
      if(m_entryLine == NULL) return 0;
      return m_entryLine.GetPrice();
   }
   
   //+------------------------------------------------------------------+
   //| Get TP price                                                    |
   //+------------------------------------------------------------------+
   double GetTPPrice()
   {
      if(m_tpLine == NULL) return 0;
      return m_tpLine.GetPrice();
   }
   
   //+------------------------------------------------------------------+
   //| Get SL price                                                    |
   //+------------------------------------------------------------------+
   double GetSLPrice()
   {
      if(m_slLine == NULL) return 0;
      return m_slLine.GetPrice();
   }
   
   //+------------------------------------------------------------------+
   //| Get TP in points                                                |
   //+------------------------------------------------------------------+
   int GetTPPoints()
   {
      if(m_entryLine == NULL || m_tpLine == NULL) return 0;
      return m_tpLine.GetPriceInPoints(m_entryLine.GetPrice());
   }
   
   //+------------------------------------------------------------------+
   //| Get SL in points                                                |
   //+------------------------------------------------------------------+
   int GetSLPoints()
   {
      if(m_entryLine == NULL || m_slLine == NULL) return 0;
      return m_slLine.GetPriceInPoints(m_entryLine.GetPrice());
   }
   
   //+------------------------------------------------------------------+
   //| Check if buy order                                              |
   //+------------------------------------------------------------------+
   bool IsBuy() { return m_isBuy; }
   
   //+------------------------------------------------------------------+
   //| Check if active                                                |
   //+------------------------------------------------------------------+
   bool IsActive() { return m_isActive; }
   
   //+------------------------------------------------------------------+
   //| Determine order type                                            |
   //+------------------------------------------------------------------+
   ENUM_ORDER_TYPE GetOrderType()
   {
      if(!m_isActive || m_entryLine == NULL) return ORDER_TYPE_BUY;
      
      double entryPrice = m_entryLine.GetPrice();
      double currentPrice = m_isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double pointValue = GetPointValue();
      
      // If entry is far from current price, it's a pending order
      if(MathAbs(entryPrice - currentPrice) > pointValue * 10)
      {
         if(m_isBuy)
            return (entryPrice > currentPrice) ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_BUY_STOP;
         else
            return (entryPrice < currentPrice) ? ORDER_TYPE_SELL_LIMIT : ORDER_TYPE_SELL_STOP;
      }
      
      // Otherwise it's a market order
      return m_isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   }
   
   //+------------------------------------------------------------------+
   //| Delete all lines                                                |
   //+------------------------------------------------------------------+
   void DeleteAll()
   {
      if(m_entryLine != NULL) { delete m_entryLine; m_entryLine = NULL; }
      if(m_tpLine != NULL) { delete m_tpLine; m_tpLine = NULL; }
      if(m_slLine != NULL) { delete m_slLine; m_slLine = NULL; }
      
      if(ObjectFind(0, m_tpAreaName) >= 0)
         ObjectDelete(0, m_tpAreaName);
      if(ObjectFind(0, m_slAreaName) >= 0)
         ObjectDelete(0, m_slAreaName);
      
      m_isActive = false;
      ChartRedraw();
   }
};

//+------------------------------------------------------------------+