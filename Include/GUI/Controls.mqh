//+------------------------------------------------------------------+
//| Controls.mqh                                                     |
//| UI Control helper functions                                      |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Theme.mqh"

//+------------------------------------------------------------------+
//| Create button                                                    |
//+------------------------------------------------------------------+
bool CreateUIButton(string name, int x, int y, int width, int height, 
                   string text, color bgColor, color textColor = COLOR_TEXT_PRIMARY)
{
   if(!InpEnableUI) return true;
   
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
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, COLOR_BORDER);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FONT_SIZE_NORMAL);
   ObjectSetString(0, name, OBJPROP_FONT, FONT_NAME);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 100); // Ensure buttons are on top and clickable
   
   return true;
}

//+------------------------------------------------------------------+
//| Create label                                                     |
//+------------------------------------------------------------------+
bool CreateUILabel(string name, int x, int y, string text, color textColor = COLOR_TEXT_PRIMARY, int fontSize = FONT_SIZE_NORMAL)
{
   if(!InpEnableUI) return true;
   
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
      return false;
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, FONT_NAME);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   
   return true;
}

//+------------------------------------------------------------------+
//| Create edit box                                                  |
//+------------------------------------------------------------------+
bool CreateUIEdit(string name, int x, int y, int width, int height, string text)
{
   if(!InpEnableUI) return true;
   
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
   ObjectSetInteger(0, name, OBJPROP_COLOR, COLOR_TEXT_PRIMARY);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, COLOR_BG_DARK);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, COLOR_BORDER);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FONT_SIZE_NORMAL);
   ObjectSetString(0, name, OBJPROP_FONT, FONT_NAME);
   ObjectSetInteger(0, name, OBJPROP_READONLY, false);
   
   return true;
}

//+------------------------------------------------------------------+
//| Create toggle switch                                             |
//+------------------------------------------------------------------+
bool CreateUIToggle(string name, int x, int y, int width, int height, string text, bool checked)
{
   if(!InpEnableUI) return true;
   
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
      return false;
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, name, OBJPROP_TEXT, (checked ? "✓ " : "") + text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, COLOR_TEXT_PRIMARY);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, checked ? COLOR_ACCENT_GREEN : COLOR_BG_PANEL);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, checked ? COLOR_ACCENT_GREEN : COLOR_BORDER);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FONT_SIZE_NORMAL);
   ObjectSetString(0, name, OBJPROP_FONT, FONT_NAME);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 100); // Ensure buttons are on top and clickable
   
   return true;
}

//+------------------------------------------------------------------+
//| Create rectangle (for stat boxes, backgrounds)                   |
//+------------------------------------------------------------------+
bool CreateUIRectangle(string name, int x, int y, int width, int height, color bgColor)
{
   if(!InpEnableUI) return true;
   
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return false;
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, COLOR_BORDER);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   
   return true;
}

//+------------------------------------------------------------------+
