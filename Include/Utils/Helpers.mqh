//+------------------------------------------------------------------+
//| Helpers.mqh                                                      |
//| General helper utilities                                         |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Debug log helper (NDJSON format)                                |
//+------------------------------------------------------------------+
void WriteDebugLog(string location, string message, string dataJson)
{
   string logPath = "ForexTradeAssistant_debug.log";
   int fileHandle = FileOpen(logPath, FILE_WRITE | FILE_READ | FILE_TXT | FILE_COMMON);
   if(fileHandle == INVALID_HANDLE)
   {
      int error = GetLastError();
      Print("[DEBUG LOG ERROR] FileOpen failed: ", error, " for path: ", logPath);
      Print("[DEBUG] ", location, " - ", message, " - ", dataJson);
   }
   else
   {
      FileSeek(fileHandle, 0, SEEK_END);
      string logLine = "{\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"location\":\"" + location + "\",\"message\":\"" + message + "\",\"data\":" + dataJson + ",\"timestamp\":" + IntegerToString((int)TimeCurrent()) + "000}";
      FileWriteString(fileHandle, logLine + "\n");
      FileClose(fileHandle);
   }
}

//+------------------------------------------------------------------+
//| Price to Y coordinate conversion (for chart drawing)            |
//+------------------------------------------------------------------+
int PriceToY(double price)
{
   int y;
   ChartTimePriceToXY(0, 0, TimeCurrent(), price, y, y);
   return y;
}

//+------------------------------------------------------------------+
//| Create shade label at right edge                                |
//+------------------------------------------------------------------+
void CreateShadeLabel(const string name,
   double priceLow,
   double priceHigh,
   color clr)
{
   int chartWidth  = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   
   int rightPadding = 0;   // distance from right edge
   int widthPx      = 100;   // shaded width
   
   int x = chartWidth - rightPadding - widthPx;
   
   int y1, y2, tempX;
   // Get Y coordinates for prices at current time (right edge)
   ChartTimePriceToXY(0, 0, TimeCurrent(), priceLow,  tempX, y1);
   ChartTimePriceToXY(0, 0, TimeCurrent(), priceHigh, tempX, y2);
   
   // Ensure y1 is top (smaller Y) and y2 is bottom (larger Y)
   if(y1 > y2) 
   { 
      int tmp = y1; 
      y1 = y2; 
      y2 = tmp; 
   }
   
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y1);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, widthPx);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, y2 - y1);
   
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
