//+------------------------------------------------------------------+
//| TradingPanel.mqh                                                 |
//| Control panel GUI for visual trading                            |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"
#include "../Core/Logger.mqh"

//+------------------------------------------------------------------+
//| Risk calculation mode                                            |
//+------------------------------------------------------------------+
enum ENUM_RISK_MODE
{
   RISK_MODE_CURRENCY = 0,  // Risk in Currency
   RISK_MODE_PERCENT  = 1,  // Risk in Percentage
   RISK_MODE_FIXED    = 2   // Fixed Volume
};

//+------------------------------------------------------------------+
//| Trading Panel class                                              |
//+------------------------------------------------------------------+
class CTradingPanel
{
private:
   string   m_panelName;
   int      m_x;
   int      m_y;
   int      m_width;
   int      m_height;
   bool     m_visible;
   bool     m_enableUI;
   
   // Risk mode
   ENUM_RISK_MODE m_riskMode;
   double   m_riskCurrency;
   double   m_riskPercent;
   double   m_fixedLotSize;
   
   // Control IDs
   string   m_btnBuyName;
   string   m_btnSellName;
   string   m_btnCloseName;
   string   m_btnClearName;
   string   m_btnExecuteName;
   string   m_radioCurrencyName;
   string   m_radioPercentName;
   string   m_radioFixedName;
   string   m_editRiskName;
   string   m_labelLotName;
   string   m_labelRiskName;
   string   m_labelBalanceName;
   string   m_labelEquityName;
   string   m_labelProfitName;
   string   m_dragHandleName;
   string   m_checkFixedRRName;
   string   m_editFixedRRName;
   bool     m_isDragging;
   int      m_dragStartX;
   int      m_dragStartY;
   
   CLogger* m_logger;
   
public:
   CTradingPanel(int x = 20, int y = 50, CLogger* logger = NULL)
   {
      m_x = x;
      m_y = y;
      m_width = 250;
      m_height = 400; // Increased for better spacing
      m_visible = true;
      m_enableUI = InpEnableUI;  // Use EnableUI flag
      m_panelName = "TradingPanel_" + IntegerToString(GetTickCount());
      
      m_riskMode = RISK_MODE_PERCENT;
      m_riskCurrency = 10.0;
      m_riskPercent = 2.0;
      m_fixedLotSize = 0.01;
      
      m_btnBuyName = m_panelName + "_BtnBuy";
      m_btnSellName = m_panelName + "_BtnSell";
      m_btnCloseName = m_panelName + "_BtnClose";
      m_btnClearName = m_panelName + "_BtnClear";
      m_btnExecuteName = m_panelName + "_BtnExecute";
      m_radioCurrencyName = m_panelName + "_RadioCurrency";
      m_radioPercentName = m_panelName + "_RadioPercent";
      m_radioFixedName = m_panelName + "_RadioFixed";
      m_editRiskName = m_panelName + "_EditRisk";
      m_labelLotName = m_panelName + "_LabelLot";
      m_labelRiskName = m_panelName + "_LabelRisk";
      m_labelBalanceName = m_panelName + "_LabelBalance";
      m_labelEquityName = m_panelName + "_LabelEquity";
      m_labelProfitName = m_panelName + "_LabelProfit";
      m_dragHandleName = m_panelName + "_DragHandle";
      m_checkFixedRRName = m_panelName + "_CheckFixedRR";
      m_editFixedRRName = m_panelName + "_EditFixedRR";
      m_isDragging = false;
      m_dragStartX = 0;
      m_dragStartY = 0;
      
      m_logger = logger;
   }
   
   ~CTradingPanel()
   {
      DeleteAll();
   }
   
