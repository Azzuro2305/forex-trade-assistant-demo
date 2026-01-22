//+------------------------------------------------------------------+
//| VisualTradeLines.mqh                                             |
//| Composite UI implementation based on ChatGPT design              |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../../Config/Inputs.mqh"
#include "../../Core/SymbolUtils.mqh"
#include "../../Core/MathRisk.mqh"
#include "../../Utils/Helpers.mqh"
#include <Canvas\Canvas.mqh>
#include "VisualTradeHelpers.mqh"
#include "LineInfoComposite.mqh"
#include "EntryComposite.mqh"

//+------------------------------------------------------------------+
//| Visual Trade Lines Manager                                       |
//| Wrapper class that integrates composite UI with existing system |
//+------------------------------------------------------------------+
class CVisualTradeLines
{
private:
   CLineInfoComposite* m_tpComposite;
   CLineInfoComposite* m_slComposite;
   CEntryComposite*    m_entryComposite;
   
   string            m_tpAreaName;
   string            m_slAreaName;
   bool              m_isActive;
   bool              m_isBuy;
   bool              m_isEntryManuallyDragged;
   string            m_baseName;
   long              m_chart;
   
   // Canvas objects for transparent shaded areas
   CCanvas*          m_tpCanvas;
   CCanvas*          m_slCanvas;
   
   // Shaded area colors (RGB only, alpha handled by canvas)
   int               m_tpAreaRed;
   int               m_tpAreaGreen;
   int               m_tpAreaBlue;
   int               m_tpAreaAlpha;   // 0-255 opacity
   int               m_slAreaRed;
   int               m_slAreaGreen;
   int               m_slAreaBlue;
   int               m_slAreaAlpha;   // 0-255 opacity
   
   // Track last prices to prevent blinking
   double            m_lastEntryPrice;
   double            m_lastTPPrice;
   double            m_lastSLPrice;
   int               m_lastChartWidth;
   double            m_lastPriceMin;  // Track visible price range for zoom/pan detection
   double            m_lastPriceMax;

   //+------------------------------------------------------------------+
   //| Create transparent shaded area using CCanvas                    |
   //+------------------------------------------------------------------+
   void CreateTransparentShade(CCanvas* &canvas, string name, double priceLow, double priceHigh, 
                                 int red, int green, int blue, int alpha)
   {
      int chartWidth  = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
      
      // Match composite panel width and align to right edge (same X position as composite)
      // So shaded area should start at the same X position as composite panels
      int compositeX = CalculateCompositePanelX(chartWidth);
      int widthPx = COMPOSITE_PANEL_WIDTH; // Match composite width
      int x = compositeX; // Align with composite panel
      
      int y1, y2, tempX;
      ChartTimePriceToXY(0, 0, TimeCurrent(), priceLow, tempX, y1);
      ChartTimePriceToXY(0, 0, TimeCurrent(), priceHigh, tempX, y2);
      
      if(y1 > y2)
      {
         int tmp = y1;
         y1 = y2;
         y2 = tmp;
      }
      
      int height = y2 - y1;
      if(height <= 0)
      {
         // If height is invalid, delete canvas if it exists
         if(canvas != NULL)
         {
            if(ObjectFind(0, name) >= 0)
               ObjectDelete(0, name);
            delete canvas;
            canvas = NULL;
         }
         return;
      }
      
      // Delete existing object if any
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      
      // Create or recreate canvas
      if(canvas == NULL)
         canvas = new CCanvas();
      
      // Create bitmap label with ARGB format for transparency
      if(!canvas.CreateBitmapLabel(name, x, y1, widthPx, height, COLOR_FORMAT_ARGB_NORMALIZE))
      {
         delete canvas;
         canvas = NULL;
         return;
      }
      
      // Set z-order to be behind UI elements (lower z-order = behind)
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      
      // Create color with alpha using ColorToARGB
      uint transparentColor = ColorToARGB((color)((red << 16) | (green << 8) | blue), (uchar)alpha);
      
      // Fill the entire canvas with transparent color
      canvas.Erase(transparentColor);
      canvas.Update();
   }
   
   void CreateShadedAreas()
   {
      if(!m_isActive) return;
      
      m_tpAreaName = m_baseName + "_TPArea";
      m_slAreaName = m_baseName + "_SLArea";
      
      UpdateShadedAreas();
   }

