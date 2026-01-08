//+------------------------------------------------------------------+
//| ObjectNames.mqh                                                  |
//| Chart object naming utilities - LOCAL ONLY                      |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"

//+------------------------------------------------------------------+
//| Object name prefix                                               |
//+------------------------------------------------------------------+
#define OBJ_PREFIX EA_NAME + "_"

//+------------------------------------------------------------------+
//| Generate object name                                             |
//+------------------------------------------------------------------+
string GenerateObjectName(string baseName, int id = 0)
{
   if(id > 0)
      return OBJ_PREFIX + baseName + "_" + IntegerToString(id);
   return OBJ_PREFIX + baseName + "_" + IntegerToString(GetTickCount());
}

//+------------------------------------------------------------------+
//| Clean up objects by prefix                                       |
//+------------------------------------------------------------------+
void CleanupObjects(string prefix)
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