   //+------------------------------------------------------------------+
   //| Create panel                                                    |
   //+------------------------------------------------------------------+
   bool Create()
   {
      if(!m_enableUI) return true; // Skip GUI if UI disabled
      
      if(!CreateBackground()) return false;
      if(!CreateDragHandle()) return false;
      if(!CreateButtons()) return false;
      if(!CreateRiskControls()) return false;
      if(!CreateLabels()) return false;
      
      ChartRedraw();
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create drag handle                                              |
   //+------------------------------------------------------------------+
   bool CreateDragHandle()
   {
      if(ObjectFind(0, m_dragHandleName) >= 0)
         ObjectDelete(0, m_dragHandleName);
      
      if(!ObjectCreate(0, m_dragHandleName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_YDISTANCE, m_y);
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_XSIZE, m_width);
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_YSIZE, 25);
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_BGCOLOR, C'50,50,50');
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_BORDER_COLOR, clrSilver);
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_BACK, false);
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, m_dragHandleName, OBJPROP_SELECTED, false);
      ObjectSetString(0, m_dragHandleName, OBJPROP_TOOLTIP, "Drag to move panel");
      
      // Add title label
      string titleName = m_panelName + "_Title";
      if(ObjectFind(0, titleName) >= 0)
         ObjectDelete(0, titleName);
      
      if(ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, m_x + 5);
         ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, m_y + 5);
         ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetString(0, titleName, OBJPROP_TEXT, "Trading Panel");
         ObjectSetInteger(0, titleName, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, 10);
         ObjectSetString(0, titleName, OBJPROP_FONT, "Arial Bold");
         ObjectSetInteger(0, titleName, OBJPROP_SELECTABLE, false);
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create background                                               |
   //+------------------------------------------------------------------+
   bool CreateBackground()
   {
      string bgName = m_panelName + "_BG";
      
      if(ObjectFind(0, bgName) >= 0)
         ObjectDelete(0, bgName);
      
      if(!ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, m_y);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, m_width);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, m_height);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, C'30,30,30');
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, clrSilver);
      ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
      ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, true); // Make background draggable
      ObjectSetInteger(0, bgName, OBJPROP_SELECTED, false);
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create buttons                                                  |
   //+------------------------------------------------------------------+
   bool CreateButtons()
   {
      int yStart = m_y + 35; // Start below drag handle
      
      // Buy button
      if(!CreateButton(m_btnBuyName, m_x + 10, yStart, 110, 30, "BUY", clrDodgerBlue))
         return false;
      
      // Sell button
      if(!CreateButton(m_btnSellName, m_x + 130, yStart, 110, 30, "SELL", clrCrimson))
         return false;
      
      // Close All button
      if(!CreateButton(m_btnCloseName, m_x + 10, yStart + 40, 110, 25, "Close All", clrOrange))
         return false;
      
      // Clear Lines button
      if(!CreateButton(m_btnClearName, m_x + 130, yStart + 40, 110, 25, "Clear Lines", clrGray))
         return false;
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create single button                                            |
   //+------------------------------------------------------------------+
   bool CreateButton(string name, int x, int y, int width, int height, string text, color bgColor)
   {
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      
      if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create risk controls                                            |
   //+------------------------------------------------------------------+
   bool CreateRiskControls()
   {
      int yPos = m_y + 110; // More spacing
      
      // Risk mode label
      if(!CreateLabel(m_panelName + "_RiskModeLabel", m_x + 10, yPos, "Risk Mode:", clrWhite))
         return false;
      
      yPos += 25;
      
      // Currency radio
      if(!CreateRadioButton(m_radioCurrencyName, m_x + 10, yPos, "Currency ($)", m_riskMode == RISK_MODE_CURRENCY))
         return false;
      
      yPos += 25;
      
      // Percent radio
      if(!CreateRadioButton(m_radioPercentName, m_x + 10, yPos, "Percent (%)", m_riskMode == RISK_MODE_PERCENT))
         return false;
      
      yPos += 25;
      
      // Fixed radio
      if(!CreateRadioButton(m_radioFixedName, m_x + 10, yPos, "Fixed Lot", m_riskMode == RISK_MODE_FIXED))
         return false;
      
      yPos += 30;
      
      // Risk input label
      string riskLabel = (m_riskMode == RISK_MODE_CURRENCY) ? "Risk ($):" : 
                        (m_riskMode == RISK_MODE_PERCENT) ? "Risk (%):" : "Lot Size:";
      if(!CreateLabel(m_panelName + "_RiskInputLabel", m_x + 10, yPos, riskLabel, clrWhite))
         return false;
      
      // Risk input edit
      string riskValue = (m_riskMode == RISK_MODE_CURRENCY) ? DoubleToString(m_riskCurrency, 2) :
                        (m_riskMode == RISK_MODE_PERCENT) ? DoubleToString(m_riskPercent, 2) :
                        DoubleToString(m_fixedLotSize, 2);
      
      if(!CreateEdit(m_editRiskName, m_x + 100, yPos, 140, 25, riskValue))
         return false;
      
      yPos += 35; // Spacing after risk input
      
      // Fixed RR checkbox and input
      if(!CreateCheckbox(m_checkFixedRRName, m_x + 10, yPos, "Use Fixed R:R", InpUseFixedRR))
         return false;
      
      if(InpUseFixedRR)
      {
         if(!CreateEdit(m_editFixedRRName, m_x + 130, yPos, 110, 22, DoubleToString(InpFixedRR, 2)))
            return false;
      }
      
      yPos += 30;
      
      // Execute trade button (moved here, smaller size)
      if(!CreateButton(m_panelName + "_BtnExecute", m_x + 10, yPos, 230, 25, "EXECUTE", clrLimeGreen))
         return false;
      
      yPos += 35; // Spacing after execute button
      
      // Calculated lot label
      if(!CreateLabel(m_labelLotName, m_x + 10, yPos, "Lot: 0.00", clrLime))
         return false;
      
      yPos += 25;
      
      // Instructions label
      if(!CreateLabel(m_panelName + "_Instructions", m_x + 10, yPos, "Press Enter or click Open", clrSilver))
         return false;
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create checkbox                                                 |
   //+------------------------------------------------------------------+
   bool CreateCheckbox(string name, int x, int y, string text, bool checked)
   {
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      
      if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, 120);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, 22);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TEXT, (checked ? "☑ " : "☐ ") + text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, checked ? clrDodgerBlue : C'50,50,50');
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, checked ? clrLime : clrGray);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create radio button                                             |
   //+------------------------------------------------------------------+
   bool CreateRadioButton(string name, int x, int y, string text, bool selected)
   {
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      
      if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, 230);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, 22);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TEXT, "● " + text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, selected ? clrDodgerBlue : C'50,50,50');
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, selected ? clrLime : clrGray);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create edit box                                                 |
   //+------------------------------------------------------------------+
   bool CreateEdit(string name, int x, int y, int width, int height, string text)
   {
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      
      if(!ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'40,40,40');
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrSilver);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_READONLY, false);
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create label                                                    |
   //+------------------------------------------------------------------+
   bool CreateLabel(string name, int x, int y, string text, color textColor)
   {
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      
      if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create account info labels                                      |
   //+------------------------------------------------------------------+
   bool CreateLabels()
   {
      UpdateAccountInfo();
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Update account info                                             |
   //+------------------------------------------------------------------+
   void UpdateAccountInfo()
   {
      if(!m_enableUI) return;
      
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double profit = equity - balance;
      
      int yPos = m_y + 110 + 25 + 25 + 25 + 30 + 35 + 30 + 35 + 25 + 25; // After lot label and instructions
      
      CreateLabel(m_labelBalanceName, m_x + 10, yPos, "Balance: $" + DoubleToString(balance, 2), clrWhite);
      yPos += 22;
      CreateLabel(m_labelEquityName, m_x + 10, yPos, "Equity: $" + DoubleToString(equity, 2), clrWhite);
      yPos += 22;
      color profitColor = (profit >= 0) ? clrLime : clrRed;
      CreateLabel(m_labelProfitName, m_x + 10, yPos, "Profit: $" + DoubleToString(profit, 2), profitColor);
   }
   
   //+------------------------------------------------------------------+
   //| Update lot size display                                         |
   //+------------------------------------------------------------------+
   void UpdateLotSize(double lotSize, int slPoints)
   {
      if(!m_enableUI) return;
      
      string text = "Lot: " + DoubleToString(lotSize, 2);
      if(slPoints > 0)
      {
         text += " | SL: " + IntegerToString(slPoints) + " pts";
      }
      
      // Calculate correct Y position (after execute button)
      int yPos = m_y + 110 + 25 + 25 + 25 + 30 + 35 + 30 + 35; // Risk controls + risk input + fixed RR + execute button + spacing
      CreateLabel(m_labelLotName, m_x + 10, yPos, text, clrLime);
      ChartRedraw();
   }
   
   //+------------------------------------------------------------------+
   //| Handle chart event                                              |
   //+------------------------------------------------------------------+
   bool OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
   {
      if(!m_enableUI) return false;
      
      // Handle panel dragging via object drag
      if(id == CHARTEVENT_OBJECT_DRAG)
      {
         if(sparam == m_dragHandleName)
         {
            // lparam and dparam contain the new X and Y coordinates
            int newX = (int)lparam;
            int newY = (int)dparam;
            
            int deltaX = newX - m_x;
            int deltaY = newY - m_y;
            
            if(deltaX != 0 || deltaY != 0)
            {
               MovePanel(deltaX, deltaY);
            }
            return true;
         }
      }
      
      // Handle mouse click to start dragging
      if(id == CHARTEVENT_CLICK)
      {
         int x = (int)lparam;
         int y = (int)dparam;
         
         // Check if click is on drag handle area
         if(x >= m_x && x <= m_x + m_width && y >= m_y && y <= m_y + 25)
         {
            m_isDragging = true;
            m_dragStartX = x;
            m_dragStartY = y;
            return true;
         }
         else
         {
            m_isDragging = false;
         }
      }
      
      // Handle mouse move for dragging
      if(id == CHARTEVENT_MOUSE_MOVE && m_isDragging)
      {
         int x = (int)lparam;
         int y = (int)dparam;
         
         int deltaX = x - m_dragStartX;
         int deltaY = y - m_dragStartY;
         
         if(MathAbs(deltaX) > 2 || MathAbs(deltaY) > 2) // Only move if significant movement
         {
            MovePanel(deltaX, deltaY);
            m_dragStartX = x;
            m_dragStartY = y;
         }
         return true;
      }
      
      if(id == CHARTEVENT_OBJECT_CLICK)
      {
         // Handle button clicks
         if(sparam == m_btnBuyName)
         {
            return true; // Buy button clicked
         }
         else if(sparam == m_btnSellName)
         {
            return true; // Sell button clicked
         }
         else if(sparam == m_btnCloseName)
         {
            return true; // Close all clicked
         }
         else if(sparam == m_btnClearName)
         {
            return true; // Clear lines clicked
         }
         else if(sparam == m_radioCurrencyName)
         {
            m_riskMode = RISK_MODE_CURRENCY;
            RefreshRiskControls();
            return true;
         }
         else if(sparam == m_radioPercentName)
         {
            m_riskMode = RISK_MODE_PERCENT;
            RefreshRiskControls();
            return true;
         }
         else if(sparam == m_radioFixedName)
         {
            m_riskMode = RISK_MODE_FIXED;
            RefreshRiskControls();
            return true;
         }
         else if(sparam == m_checkFixedRRName)
         {
            // Toggle fixed RR
            // Note: This requires recompiling EA to change InpUseFixedRR
            // For now, just refresh to show/hide input
            RefreshRiskControls();
            return true;
         }
      }
      else if(id == CHARTEVENT_OBJECT_ENDEDIT)
      {
         if(sparam == m_editRiskName)
         {
            string text = ObjectGetString(0, m_editRiskName, OBJPROP_TEXT);
            double value = StringToDouble(text);
            
            if(m_riskMode == RISK_MODE_CURRENCY)
               m_riskCurrency = value;
            else if(m_riskMode == RISK_MODE_PERCENT)
               m_riskPercent = value;
            else if(m_riskMode == RISK_MODE_FIXED)
               m_fixedLotSize = value;
            
            return true;
         }
         else if(sparam == m_editFixedRRName)
         {
            // Fixed RR value changed - would need to update InpFixedRR
            // For now, just acknowledge the change
            return true;
         }
      }
      
      // Handle panel dragging - check if drag handle or background is being dragged
      if(id == CHARTEVENT_OBJECT_DRAG)
      {
         string bgName = m_panelName + "_BG";
         if(sparam == m_dragHandleName || sparam == bgName)
         {
            // Get new position from the dragged object
            int newX = (int)ObjectGetInteger(0, sparam, OBJPROP_XDISTANCE);
            int newY = (int)ObjectGetInteger(0, sparam, OBJPROP_YDISTANCE);
            
            // Calculate delta
            int deltaX = newX - m_x;
            int deltaY = newY - m_y;
            
            if(deltaX != 0 || deltaY != 0)
            {
               MovePanel(deltaX, deltaY);
            }
            return true;
         }
      }
      
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Refresh risk controls                                           |
   //+------------------------------------------------------------------+
   void RefreshRiskControls()
   {
      CreateRiskControls();
      ChartRedraw();
   }
   
   //+------------------------------------------------------------------+
   //| Get risk mode                                                   |
   //+------------------------------------------------------------------+
   ENUM_RISK_MODE GetRiskMode() { return m_riskMode; }
   
   //+------------------------------------------------------------------+
   //| Get risk currency                                               |
   //+------------------------------------------------------------------+
   double GetRiskCurrency() { return m_riskCurrency; }
   
   //+------------------------------------------------------------------+
   //| Get risk percent                                                |
   //+------------------------------------------------------------------+
   double GetRiskPercent() { return m_riskPercent; }
   
   //+------------------------------------------------------------------+
   //| Get fixed lot size                                             |
   //+------------------------------------------------------------------+
   double GetFixedLotSize() { return m_fixedLotSize; }
   
   //+------------------------------------------------------------------+
   //| Check if buy button clicked                                    |
   //+------------------------------------------------------------------+
   bool IsBuyClicked(const string& sparam) { return (sparam == m_btnBuyName); }
   
   //+------------------------------------------------------------------+
   //| Check if sell button clicked                                   |
   //+------------------------------------------------------------------+
   bool IsSellClicked(const string& sparam) { return (sparam == m_btnSellName); }
   
   //+------------------------------------------------------------------+
   //| Check if close all clicked                                     |
   //+------------------------------------------------------------------+
   bool IsCloseAllClicked(const string& sparam) { return (sparam == m_btnCloseName); }
   
   //+------------------------------------------------------------------+
   //| Check if clear lines clicked                                   |
   //+------------------------------------------------------------------+
   bool IsClearLinesClicked(const string& sparam) { return (sparam == m_btnClearName); }
   
   //+------------------------------------------------------------------+
   //| Check if execute trade clicked                                  |
   //+------------------------------------------------------------------+
   bool IsExecuteClicked(const string& sparam) { return (sparam == m_btnExecuteName); }
   
   //+------------------------------------------------------------------+
   //| Move panel                                                     |
   //+------------------------------------------------------------------+
   void MovePanel(int deltaX, int deltaY)
   {
      m_x += deltaX;
      m_y += deltaY;
      
      // Update positions of all objects without recreating
      string bgName = m_panelName + "_BG";
      if(ObjectFind(0, bgName) >= 0)
      {
         ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, m_x);
         ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, m_y);
      }
      
      if(ObjectFind(0, m_dragHandleName) >= 0)
      {
         ObjectSetInteger(0, m_dragHandleName, OBJPROP_XDISTANCE, m_x);
         ObjectSetInteger(0, m_dragHandleName, OBJPROP_YDISTANCE, m_y);
      }
      
      // Update all other objects
      ObjectsDeleteAll(0, m_panelName);
      Create();
      ChartRedraw();
   }
   
   //+------------------------------------------------------------------+
   //| Delete all objects                                             |
   //+------------------------------------------------------------------+
   void DeleteAll()
   {
      if(!m_enableUI) return;
      
      ObjectsDeleteAll(0, m_panelName);
      ChartRedraw();
   }
   
   //+------------------------------------------------------------------+
   //| Set visible                                                     |
   //+------------------------------------------------------------------+
   void SetVisible(bool visible)
   {
      m_visible = visible;
      if(m_enableUI)
      {
         // Show/hide all panel objects
         // Implementation can be added if needed
      }
   }
};

//+------------------------------------------------------------------+