   void UpdateShadedAreas(bool forceUpdate = false)
   {
      if(!m_isActive || m_entryComposite == NULL || m_tpComposite == NULL || m_slComposite == NULL)
         return;
   
      double entry = m_entryComposite.Price();
      double tp    = m_tpComposite.Price();
      double sl    = m_slComposite.Price();
      double pointValue = GetPointValue(_Symbol);
      
      // Get current chart state (needed for both force and normal updates)
      int currentChartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      double currentPriceMin = ChartGetDouble(0, CHART_PRICE_MIN);
      double currentPriceMax = ChartGetDouble(0, CHART_PRICE_MAX);
      
      // If forced update (from CHARTEVENT_CHART_CHANGE), skip all checks
      if(!forceUpdate)
      {
         // Check if prices changed significantly (prevent blinking)
         bool entryChanged = (MathAbs(entry - m_lastEntryPrice) > pointValue);
         bool tpChanged = (MathAbs(tp - m_lastTPPrice) > pointValue);
         bool slChanged = (MathAbs(sl - m_lastSLPrice) > pointValue);
         
         bool chartResized = (currentChartWidth != m_lastChartWidth);
         
         // Check if visible price range changed (zoom/pan detection)
         bool priceRangeChanged = (MathAbs(currentPriceMin - m_lastPriceMin) > pointValue * 0.1) ||
                                  (MathAbs(currentPriceMax - m_lastPriceMax) > pointValue * 0.1);
         
         // Update if prices changed, chart resized, OR visible price range changed (zoom/pan)
         if(!entryChanged && !tpChanged && !slChanged && !chartResized && !priceRangeChanged)
            return;
      }
      
      // Update last prices and chart state
      m_lastEntryPrice = entry;
      m_lastTPPrice = tp;
      m_lastSLPrice = sl;
      m_lastChartWidth = currentChartWidth;
      m_lastPriceMin = currentPriceMin;
      m_lastPriceMax = currentPriceMax;
   
      // Delete existing canvas objects
      if(m_tpCanvas != NULL)
      {
         if(ObjectFind(0, m_tpAreaName) >= 0)
            ObjectDelete(0, m_tpAreaName);
         delete m_tpCanvas;
         m_tpCanvas = NULL;
      }
      
      if(m_slCanvas != NULL)
      {
         if(ObjectFind(0, m_slAreaName) >= 0)
            ObjectDelete(0, m_slAreaName);
         delete m_slCanvas;
         m_slCanvas = NULL;
      }
   
      // Create TP area with transparency (GREEN)
      if(m_isBuy && tp > entry)
         CreateTransparentShade(m_tpCanvas, m_tpAreaName, entry, tp, m_tpAreaRed, m_tpAreaGreen, m_tpAreaBlue, m_tpAreaAlpha);
      else if(!m_isBuy && tp < entry)
         CreateTransparentShade(m_tpCanvas, m_tpAreaName, tp, entry, m_tpAreaRed, m_tpAreaGreen, m_tpAreaBlue, m_tpAreaAlpha);
      
      // Create SL area with transparency (RED - between entry and SL)
      if(m_isBuy && sl < entry)
         CreateTransparentShade(m_slCanvas, m_slAreaName, sl, entry, m_slAreaRed, m_slAreaGreen, m_slAreaBlue, m_slAreaAlpha);
      else if(!m_isBuy && sl > entry)
         CreateTransparentShade(m_slCanvas, m_slAreaName, entry, sl, m_slAreaRed, m_slAreaGreen, m_slAreaBlue, m_slAreaAlpha);
      
      ChartRedraw();
   }
   
public:
   CVisualTradeLines()
   {
      m_tpComposite = NULL;
      m_slComposite = NULL;
      m_entryComposite = NULL;
      m_isActive = false;
      m_isBuy = true;
      m_baseName = "VTL_" + IntegerToString(GetTickCount());
      m_chart = ChartID();
      m_isEntryManuallyDragged = false;
      
      // Initialize canvas objects
      m_tpCanvas = NULL;
      m_slCanvas = NULL;
      
      // Initialize shaded area colors with low opacity
      // Alpha values: 40 = ~16% opacity, 60 = ~24% opacity, 80 = ~31% opacity, 100 = ~39% opacity
      m_tpAreaRed = 0;
      m_tpAreaGreen = 180;
      m_tpAreaBlue = 0;
      m_tpAreaAlpha = 60;   // ~24% opacity
      
       m_slAreaRed = 255;   // Bright red
       m_slAreaGreen = 0;
       m_slAreaBlue = 0;
       m_slAreaAlpha = 40;   // Low opacity (~16%)
      
      // Initialize last prices for blinking prevention
      m_lastEntryPrice = 0;
      m_lastTPPrice = 0;
      m_lastSLPrice = 0;
      m_lastChartWidth = 0;
      m_lastPriceMin = 0;
      m_lastPriceMax = 0;
   }
   
