//+------------------------------------------------------------------+
//| LineInfoComposite.mqh                                             |
//| TP/SL composite: line + panel + labels + edits                   |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "VisualTradeHelpers.mqh"
#include "../../Utils/Helpers.mqh"

//+------------------------------------------------------------------+
//| Base composite: line + panel + labels + edits                   |
//+------------------------------------------------------------------+
class CLineInfoComposite
{
protected:
   long   m_chart;
   int    m_subwin;
   string m_prefix;
   bool   m_isBuy;
   bool   m_isPinned;

   // object names
   string n_line;
   string n_panel;
   string n_tag;       // "Tp"/"Sl"
   string n_points;    // text label (e.g. "909")
   string n_usd;       // text label (e.g. "9.09 USD")
   string n_pct;       // text label (e.g. "0.03%")
   string n_edit_price;
   string n_pin_btn;   // Pin button

   // layout
   int m_x;
   int m_w;
   int m_h;

   // colors
   color m_line_color;
   color m_panel_bg;
   color m_panel_border;

public:
   bool Create(long chart_id, int subwin, string prefix,
               color line_color, color panel_bg, string tag_text,
               double initial_price, bool isBuy = true)
   {
      m_chart  = chart_id;
      m_subwin = subwin;
      m_prefix = prefix;
      m_isBuy  = isBuy;
      m_isPinned = false;

      n_line        = m_prefix + "_HLINE";
      n_panel       = m_prefix + "_PANEL";
      n_tag         = m_prefix + "_TAG";
      n_points      = m_prefix + "_POINTS";
      n_usd         = m_prefix + "_USD";
      n_pct         = m_prefix + "_PCT";
      n_edit_price  = m_prefix + "_EDIT_PRICE";
      n_pin_btn     = m_prefix + "_PIN";

      int cw = (int)ChartGetInteger(m_chart, CHART_WIDTH_IN_PIXELS);
      m_x = CalculateCompositePanelX(cw);
      m_w = COMPOSITE_PANEL_WIDTH;
      m_h = 18;

      m_line_color   = line_color;
      m_panel_bg     = panel_bg;
      m_panel_border = line_color;

      // 1) HLINE
      if(!ObjectCreate(m_chart, n_line, OBJ_HLINE, m_subwin, 0, initial_price))
         return false;
      ObjectSetInteger(m_chart, n_line, OBJPROP_COLOR, m_line_color);
      ObjectSetInteger(m_chart, n_line, OBJPROP_WIDTH, 1);
      ObjectSetInteger(m_chart, n_line, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(m_chart, n_line, OBJPROP_SELECTED, true);

      // 2) Panel (background)
      if(!ObjectCreate(m_chart, n_panel, OBJ_RECTANGLE_LABEL, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_panel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_XSIZE, m_w);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_BGCOLOR, m_panel_bg);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_COLOR, m_panel_border);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_panel, OBJPROP_BACK, true);

