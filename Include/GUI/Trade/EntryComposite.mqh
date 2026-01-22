//+------------------------------------------------------------------+
//| EntryComposite.mqh                                                |
//| Entry composite: entry HLINE + bottom bar                        |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "VisualTradeHelpers.mqh"
#include "../../Utils/Helpers.mqh"

//+------------------------------------------------------------------+
//| Entry composite: entry HLINE + bottom bar                        |
//+------------------------------------------------------------------+
class CEntryComposite
{
private:
   long   m_chart;
   int    m_subwin;
   string m_prefix;
   bool   m_is_buy;
   bool   m_wasManuallyDragged;

   string n_line;
   string n_panel;
   string n_side_bg;
   string n_lbl_side;
   string n_edit_price;
   string n_lbl_lot;
   string n_btn_open;
   string n_btn_close;

   int m_x, m_w, m_h;

public:
   bool Create(long chart_id, int subwin, string prefix, double initial_price, bool isBuy = true)
   {
      m_chart  = chart_id;
      m_subwin = subwin;
      m_prefix = prefix;
      m_is_buy = isBuy;
      m_wasManuallyDragged = false;

      n_line       = m_prefix + "_HLINE";
      n_panel      = m_prefix + "_PANEL";
      n_side_bg    = m_prefix + "_SIDE_BG";
      n_lbl_side   = m_prefix + "_SIDE_LBL";
      n_edit_price = m_prefix + "_PRICE";
      n_lbl_lot    = m_prefix + "_LOT";
      n_btn_open   = m_prefix + "_OPEN";
      n_btn_close  = m_prefix + "_CLOSE";

      int cw = (int)ChartGetInteger(m_chart, CHART_WIDTH_IN_PIXELS);
      m_x = CalculateCompositePanelX(cw);
      m_w = COMPOSITE_PANEL_WIDTH;
      m_h = 20;

      // Entry line
      if(!ObjectCreate(m_chart, n_line, OBJ_HLINE, m_subwin, 0, initial_price))
         return false;
      ObjectSetInteger(m_chart, n_line, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(m_chart, n_line, OBJPROP_WIDTH, 1);
      ObjectSetInteger(m_chart, n_line, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(m_chart, n_line, OBJPROP_SELECTED, true);
      ObjectSetInteger(m_chart, n_line, OBJPROP_ZORDER, 0);
      ObjectSetInteger(m_chart, n_line, OBJPROP_BACK, true);

      // Panel
      if(!ObjectCreate(m_chart, n_panel, OBJ_RECTANGLE_LABEL, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_panel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_XSIZE, m_w);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_BGCOLOR, clrDodgerBlue);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_BACK, false);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_ZORDER, 100);

      // Side colored background
      if(!ObjectCreate(m_chart, n_side_bg, OBJ_RECTANGLE_LABEL, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_side_bg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_side_bg, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(m_chart, n_side_bg, OBJPROP_XSIZE, COMPOSITE_TAG_WIDTH);
      ObjectSetInteger(m_chart, n_side_bg, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_side_bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chart, n_side_bg, OBJPROP_SELECTABLE, false);

      // Side label
      if(!ObjectCreate(m_chart, n_lbl_side, OBJ_LABEL, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_lbl_side, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_lbl_side, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_LABEL_PADDING);
      ObjectSetInteger(m_chart, n_lbl_side, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chart, n_lbl_side, OBJPROP_COLOR, clrWhite);

      // Lot size label
      if(!ObjectCreate(m_chart, n_lbl_lot, OBJ_LABEL, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_lbl_lot, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_lbl_lot, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_INFO_START);
      ObjectSetInteger(m_chart, n_lbl_lot, OBJPROP_YDISTANCE, 0);
      ObjectSetInteger(m_chart, n_lbl_lot, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chart, n_lbl_lot, OBJPROP_COLOR, clrWhite);
      ObjectSetString (m_chart, n_lbl_lot, OBJPROP_TEXT, "Lot 0.00");
      ObjectSetInteger(m_chart, n_lbl_lot, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_lbl_lot, OBJPROP_BACK, false);
      ObjectSetInteger(m_chart, n_lbl_lot, OBJPROP_ZORDER, 300);

      // Price edit
      if(!ObjectCreate(m_chart, n_edit_price, OBJ_EDIT, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_EDIT_START);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_XSIZE, COMPOSITE_EDIT_WIDTH);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetString (m_chart, n_edit_price, OBJPROP_TEXT, PriceToStr(initial_price));
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_READONLY, false);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_BACK, false);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_ZORDER, 300);

      // Open button
      if(!ObjectCreate(m_chart, n_btn_open, OBJ_BUTTON, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_btn_open, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_btn_open, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_BUTTON_START);
      ObjectSetInteger(m_chart, n_btn_open, OBJPROP_XSIZE, 50);
      ObjectSetInteger(m_chart, n_btn_open, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_btn_open, OBJPROP_FONTSIZE, 9);
      ObjectSetString (m_chart, n_btn_open, OBJPROP_TEXT, "Open");
      ObjectSetInteger(m_chart, n_btn_open, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chart, n_btn_open, OBJPROP_BGCOLOR, C'0,150,0');
      ObjectSetInteger(m_chart, n_btn_open, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_btn_open, OBJPROP_ZORDER, 300);

      // Close X
      if(!ObjectCreate(m_chart, n_btn_close, OBJ_BUTTON, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_btn_close, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_btn_close, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_CLOSE_BUTTON);
      ObjectSetInteger(m_chart, n_btn_close, OBJPROP_XSIZE, COMPOSITE_BUTTON_WIDTH);
      ObjectSetInteger(m_chart, n_btn_close, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_btn_close, OBJPROP_FONTSIZE, 9);
      ObjectSetString (m_chart, n_btn_close, OBJPROP_TEXT, "x");
      ObjectSetInteger(m_chart, n_btn_close, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chart, n_btn_close, OBJPROP_BGCOLOR, C'200,0,0');
      ObjectSetInteger(m_chart, n_btn_close, OBJPROP_SELECTABLE, false);

      ApplySideVisual();
      UpdateLayout();
      return true;
   }

   void Destroy()
   {
      ObjDel(m_chart, n_line);
      ObjDel(m_chart, n_panel);
      ObjDel(m_chart, n_side_bg);
      ObjDel(m_chart, n_lbl_side);
      ObjDel(m_chart, n_edit_price);
      ObjDel(m_chart, n_lbl_lot);
      ObjDel(m_chart, n_btn_open);
      ObjDel(m_chart, n_btn_close);
   }

   void ApplySideVisual()
   {
      if(m_is_buy)
      {
         ObjectSetInteger(m_chart, n_side_bg, OBJPROP_BGCOLOR, C'0,90,200');
         ObjectSetString (m_chart, n_lbl_side, OBJPROP_TEXT, "Buy");
         ObjectSetInteger(m_chart, n_line, OBJPROP_COLOR, clrDodgerBlue);
      }
      else
      {
         ObjectSetInteger(m_chart, n_side_bg, OBJPROP_BGCOLOR, clrRed);
         ObjectSetString (m_chart, n_lbl_side, OBJPROP_TEXT, "Sell");
         ObjectSetInteger(m_chart, n_line, OBJPROP_COLOR, clrRed);
      }
   }

   double Price() const { return ObjectGetDouble(m_chart, n_line, OBJPROP_PRICE); }

   void SetPrice(double p)
   {
      p = NormalizePrice(p);
      ObjectSetDouble(m_chart, n_line, OBJPROP_PRICE, p);
      ObjectSetString(m_chart, n_edit_price, OBJPROP_TEXT, PriceToStr(p));
      UpdateLayout();
   }

   void UpdateLayout()
   {
      double currentPrice = ObjectGetDouble(m_chart, n_line, OBJPROP_PRICE);
      int y;
      if(!PriceToY(m_chart, currentPrice, y))
         return;

      int ydist = y - (m_h/2);
      
      int cw = (int)ChartGetInteger(m_chart, CHART_WIDTH_IN_PIXELS);
      int newX = CalculateCompositePanelX(cw);
      if(newX != m_x)
      {
         m_x = newX;
         ObjectSetInteger(m_chart, n_panel,      OBJPROP_XDISTANCE, m_x);
         ObjectSetInteger(m_chart, n_side_bg,    OBJPROP_XDISTANCE, m_x);
         ObjectSetInteger(m_chart, n_lbl_side,   OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_LABEL_PADDING);
         ObjectSetInteger(m_chart, n_lbl_lot,    OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_INFO_START);
         ObjectSetInteger(m_chart, n_edit_price, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_EDIT_START);
         ObjectSetInteger(m_chart, n_btn_open,   OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_BUTTON_START);
         ObjectSetInteger(m_chart, n_btn_close,  OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_CLOSE_BUTTON);
      }

      ObjectSetInteger(m_chart, n_panel,      OBJPROP_YDISTANCE, ydist);
      ObjectSetInteger(m_chart, n_side_bg,    OBJPROP_YDISTANCE, ydist);
      ObjectSetInteger(m_chart, n_lbl_side,   OBJPROP_YDISTANCE, ydist + 2);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_YDISTANCE, ydist);
      ObjectSetInteger(m_chart, n_lbl_lot,    OBJPROP_YDISTANCE, ydist + 2);
      ObjectSetInteger(m_chart, n_btn_open,   OBJPROP_YDISTANCE, ydist);
      ObjectSetInteger(m_chart, n_btn_close, OBJPROP_YDISTANCE, ydist);
   }
   
   void SetLotSizeText(string lotText)
   {
      ObjectSetString(m_chart, n_lbl_lot, OBJPROP_TEXT, lotText);
   }

   bool OnChartEvent(const int id, const string &sparam)
   {
      if((id == CHARTEVENT_OBJECT_DRAG || id == CHARTEVENT_OBJECT_CHANGE) && sparam == n_line)
      {
         m_wasManuallyDragged = true;
         double currentPrice = ObjectGetDouble(m_chart, n_line, OBJPROP_PRICE);
         ObjectSetString(m_chart, n_edit_price, OBJPROP_TEXT, PriceToStr(currentPrice));
         UpdateLayout();
         ChartRedraw(0);
         return false;
      }

      if(id == CHARTEVENT_OBJECT_CLICK && sparam == n_btn_open)
         return false;

      if(id == CHARTEVENT_OBJECT_CLICK && sparam == n_btn_close)
      {
         Destroy();
         return true;
      }

      if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == n_edit_price)
      {
         double p = StringToDouble(ObjectGetString(m_chart, n_edit_price, OBJPROP_TEXT));
         if(p > 0) SetPrice(p);
         return true;
      }

      if(id == CHARTEVENT_CHART_CHANGE)
      {
         UpdateLayout();
         return false;
      }

      return false;
   }

   string LineName() const { return n_line; }
   string EditName() const { return n_edit_price; }
   bool WasManuallyDragged() const { return m_wasManuallyDragged; }
   void SetManuallyDragged(bool dragged) { m_wasManuallyDragged = dragged; }
   string OpenBtnName() const { return n_btn_open; }
   
   void SetSideLabel(string labelText)
   {
      ObjectSetString(m_chart, n_lbl_side, OBJPROP_TEXT, labelText);
   }
   bool IsBuy() const { return m_is_buy; }
};