   ~CVisualTradeLines()
   {
      DeleteAll();
   }
   
   bool CreateBuySetup(double entryPrice = 0, double tpPrice = 0, double slPrice = 0)
   {
      if(m_isActive) DeleteAll();
      
      if(entryPrice == 0) entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(InpUseFixedRR && InpFixedRR > 0)
      {
         int slPoints = InpStopLoss;
         int tpPoints = (int)MathRound(slPoints * InpFixedRR);
         if(tpPrice == 0) tpPrice = entryPrice + PointsToPrice(tpPoints);
         if(slPrice == 0) slPrice = entryPrice - PointsToPrice(slPoints);
      }
      else
      {
         if(tpPrice == 0) tpPrice = NormalizePrice(entryPrice + 30.00);
         if(slPrice == 0) slPrice = NormalizePrice(entryPrice - 10.00);
      }
      
      m_isBuy = true;
      m_isActive = true;
      m_isEntryManuallyDragged = false;
      
      m_entryComposite = new CEntryComposite();
      m_tpComposite = new CLineInfoComposite();
      m_slComposite = new CLineInfoComposite();
      
      if(!m_entryComposite.Create(m_chart, 0, m_baseName + "_ENTRY", entryPrice, m_isBuy) ||
         !m_tpComposite.Create(m_chart, 0, m_baseName + "_TP", clrLime, (color)0x003000, "Tp", tpPrice, m_isBuy) ||
         !m_slComposite.Create(m_chart, 0, m_baseName + "_SL", clrRed, (color)0x300000, "Sl", slPrice, m_isBuy))
      {
         DeleteAll();
         return false;
      }
      
      double currentMarketPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      m_entryComposite.SetPrice(currentMarketPrice);
      
      // Update order type label (should be "Buy" initially for market order)
      UpdateEntryOrderTypeLabel();
      
      // Initialize TP and SL labels
      UpdateTPLabels();
      UpdateSLLabels();
      
      CreateShadedAreas();
      EnsureLinesSelectable();
      ChartRedraw();
      
      return true;
   }
   
   bool CreateSellSetup(double entryPrice = 0, double tpPrice = 0, double slPrice = 0)
   {
      if(m_isActive) DeleteAll();
      
      if(entryPrice == 0) entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      if(InpUseFixedRR && InpFixedRR > 0)
      {
         int slPoints = InpStopLoss;
         int tpPoints = (int)MathRound(slPoints * InpFixedRR);
         if(tpPrice == 0) tpPrice = entryPrice - PointsToPrice(tpPoints);
         if(slPrice == 0) slPrice = entryPrice + PointsToPrice(slPoints);
      }
      else
      {
         if(tpPrice == 0) tpPrice = NormalizePrice(entryPrice - 1000.00);
         if(slPrice == 0) slPrice = NormalizePrice(entryPrice + 500.00);
      }
      
      m_isBuy = false;
      m_isActive = true;
      m_isEntryManuallyDragged = false;
      
      m_entryComposite = new CEntryComposite();
      m_tpComposite = new CLineInfoComposite();
      m_slComposite = new CLineInfoComposite();
      
      if(!m_entryComposite.Create(m_chart, 0, m_baseName + "_ENTRY", entryPrice, m_isBuy) ||
         !m_tpComposite.Create(m_chart, 0, m_baseName + "_TP", clrLime, (color)0x003000, "Tp", tpPrice, m_isBuy) ||
         !m_slComposite.Create(m_chart, 0, m_baseName + "_SL", clrRed, (color)0x300000, "Sl", slPrice, m_isBuy))
      {
         DeleteAll();
         return false;
      }
      
      double currentMarketPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      m_entryComposite.SetPrice(currentMarketPrice);
      
      // Update order type label (should be "Sell" initially for market order)
      UpdateEntryOrderTypeLabel();
      
      // Initialize TP and SL labels
      UpdateTPLabels();
      UpdateSLLabels();
      
      CreateShadedAreas();
      EnsureLinesSelectable();
      ChartRedraw();
      
      return true;
   }
   
