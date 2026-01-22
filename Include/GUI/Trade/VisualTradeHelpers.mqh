//+------------------------------------------------------------------+
//| VisualTradeHelpers.mqh                                           |
//| Helper functions for visual trade lines                          |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| UI Component Width Constants (Composite Panel Layout)            |
//+------------------------------------------------------------------+
#define COMPOSITE_TAG_WIDTH           38   // Width of tag label ("Tp"/"Sl"/"Buy"/"Sell")
#define COMPOSITE_INFO_WIDTH         100   // Width of info section (points, USD, percentage labels)
#define COMPOSITE_EDIT_WIDTH          72   // Width of price edit input box
#define COMPOSITE_BUTTON_WIDTH        22   // Width of pin button (or close button)
#define COMPOSITE_RIGHT_PADDING        8   // Right padding from chart edge
#define COMPOSITE_PANEL_WIDTH        280  // Total panel width (sum of all components)

//+------------------------------------------------------------------+
//| UI Component X Position Offsets (from panel start)             |
//+------------------------------------------------------------------+
#define COMPOSITE_OFFSET_TAG_START     0   // Tag starts at panel start (m_x + 0)
#define COMPOSITE_OFFSET_LABEL_PADDING 8   // Padding for labels inside tag area (m_x + 8)
#define COMPOSITE_OFFSET_INFO_START   38   // Info section starts after tag (m_x + 38)
#define COMPOSITE_OFFSET_USD_LABEL    88   // USD label X position (m_x + 88)
#define COMPOSITE_OFFSET_PCT_LABEL   150   // Percentage label X position (m_x + 150)
#define COMPOSITE_OFFSET_EDIT_START  138   // Edit box starts here (m_x + 138)
#define COMPOSITE_OFFSET_BUTTON_START 210  // Button starts here (m_x + 210)
#define COMPOSITE_OFFSET_CLOSE_BUTTON 258  // Close button X position (m_x + 258)

//+------------------------------------------------------------------+
//| Helper: Calculate composite panel X position (right-aligned)    |
//+------------------------------------------------------------------+
int CalculateCompositePanelX(int chartWidth)
{
   return chartWidth - (COMPOSITE_TAG_WIDTH + COMPOSITE_INFO_WIDTH + COMPOSITE_EDIT_WIDTH + COMPOSITE_BUTTON_WIDTH + COMPOSITE_RIGHT_PADDING);
}

//+------------------------------------------------------------------+
//| Helper: Convert price to Y coordinate (using ChartTimePriceToXY for immediate sync) |
//+------------------------------------------------------------------+
bool PriceToY(long chart_id, double price, int &y_out)
{
   // Use ChartTimePriceToXY for immediate, accurate Y coordinate during drag
   // For horizontal lines, Y is constant across X, so use current time at right edge
   // Calculate at right edge X (where composite panel is) for accurate positioning
   int chartWidth = (int)ChartGetInteger(chart_id, CHART_WIDTH_IN_PIXELS);
   datetime chartTime = TimeCurrent(); // Use current time for right edge
   
   int x_temp;
   // Calculate Y at the right edge X position (where composite panel is located)
   ChartTimePriceToXY(chart_id, 0, chartTime, price, x_temp, y_out);
   return true;
}

//+------------------------------------------------------------------+
//| Helper: Delete object by name                                    |
//+------------------------------------------------------------------+
void ObjDel(long chart_id, string name)
{
   if(ObjectFind(chart_id, name) >= 0)
      ObjectDelete(chart_id, name);
}

//+------------------------------------------------------------------+
//| Helper: Get symbol digits                                       |
//+------------------------------------------------------------------+
int DigitsSym() { return (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS); }

//+------------------------------------------------------------------+
//| Helper: Format price to string                                  |
//+------------------------------------------------------------------+
string PriceToStr(double p) { return DoubleToString(p, DigitsSym()); }

//+------------------------------------------------------------------+
//| Helper: Create color with alpha (opacity) using ARGB format    |
//+------------------------------------------------------------------+
color ColorWithAlpha(int red, int green, int blue, int alpha)
{
   return (color)((alpha << 24) | (red << 16) | (green << 8) | blue);
}