      // 3) Tag label ("Tp"/"Sl")
      if(!ObjectCreate(m_chart, n_tag, OBJ_RECTANGLE_LABEL, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_tag, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_tag, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(m_chart, n_tag, OBJPROP_XSIZE, COMPOSITE_TAG_WIDTH);
      ObjectSetInteger(m_chart, n_tag, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_tag, OBJPROP_BGCOLOR, m_panel_bg);
      ObjectSetInteger(m_chart, n_tag, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chart, n_tag, OBJPROP_BORDER_COLOR, m_panel_bg);
      ObjectSetInteger(m_chart, n_tag, OBJPROP_FONTSIZE, 9);
      ObjectSetString (m_chart, n_tag, OBJPROP_FONT, "Arial Bold");
      ObjectSetString (m_chart, n_tag, OBJPROP_TEXT, tag_text);
      ObjectSetInteger(m_chart, n_tag, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_tag, OBJPROP_BACK, false);

      // 4) Points label
      if(!ObjectCreate(m_chart, n_points, OBJ_RECTANGLE_LABEL, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_points, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_points, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_INFO_START);
      ObjectSetInteger(m_chart, n_points, OBJPROP_XSIZE, 50);
      ObjectSetInteger(m_chart, n_points, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_points, OBJPROP_BGCOLOR, m_panel_bg);
      ObjectSetInteger(m_chart, n_points, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chart, n_points, OBJPROP_BORDER_COLOR, m_panel_bg);
      ObjectSetInteger(m_chart, n_points, OBJPROP_FONTSIZE, 9);
      ObjectSetString (m_chart, n_points, OBJPROP_FONT, "Arial");
      ObjectSetString (m_chart, n_points, OBJPROP_TEXT, "0");
      ObjectSetInteger(m_chart, n_points, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_points, OBJPROP_BACK, false);

      // 4b) USD label
      if(!ObjectCreate(m_chart, n_usd, OBJ_LABEL, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_usd, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_usd, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_USD_LABEL);
      ObjectSetInteger(m_chart, n_usd, OBJPROP_YDISTANCE, 0);
      ObjectSetInteger(m_chart, n_usd, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chart, n_usd, OBJPROP_COLOR, clrWhite);
      ObjectSetString (m_chart, n_usd, OBJPROP_TEXT, "0.00 USD");
      ObjectSetInteger(m_chart, n_usd, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_usd, OBJPROP_BACK, false);

      // 4c) Percentage label
      if(!ObjectCreate(m_chart, n_pct, OBJ_LABEL, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_pct, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_pct, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_PCT_LABEL);
      ObjectSetInteger(m_chart, n_pct, OBJPROP_YDISTANCE, 0);
      ObjectSetInteger(m_chart, n_pct, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chart, n_pct, OBJPROP_COLOR, clrWhite);
      ObjectSetString (m_chart, n_pct, OBJPROP_TEXT, "0.00%");
      ObjectSetInteger(m_chart, n_pct, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_pct, OBJPROP_BACK, false);

      // 5) Price input box
      if(!ObjectCreate(m_chart, n_edit_price, OBJ_EDIT, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_EDIT_START);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_XSIZE, COMPOSITE_EDIT_WIDTH);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_BORDER_COLOR, clrWhite);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_FONTSIZE, 9);
      ObjectSetString (m_chart, n_edit_price, OBJPROP_TEXT, PriceToStr(initial_price));
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_READONLY, false);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_BACK, false);
      ObjectSetInteger(m_chart, n_edit_price, OBJPROP_ZORDER, 300);

      // 6) Pin button
      if(!ObjectCreate(m_chart, n_pin_btn, OBJ_BUTTON, m_subwin, 0, 0))
         return false;
      ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_BUTTON_START);
      ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_XSIZE, COMPOSITE_BUTTON_WIDTH);
      ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_YSIZE, m_h);
      ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_FONTSIZE, 9);
      ObjectSetString (m_chart, n_pin_btn, OBJPROP_TEXT, "📍");
      ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_BGCOLOR, clrDarkSlateGray);
      ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_SELECTABLE, false);

      UpdateLayout();
      return true;
   }

   void Destroy()
   {
      ObjDel(m_chart, n_line);
      ObjDel(m_chart, n_panel);
      ObjDel(m_chart, n_tag);
      ObjDel(m_chart, n_points);
      ObjDel(m_chart, n_usd);
      ObjDel(m_chart, n_pct);
      ObjDel(m_chart, n_edit_price);
      ObjDel(m_chart, n_pin_btn);
   }

   double Price() const
   {
      return ObjectGetDouble(m_chart, n_line, OBJPROP_PRICE);
   }

   void SetPrice(double p)
   {
      p = NormalizePrice(p);
      ObjectSetDouble(m_chart, n_line, OBJPROP_PRICE, p);
      ObjectSetString(m_chart, n_edit_price, OBJPROP_TEXT, PriceToStr(p));
      UpdateLayout();
      ObjectSetInteger(m_chart, n_line, OBJPROP_SELECTABLE, !m_isPinned);
      ObjectSetInteger(m_chart, n_line, OBJPROP_SELECTED, !m_isPinned);
   }

   void SetPointsText(string s) 
   { 
      // Parse the text format: "points amount USD percent%"
      string parts[];
      int count = StringSplit(s, ' ', parts);
      if(count >= 1)
         ObjectSetString(m_chart, n_points, OBJPROP_TEXT, parts[0]); // Points
      if(count >= 3 && parts[2] == "USD")
         ObjectSetString(m_chart, n_usd, OBJPROP_TEXT, parts[1] + " USD"); // USD amount
      if(count >= 4)
      {
         string pctStr = parts[3];
         if(StringFind(pctStr, "%") >= 0)
            ObjectSetString(m_chart, n_pct, OBJPROP_TEXT, pctStr);
         else
            ObjectSetString(m_chart, n_pct, OBJPROP_TEXT, pctStr + "%");
      }
   }

   void UpdateLayout()
   {
      int y;
      if(!PriceToY(m_chart, Price(), y))
         return;

      int ydist = y - (m_h/2);
      
      int cw = (int)ChartGetInteger(m_chart, CHART_WIDTH_IN_PIXELS);
      int newX = CalculateCompositePanelX(cw);
      if(newX != m_x)
      {
         m_x = newX;
         ObjectSetInteger(m_chart, n_panel,      OBJPROP_XDISTANCE, m_x);
         ObjectSetInteger(m_chart, n_tag,        OBJPROP_XDISTANCE, m_x);
         ObjectSetInteger(m_chart, n_points,      OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_INFO_START);
         ObjectSetInteger(m_chart, n_usd,        OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_USD_LABEL);
         ObjectSetInteger(m_chart, n_pct,        OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_PCT_LABEL);
         ObjectSetInteger(m_chart, n_edit_price, OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_EDIT_START);
         ObjectSetInteger(m_chart, n_pin_btn,    OBJPROP_XDISTANCE, m_x + COMPOSITE_OFFSET_BUTTON_START);
      }

      ObjectSetInteger(m_chart, n_panel,       OBJPROP_YDISTANCE, ydist);
      ObjectSetInteger(m_chart, n_tag,         OBJPROP_YDISTANCE, ydist);
      ObjectSetInteger(m_chart, n_points,     OBJPROP_YDISTANCE, ydist + 2);
      ObjectSetInteger(m_chart, n_usd,        OBJPROP_YDISTANCE, ydist + 2);
      ObjectSetInteger(m_chart, n_pct,        OBJPROP_YDISTANCE, ydist + 2);
      ObjectSetInteger(m_chart, n_edit_price,  OBJPROP_YDISTANCE, ydist);
      ObjectSetInteger(m_chart, n_pin_btn,     OBJPROP_YDISTANCE, ydist);
   }

    bool OnChartEvent(const int id, const string &sparam)
    {
       if((id == CHARTEVENT_OBJECT_DRAG || id == CHARTEVENT_OBJECT_CHANGE) && sparam == n_line)
       {
          double currentPrice = ObjectGetDouble(m_chart, n_line, OBJPROP_PRICE);
          ObjectSetString(m_chart, n_edit_price, OBJPROP_TEXT, PriceToStr(currentPrice));
          UpdateLayout();
          ChartRedraw(0);
          return false;
       }

      if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == n_edit_price)
      {
         double p = StringToDouble(ObjectGetString(m_chart, n_edit_price, OBJPROP_TEXT));
         if(p > 0) SetPrice(p);
         return true;
      }

      if(id == CHARTEVENT_OBJECT_CLICK && sparam == n_pin_btn)
      {
         m_isPinned = !m_isPinned;
         ObjectSetString(m_chart, n_pin_btn, OBJPROP_TEXT, m_isPinned ? "📌" : "📍");
         ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_COLOR, m_isPinned ? clrYellow : clrWhite);
         ObjectSetInteger(m_chart, n_pin_btn, OBJPROP_BGCOLOR, m_isPinned ? clrDarkOrange : clrDarkSlateGray);
         ObjectSetInteger(m_chart, n_line, OBJPROP_SELECTABLE, !m_isPinned);
         ObjectSetInteger(m_chart, n_line, OBJPROP_SELECTED, !m_isPinned);
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
   string PinBtnName() const { return n_pin_btn; }
   bool IsPinned() const { return m_isPinned; }
   void SetPinned(bool pinned) { m_isPinned = pinned; }
};