   void Update()
   {
      if(!m_isActive) return;
      
      if(m_entryComposite != NULL)
      {
         // CRITICAL: Check if manually dragged FIRST - if so, skip all market price logic
         // Check the flag first (set by OnChartEvent when user drags)
         if(m_isEntryManuallyDragged || m_entryComposite.WasManuallyDragged())
         {
            // User has manually dragged - just validate price is within bounds and update stored price
            double objectPrice = ObjectGetDouble(0, m_entryComposite.LineName(), OBJPROP_PRICE);
            double validatedPrice = ValidateEntryPrice(objectPrice);
            if(MathAbs(validatedPrice - objectPrice) > 0.00001)
            {
               ObjectSetDouble(0, m_entryComposite.LineName(), OBJPROP_PRICE, validatedPrice);
               ChartRedraw(0);
               objectPrice = validatedPrice;
            }
            // Update stored price to match object price
            m_entryComposite.SetPrice(objectPrice);
            // Update order type label based on position
            UpdateEntryOrderTypeLabel();
            // Skip market price update - continue to TP/SL updates below
         }
         else
         {
            // Entry line is NOT manually dragged - keep it at market price
            double objectPrice = ObjectGetDouble(0, m_entryComposite.LineName(), OBJPROP_PRICE);
            double currentMarketPrice = m_isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double pointValue = GetPointValue(_Symbol);
            
            // Validate entry price is within TP/SL bounds
            double validatedPrice = ValidateEntryPrice(objectPrice);
            if(MathAbs(validatedPrice - objectPrice) > 0.00001)
            {
               ObjectSetDouble(0, m_entryComposite.LineName(), OBJPROP_PRICE, validatedPrice);
               ChartRedraw(0);
               objectPrice = validatedPrice;
            }
            
            // Detect if user is dragging by checking if line price differs from market
            double marketDiff = MathAbs(objectPrice - currentMarketPrice);
            
            // If price is away from market, user is dragging
            if(marketDiff > pointValue * 0.5)
            {
               // User is dragging - mark as manually dragged
               m_isEntryManuallyDragged = true;
               m_entryComposite.SetManuallyDragged(true);
               // Update stored price to match object price
               m_entryComposite.SetPrice(objectPrice);
               // Update order type label based on position
               UpdateEntryOrderTypeLabel();
               // Skip market price update
            }
            // If still at market price (or very close), update to current market price
            else
            {
               // If line is back at market, reset manually dragged flag
               if(m_isEntryManuallyDragged || m_entryComposite.WasManuallyDragged())
               {
                  m_isEntryManuallyDragged = false;
                  m_entryComposite.SetManuallyDragged(false);
               }
               
               double newEntryPrice = NormalizePrice(currentMarketPrice);
               double priceChange = MathAbs(newEntryPrice - objectPrice);
               
               // Always update to market price if not manually dragged (use very small threshold)
               if(priceChange >= pointValue * 0.01)
               {
                  double tpOffset = 0;
                  double slOffset = 0;
                  
                  if(m_tpComposite != NULL && !m_tpComposite.IsPinned())
                     tpOffset = m_tpComposite.Price() - objectPrice;
                  
                  if(m_slComposite != NULL && !m_slComposite.IsPinned())
                     slOffset = m_slComposite.Price() - objectPrice;
                  
                  ObjectSetDouble(0, m_entryComposite.LineName(), OBJPROP_PRICE, newEntryPrice);
                  m_entryComposite.SetPrice(newEntryPrice);
                  
                  if(m_tpComposite != NULL && !m_tpComposite.IsPinned())
                     m_tpComposite.SetPrice(NormalizePrice(newEntryPrice + tpOffset));
                  
                  if(m_slComposite != NULL && !m_slComposite.IsPinned())
                     m_slComposite.SetPrice(NormalizePrice(newEntryPrice + slOffset));
                  
                  // Update order type label (should be "Buy" or "Sell" for market orders)
                  UpdateEntryOrderTypeLabel();
                  ChartRedraw(0);
               }
            }
         }
      }
      
      if(m_tpComposite != NULL && !m_tpComposite.IsPinned())
      {
         double price = ObjectGetDouble(0, m_tpComposite.LineName(), OBJPROP_PRICE);
         if(price != m_tpComposite.Price())
         {
            m_tpComposite.SetPrice(price);
            m_tpComposite.UpdateLayout();
            // Update TP labels when price changes
            UpdateTPLabels();
         }
      }
      
      if(m_slComposite != NULL && !m_slComposite.IsPinned())
      {
         double price = ObjectGetDouble(0, m_slComposite.LineName(), OBJPROP_PRICE);
         if(price != m_slComposite.Price())
         {
            m_slComposite.SetPrice(price);
            m_slComposite.UpdateLayout();
            // Update SL labels when price changes
            UpdateSLLabels();
         }
      }
      
      UpdateShadedAreas();
      
      // Ensure lines remain selectable and selected (unless pinned)
      EnsureLinesSelectable();
   }
   
   void EnsureLinesSelectable()
   {
      if(!m_isActive) return;
      
      // Ensure all lines are selectable AND pre-selected for immediate dragging
      if(m_entryComposite != NULL)
      {
         string entryName = m_entryComposite.LineName();
         if(ObjectFind(0, entryName) >= 0)
         {
            ObjectSetInteger(0, entryName, OBJPROP_SELECTABLE, true);
            ObjectSetInteger(0, entryName, OBJPROP_SELECTED, true);
         }
      }
      
      if(m_tpComposite != NULL)
      {
         string tpName = m_tpComposite.LineName();
         if(ObjectFind(0, tpName) >= 0)
         {
            bool isPinned = m_tpComposite.IsPinned();
            ObjectSetInteger(0, tpName, OBJPROP_SELECTABLE, !isPinned);
            ObjectSetInteger(0, tpName, OBJPROP_SELECTED, !isPinned);
         }
      }
      
      if(m_slComposite != NULL)
      {
         string slName = m_slComposite.LineName();
         if(ObjectFind(0, slName) >= 0)
         {
            bool isPinned = m_slComposite.IsPinned();
            ObjectSetInteger(0, slName, OBJPROP_SELECTABLE, !isPinned);
            ObjectSetInteger(0, slName, OBJPROP_SELECTED, !isPinned);
         }
      }
   }
   
   bool HandleInputEdit(string inputName, string inputText)
   {
      if(!m_isActive) return false;
      
      double referencePrice = GetEntryPrice();
      bool updated = false;
      
      if(StringFind(inputName, "ENTRY") >= 0 && m_entryComposite != NULL)
      {
         if(StringGetCharacter(inputText, 0) == 'p' || StringGetCharacter(inputText, 0) == 'P')
         {
            int points = (int)StringToInteger(StringSubstr(inputText, 1));
            double newPrice = referencePrice + (points * GetPointValue(_Symbol));
            m_entryComposite.SetPrice(newPrice);
            updated = true;
         }
         else
         {
            double newPrice = StringToDouble(inputText);
            if(newPrice > 0)
            {
               m_entryComposite.SetPrice(newPrice);
               updated = true;
            }
         }
      }
      else if(StringFind(inputName, "TP") >= 0 && m_tpComposite != NULL)
      {
         if(StringGetCharacter(inputText, 0) == 'p' || StringGetCharacter(inputText, 0) == 'P')
         {
            int points = (int)StringToInteger(StringSubstr(inputText, 1));
            double newPrice = referencePrice + (points * GetPointValue(_Symbol) * (m_isBuy ? 1 : -1));
            m_tpComposite.SetPrice(newPrice);
            updated = true;
         }
         else
         {
            double newPrice = StringToDouble(inputText);
            if(newPrice > 0)
            {
               m_tpComposite.SetPrice(newPrice);
               updated = true;
            }
         }
      }
      else if(StringFind(inputName, "SL") >= 0 && m_slComposite != NULL)
      {
         if(StringGetCharacter(inputText, 0) == 'p' || StringGetCharacter(inputText, 0) == 'P')
         {
            int points = (int)StringToInteger(StringSubstr(inputText, 1));
            double newPrice = referencePrice - (points * GetPointValue(_Symbol) * (m_isBuy ? 1 : -1));
            m_slComposite.SetPrice(newPrice);
            updated = true;
         }
         else
         {
            double newPrice = StringToDouble(inputText);
            if(newPrice > 0)
            {
               m_slComposite.SetPrice(newPrice);
               updated = true;
            }
         }
      }
      
      if(updated)
      {
         UpdateShadedAreas();
         ChartRedraw();
      }
      
      return updated;
   }
   
   double ValidateEntryPrice(double entryPrice)
   {
      if(!m_isActive || m_entryComposite == NULL) return entryPrice;
      
      double tpPrice = GetTPPrice();
      double slPrice = GetSLPrice();
      
      if(tpPrice == 0 || slPrice == 0) return entryPrice;
      
      if(m_isBuy)
      {
         if(entryPrice < slPrice) return slPrice;
         if(entryPrice > tpPrice) return tpPrice;
      }
      else
      {
         if(entryPrice < tpPrice) return tpPrice;
         if(entryPrice > slPrice) return slPrice;
      }
      
      return entryPrice;
   }
   
   bool HandleEntryLineDrag(string objectName)
   {
      if(!m_isActive || m_entryComposite == NULL) return false;
      if(StringFind(objectName, "_ENTRY") < 0) return false;
      
      double currentPrice = ObjectGetDouble(0, objectName, OBJPROP_PRICE);
      double validatedPrice = ValidateEntryPrice(currentPrice);
      
      if(MathAbs(validatedPrice - currentPrice) > 0.00001)
      {
         ObjectSetDouble(0, objectName, OBJPROP_PRICE, validatedPrice);
         ChartRedraw(0);
         return true;
      }
      
      return false;
   }
   
   bool IsOpenButtonClicked(const string& sparam)
   {
      if(!m_isActive || m_entryComposite == NULL) return false;
      return (sparam == m_entryComposite.OpenBtnName());
   }
   
   bool IsPinButtonClicked(const string& sparam)
   {
      if(!m_isActive) return false;
      if(m_tpComposite != NULL && sparam == m_tpComposite.PinBtnName())
         return true;
      if(m_slComposite != NULL && sparam == m_slComposite.PinBtnName())
         return true;
      return false;
   }
   
   void TogglePinForLine(const string& sparam)
   {
      if(!m_isActive) return;
      if(m_tpComposite != NULL && sparam == m_tpComposite.PinBtnName())
      {
         m_tpComposite.SetPinned(!m_tpComposite.IsPinned());
         ObjectSetInteger(0, m_tpComposite.LineName(), OBJPROP_SELECTABLE, !m_tpComposite.IsPinned());
         ObjectSetInteger(0, m_tpComposite.LineName(), OBJPROP_SELECTED, !m_tpComposite.IsPinned());
      }
      else if(m_slComposite != NULL && sparam == m_slComposite.PinBtnName())
      {
         m_slComposite.SetPinned(!m_slComposite.IsPinned());
         ObjectSetInteger(0, m_slComposite.LineName(), OBJPROP_SELECTABLE, !m_slComposite.IsPinned());
         ObjectSetInteger(0, m_slComposite.LineName(), OBJPROP_SELECTED, !m_slComposite.IsPinned());
      }
   }
   
   double GetEntryPrice()
   {
      if(m_entryComposite == NULL) return 0;
      return m_entryComposite.Price();
   }
   
   double GetTPPrice()
   {
      if(m_tpComposite == NULL) return 0;
      return m_tpComposite.Price();
   }
   
   double GetSLPrice()
   {
      if(m_slComposite == NULL) return 0;
      return m_slComposite.Price();
   }
   
   int GetTPPoints()
   {
      if(m_entryComposite == NULL || m_tpComposite == NULL) return 0;
      return (int)MathRound(MathAbs(m_tpComposite.Price() - m_entryComposite.Price()) / GetPointValue(_Symbol));
   }
   
   int GetSLPoints()
   {
      if(m_entryComposite == NULL || m_slComposite == NULL) return 0;
      return (int)MathRound(MathAbs(m_slComposite.Price() - m_entryComposite.Price()) / GetPointValue(_Symbol));
   }
   
   bool IsBuy() { return m_isBuy; }
   bool IsActive() { return m_isActive; }
   
   bool UpdateTPPrice(double tpPrice)
   {
      if(!m_isActive || m_tpComposite == NULL) return false;
      m_tpComposite.SetPrice(tpPrice);
      UpdateShadedAreas();
      return true;
   }
   
   bool UpdateSLPrice(double slPrice)
   {
      if(!m_isActive || m_slComposite == NULL) return false;
      m_slComposite.SetPrice(slPrice);
      UpdateShadedAreas();
      return true;
   }
   
   void RefreshShadedAreas()
   {
      UpdateShadedAreas();
   }
   
   string GetBaseName() { return m_baseName; }
   
   void UpdateSLLabelRisk(double riskAmount)
   {
      if(!m_isActive || m_slComposite == NULL || m_entryComposite == NULL) return;
      
      int slPoints = GetSLPoints();
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskPercent = balance > 0 ? (riskAmount / balance) * 100.0 : 0;
      
      string labelText = IntegerToString(slPoints) + " " + 
                        DoubleToString(riskAmount, 2) + " USD " + 
                        DoubleToString(riskPercent, 2) + "%";
      
      m_slComposite.SetPointsText(labelText);
   }
   
   void UpdateTPLabelProfit(double profitAmount)
   {
      if(!m_isActive || m_tpComposite == NULL || m_entryComposite == NULL) return;
      
      int tpPoints = GetTPPoints();
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double profitPercent = balance > 0 ? (profitAmount / balance) * 100.0 : 0;
      
      string labelText = IntegerToString(tpPoints) + " " + 
                        DoubleToString(profitAmount, 2) + " USD " + 
                        DoubleToString(profitPercent, 2) + "%";
      
      m_tpComposite.SetPointsText(labelText);
   }
   
   void UpdateEntryLabel(string labelText)
   {
      // Update lot size label in entry composite
      if(m_entryComposite != NULL)
         m_entryComposite.SetLotSizeText(labelText);
   }
   
   // Update TP labels using risk manager (called internally)
   void UpdateTPLabels()
   {
      if(!m_isActive || m_tpComposite == NULL || m_entryComposite == NULL) return;
      
      int tpPoints = GetTPPoints();
      int slPoints = GetSLPoints();
      if(tpPoints <= 0 || slPoints <= 0) return;
      
      // Calculate lot size and profit (use default risk if no risk manager available)
      double lotSize = 0.01; // Default
      double profitAmount = ::CalculateProfitAmount(lotSize, tpPoints);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double profitPercent = balance > 0 ? (profitAmount / balance) * 100.0 : 0;
      
      string labelText = IntegerToString(tpPoints) + " " + 
                        DoubleToString(profitAmount, 2) + " USD " + 
                        DoubleToString(profitPercent, 2) + "%";
      
      m_tpComposite.SetPointsText(labelText);
   }
   
   // Update SL labels using risk manager (called internally)
   void UpdateSLLabels()
   {
      if(!m_isActive || m_slComposite == NULL || m_entryComposite == NULL) return;
      
      int slPoints = GetSLPoints();
      if(slPoints <= 0) return;
      
      // Calculate lot size and risk (use default risk if no risk manager available)
      double lotSize = 0.01; // Default
      double riskAmount = ::CalculateRiskAmount(lotSize, slPoints);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskPercent = balance > 0 ? (riskAmount / balance) * 100.0 : 0;
      
      string labelText = IntegerToString(slPoints) + " " + 
                        DoubleToString(riskAmount, 2) + " USD " + 
                        DoubleToString(riskPercent, 2) + "%";
      
      m_slComposite.SetPointsText(labelText);
   }
   
   void UpdateEntryOrderTypeLabel()
   {
      // Update entry label based on order type
      if(!m_isActive || m_entryComposite == NULL) return;
      
      ENUM_ORDER_TYPE orderType = GetOrderType();
      string labelText = "";
      
      switch(orderType)
      {
         case ORDER_TYPE_BUY:
            labelText = "Buy";
            break;
         case ORDER_TYPE_BUY_LIMIT:
            labelText = "Buy Limit";
            break;
         case ORDER_TYPE_BUY_STOP:
            labelText = "Buy Stop";
            break;
         case ORDER_TYPE_SELL:
            labelText = "Sell";
            break;
         case ORDER_TYPE_SELL_LIMIT:
            labelText = "Sell Limit";
            break;
         case ORDER_TYPE_SELL_STOP:
            labelText = "Sell Stop";
            break;
         default:
            labelText = m_isBuy ? "Buy" : "Sell";
            break;
      }
      
      m_entryComposite.SetSideLabel(labelText);
   }
   
   ENUM_ORDER_TYPE GetOrderType()
   {
      if(!m_isActive || m_entryComposite == NULL) 
         return ORDER_TYPE_BUY;
      
      double entryPrice = m_entryComposite.Price();
      double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double currentPrice = m_isBuy ? askPrice : bidPrice;
      double pointValue = GetPointValue(_Symbol);
      
      // If entry line is NOT manually dragged, it's always at market price = market order
      if(!m_isEntryManuallyDragged && !m_entryComposite.WasManuallyDragged())
         return m_isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      
      // If entry is close to market price (within 10 points), it's a market order
      bool isMarketOrder = (MathAbs(entryPrice - currentPrice) <= pointValue * 10);
      
      if(isMarketOrder)
         return m_isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      else
      {
         // Entry is away from market - determine if limit or stop order
         if(m_isBuy)
         {
            // For BUY: entry below ask = LIMIT, entry above ask = STOP
            if(entryPrice < askPrice)
               return ORDER_TYPE_BUY_LIMIT;
            else
               return ORDER_TYPE_BUY_STOP;
         }
         else
         {
            // For SELL: entry above bid = LIMIT, entry below bid = STOP
            if(entryPrice > bidPrice)
               return ORDER_TYPE_SELL_LIMIT;
            else
               return ORDER_TYPE_SELL_STOP;
         }
      }
   }
   
   void DeleteAll()
   {
      if(m_tpComposite != NULL) { delete m_tpComposite; m_tpComposite = NULL; }
      if(m_slComposite != NULL) { delete m_slComposite; m_slComposite = NULL; }
      if(m_entryComposite != NULL) { delete m_entryComposite; m_entryComposite = NULL; }
      
      // Delete canvas objects
      if(m_tpCanvas != NULL)
      {
         if(ObjectFind(0, m_tpAreaName) >= 0)
            ObjectDelete(0, m_tpAreaName);
         delete m_tpCanvas;
         m_tpCanvas = NULL;
      }
      
      if(m_slCanvas != NULL)
      {
         if(ObjectFind(0, m_slAreaName) >= 0)
            ObjectDelete(0, m_slAreaName);
         delete m_slCanvas;
         m_slCanvas = NULL;
      }
      
      m_isActive = false;
      ChartRedraw();
   }
   
   // Forward chart events to composite classes
   bool OnChartEvent(const int id, const string &sparam)
   {
      if(!m_isActive) return false;
      
      bool handled = false;
      
      // Handle chart resize, zoom, or pan - CRITICAL: Update everything immediately
      if(id == CHARTEVENT_CHART_CHANGE)
      {
         // Force update all composite layouts immediately (zoom/pan changes Y positions)
         if(m_entryComposite != NULL)
            m_entryComposite.UpdateLayout();
         if(m_tpComposite != NULL)
            m_tpComposite.UpdateLayout();
         if(m_slComposite != NULL)
            m_slComposite.UpdateLayout();
         
         // Force update shaded areas immediately (bypass all checks)
         UpdateShadedAreas(true); // true = force update
         ChartRedraw();
         return false; // Don't mark as handled, let other handlers process
      }
      
      // Handle line drag events - update composite UI immediately for smooth following
      if(id == CHARTEVENT_OBJECT_DRAG || id == CHARTEVENT_OBJECT_CHANGE)
      {
         if(m_entryComposite != NULL && sparam == m_entryComposite.LineName())
         {
            // Get current price from line DURING drag (before mouse release)
            double price = ObjectGetDouble(0, sparam, OBJPROP_PRICE);
            // Mark as manually dragged when user drags
            m_entryComposite.SetManuallyDragged(true);
            m_isEntryManuallyDragged = true;
            // Directly update layout immediately during drag (faster than SetPrice)
            // Update edit box text first
            ObjectSetString(0, m_entryComposite.EditName(), OBJPROP_TEXT, PriceToStr(price));
            // Then update layout position immediately
            m_entryComposite.UpdateLayout();
            // Update order type label based on new position
            UpdateEntryOrderTypeLabel();
            UpdateShadedAreas();
            ChartRedraw(0); // Force immediate redraw
            handled = true;
         }
         else if(m_tpComposite != NULL && sparam == m_tpComposite.LineName())
         {
            // Get current price from line DURING drag (before mouse release)
            double price = ObjectGetDouble(0, sparam, OBJPROP_PRICE);
            // Directly update layout immediately during drag (faster than SetPrice)
            // Update edit box text first
            ObjectSetString(0, m_tpComposite.EditName(), OBJPROP_TEXT, PriceToStr(price));
            // Then update layout position immediately
            m_tpComposite.UpdateLayout();
            // Update TP labels (points, USD, percentage)
            UpdateTPLabels();
            UpdateShadedAreas();
            ChartRedraw(0); // Force immediate redraw
            handled = true;
         }
         else if(m_slComposite != NULL && sparam == m_slComposite.LineName())
         {
            // Get current price from line DURING drag (before mouse release)
            double price = ObjectGetDouble(0, sparam, OBJPROP_PRICE);
            // Directly update layout immediately during drag (faster than SetPrice)
            // Update edit box text first
            ObjectSetString(0, m_slComposite.EditName(), OBJPROP_TEXT, PriceToStr(price));
            // Then update layout position immediately
            m_slComposite.UpdateLayout();
            // Update SL labels (points, USD, percentage)
            UpdateSLLabels();
            UpdateShadedAreas();
            ChartRedraw(0); // Force immediate redraw
            handled = true;
         }
      }
      
      // Forward other events to composites
      if(m_entryComposite != NULL)
         handled = m_entryComposite.OnChartEvent(id, sparam) || handled;
      
      if(m_tpComposite != NULL)
         handled = m_tpComposite.OnChartEvent(id, sparam) || handled;
      
      if(m_slComposite != NULL)
         handled = m_slComposite.OnChartEvent(id, sparam) || handled;
      
      if(handled)
      {
         UpdateShadedAreas();
         ChartRedraw();
      }
      
      // Always ensure lines remain selectable after any event (unless pinned)
      EnsureLinesSelectable();
      
      return handled;
   }
};

//+------------------------------------------------------------------+
