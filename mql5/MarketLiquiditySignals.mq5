//+------------------------------------------------------------------+
//| EPIPHANY 2.0 - MULTI-TIMEFRAME LIQUIDITY & TRADING SIGNALS       |
//| For Global Trading Community                                      |
//| by Julio Henrique Viera Nieves                                    |
//| Versión: 2.0 - EMA20, EMA200, EMA400                              |
//| EMA40 y EMA80 ELIMINADAS - Menos ruido, más estructura            |
//+------------------------------------------------------------------+
#property copyright "Epiphany Trading - Julio Viera"
#property link      "https://www.mql5.com"
#property version   "2.0"
#property indicator_chart_window

//=========================== EMA CONFIGURATION ============================
input int ema20Period = 20;      // EMA Rápida (Entrada)
input int ema200Period = 200;    // EMA Institucional (Soporte/Resistencia)
input int ema400Period = 400;    // EMA Campo Gravitatorio (Contexto Mayor)

//=== COLORS FOR EMAs ===
input color color_ema20 = clrDodgerBlue;
input color color_ema200 = clrGray;
input color color_ema400 = clrGold;

//=== SHOW LEVELS ON CHART ===
input bool show_max_min = true;

//=== VOLUME VARIABLES ===
input int volume_lookback = 25; // Number of candles for volume analysis

//=== MARKET SESSION VARIABLES ===
input string asia_open = "00:00"; // Asia Open
input string asia_close = "09:00"; // Asia Close
input string europe_open = "08:00"; // Europe Open
input string europe_close = "17:00"; // Europe Close
input string us_open = "14:30"; // NY Open
input string us_close = "21:00"; // NY Close

// Handlers for EMAs
int ema20handler, ema200handler, ema400handler;
double ema20[], ema200[], ema400[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Configure arrays
   ArraySetAsSeries(ema20, true);
   ArraySetAsSeries(ema200, true);
   ArraySetAsSeries(ema400, true);

   // Create handlers for EMAs
   ema20handler = iMA(_Symbol, _Period, ema20Period, 0, MODE_EMA, PRICE_CLOSE);
   ema200handler = iMA(_Symbol, _Period, ema200Period, 0, MODE_EMA, PRICE_CLOSE);
   ema400handler = iMA(_Symbol, _Period, ema400Period, 0, MODE_EMA, PRICE_CLOSE);

   // Clean previous objects
   ObjectsDeleteAll(0, -1, -1);

   // Create objects once (avoids flickering)
   CreateGraphicObjects();

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Create graphic objects once                                      |
//+------------------------------------------------------------------+
void CreateGraphicObjects()
{
   //=== SESSION AND SIGNAL OBJECTS ===

   // Current session
   ObjectCreate(0, "CURRENT_SESSION", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "CURRENT_SESSION", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "CURRENT_SESSION", OBJPROP_XDISTANCE, 200);
   ObjectSetInteger(0, "CURRENT_SESSION", OBJPROP_YDISTANCE, 10);
   ObjectSetInteger(0, "CURRENT_SESSION", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "CURRENT_SESSION", OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(0, "CURRENT_SESSION", OBJPROP_BACK, false);

   // Current signal
   ObjectCreate(0, "CURRENT_SIGNAL", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "CURRENT_SIGNAL", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "CURRENT_SIGNAL", OBJPROP_XDISTANCE, 200);
   ObjectSetInteger(0, "CURRENT_SIGNAL", OBJPROP_YDISTANCE, 35);
   ObjectSetInteger(0, "CURRENT_SIGNAL", OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, "CURRENT_SIGNAL", OBJPROP_BACK, false);

   //=== EMA VALUES ===

   // EMA20
   ObjectCreate(0, "EMA20_VALUE", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "EMA20_VALUE", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "EMA20_VALUE", OBJPROP_XDISTANCE, 200);
   ObjectSetInteger(0, "EMA20_VALUE", OBJPROP_YDISTANCE, 65);
   ObjectSetInteger(0, "EMA20_VALUE", OBJPROP_COLOR, color_ema20);
   ObjectSetInteger(0, "EMA20_VALUE", OBJPROP_BACK, false);

   // EMA200
   ObjectCreate(0, "EMA200_VALUE", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "EMA200_VALUE", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "EMA200_VALUE", OBJPROP_XDISTANCE, 200);
   ObjectSetInteger(0, "EMA200_VALUE", OBJPROP_YDISTANCE, 85);
   ObjectSetInteger(0, "EMA200_VALUE", OBJPROP_COLOR, color_ema200);
   ObjectSetInteger(0, "EMA200_VALUE", OBJPROP_BACK, false);

   // EMA400
   ObjectCreate(0, "EMA400_VALUE", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "EMA400_VALUE", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "EMA400_VALUE", OBJPROP_XDISTANCE, 200);
   ObjectSetInteger(0, "EMA400_VALUE", OBJPROP_YDISTANCE, 105);
   ObjectSetInteger(0, "EMA400_VALUE", OBJPROP_COLOR, color_ema400);
   ObjectSetInteger(0, "EMA400_VALUE", OBJPROP_BACK, false);

   //=== VOLUME INFORMATION ===

   // Current volume
   ObjectCreate(0, "CURRENT_VOLUME", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "CURRENT_VOLUME", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "CURRENT_VOLUME", OBJPROP_XDISTANCE, 200);
   ObjectSetInteger(0, "CURRENT_VOLUME", OBJPROP_YDISTANCE, 130);
   ObjectSetInteger(0, "CURRENT_VOLUME", OBJPROP_COLOR, clrCyan);
   ObjectSetInteger(0, "CURRENT_VOLUME", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, "CURRENT_VOLUME", OBJPROP_BACK, false);

   // Maximum volume
   ObjectCreate(0, "VOLUME_MAX", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "VOLUME_MAX", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "VOLUME_MAX", OBJPROP_XDISTANCE, 200);
   ObjectSetInteger(0, "VOLUME_MAX", OBJPROP_YDISTANCE, 150);
   ObjectSetInteger(0, "VOLUME_MAX", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "VOLUME_MAX", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, "VOLUME_MAX", OBJPROP_BACK, false);

   // Minimum volume
   ObjectCreate(0, "VOLUME_MIN", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "VOLUME_MIN", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "VOLUME_MIN", OBJPROP_XDISTANCE, 200);
   ObjectSetInteger(0, "VOLUME_MIN", OBJPROP_YDISTANCE, 170);
   ObjectSetInteger(0, "VOLUME_MIN", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "VOLUME_MIN", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, "VOLUME_MIN", OBJPROP_BACK, false);

   //=== LINES LEGEND ===
   ObjectCreate(0, "LEGEND_TITLE", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "LEGEND_TITLE", OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, "LEGEND_TITLE", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "LEGEND_TITLE", OBJPROP_YDISTANCE, 170);
   ObjectSetInteger(0, "LEGEND_TITLE", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "LEGEND_TITLE", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, "LEGEND_TITLE", OBJPROP_BACK, false);
   ObjectSetString(0, "LEGEND_TITLE", OBJPROP_TEXT, "LINES: MAX/MIN PER TIMEFRAME");
}

//+------------------------------------------------------------------+
//| Function to calculate volumes                                    |
//+------------------------------------------------------------------+
void CalculateVolumeLevels(long &currentVol, long &maxVol, long &minVol, string &volumeSignal)
{
   long volumes[];
   ArraySetAsSeries(volumes, true);

   if(CopyTickVolume(_Symbol, _Period, 0, volume_lookback, volumes) < volume_lookback)
   {
      currentVol = 0;
      maxVol = 0;
      minVol = 0;
      volumeSignal = "NO DATA";
      return;
   }

   currentVol = volumes[0];
   maxVol = volumes[0];
   minVol = volumes[0];

   for(int i = 1; i < volume_lookback; i++)
   {
      if(volumes[i] > maxVol) maxVol = volumes[i];
      if(volumes[i] < minVol) minVol = volumes[i];
   }

   double avgVolume = (maxVol + minVol) / 2.0;

   if(currentVol > avgVolume * 1.5)
      volumeSignal = "HIGH VOLUME 📈 - CONFIRMED";
   else if(currentVol < avgVolume * 0.5)
      volumeSignal = "LOW VOLUME 📉 - CAUTION";
   else if(currentVol > avgVolume)
      volumeSignal = "NORMAL VOLUME ✅";
   else
      volumeSignal = "LOW VOLUME ⚠️";
}

//+------------------------------------------------------------------+
//| Function to determine market session                             |
//+------------------------------------------------------------------+
string GetMarketSession()
{
   MqlDateTime current_time;
   TimeCurrent(current_time);

   string current_hour_min = StringFormat("%02d:%02d", current_time.hour, current_time.min);

   if(current_hour_min >= asia_open && current_hour_min < asia_close)
      return "ASIA 🇯🇵";

   else if(current_hour_min >= europe_open && current_hour_min < europe_close)
      return "EUROPE 🇪🇺";

   else if(current_hour_min >= us_open && current_hour_min < us_close)
      return "NEW YORK 🇺🇸";

   else
      return "LOW LIQUIDITY";
}

//+------------------------------------------------------------------+
//| Function to draw maximum and minimum levels                      |
//+------------------------------------------------------------------+
void DrawTimeframeLevels(ENUM_TIMEFRAMES tf, color clr, int offset)
{
   if(!show_max_min) return;

   string tf_name = TimeframeToString(tf);
   string name = "MAX_" + tf_name;
   int period = 100;

   int max_index = iHighest(_Symbol, tf, MODE_HIGH, period, 1);
   int min_index = iLowest(_Symbol, tf, MODE_LOW, period, 1);

   double max_price = iHigh(_Symbol, tf, max_index);
   double min_price = iLow(_Symbol, tf, min_index);

   if(ObjectFind(0, name + "_HIGH") < 0)
   {
      ObjectCreate(0, name + "_HIGH", OBJ_HLINE, 0, 0, max_price);
      ObjectSetInteger(0, name + "_HIGH", OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name + "_HIGH", OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, name + "_HIGH", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name + "_HIGH", OBJPROP_BACK, true);
   }
   else
   {
      ObjectSetDouble(0, name + "_HIGH", OBJPROP_PRICE, max_price);
   }

   if(ObjectFind(0, name + "_LOW") < 0)
   {
      ObjectCreate(0, name + "_LOW", OBJ_HLINE, 0, 0, min_price);
      ObjectSetInteger(0, name + "_LOW", OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name + "_LOW", OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, name + "_LOW", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name + "_LOW", OBJPROP_BACK, true);
   }
   else
   {
      ObjectSetDouble(0, name + "_LOW", OBJPROP_PRICE, min_price);
   }

   if(ObjectFind(0, name + "_LEGEND") < 0)
   {
      ObjectCreate(0, name + "_LEGEND", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name + "_LEGEND", OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, name + "_LEGEND", OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, name + "_LEGEND", OBJPROP_YDISTANCE, 10 + offset * 20);
      ObjectSetInteger(0, name + "_LEGEND", OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name + "_LEGEND", OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, name + "_LEGEND", OBJPROP_BACK, false);
   }

   ObjectSetString(0, name + "_LEGEND", OBJPROP_TEXT, tf_name + " - Max:" + DoubleToString(max_price, _Digits) + " Min:" + DoubleToString(min_price, _Digits));
}

//+------------------------------------------------------------------+
//| Convert timeframe to string                                      |
//+------------------------------------------------------------------+
string TimeframeToString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1: return "M1";
      case PERIOD_M5: return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1: return "H1";
      case PERIOD_H4: return "H4";
      case PERIOD_D1: return "D1";
      case PERIOD_W1: return "W1";
      default: return "TF";
   }
}

//+------------------------------------------------------------------+
//| Check perfect bullish structure (NUEVO con EMA200 y EMA400)      |
//+------------------------------------------------------------------+
bool PerfectBullishStructure()
{
   double current_price = iClose(_Symbol, _Period, 0);

   // Price above EMA20 (entrada)
   bool condition1 = (current_price > ema20[0]);
   
   // Estructura alcista: EMA20 > EMA200 > EMA400
   bool condition2 = (ema20[0] > ema200[0]);
   bool condition3 = (ema200[0] > ema400[0]);

   return (condition1 && condition2 && condition3);
}

//+------------------------------------------------------------------+
//| Check perfect bearish structure (NUEVO con EMA200 y EMA400)      |
//+------------------------------------------------------------------+
bool PerfectBearishStructure()
{
   double current_price = iClose(_Symbol, _Period, 0);

   // Price below EMA20 (entrada)
   bool condition1 = (current_price < ema20[0]);
   
   // Estructura bajista: EMA20 < EMA200 < EMA400
   bool condition2 = (ema20[0] < ema200[0]);
   bool condition3 = (ema200[0] < ema400[0]);

   return (condition1 && condition2 && condition3);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //================== COPY EMA BUFFERS ==================
   if(CopyBuffer(ema20handler, 0, 0, 3, ema20) < 3) return;
   CopyBuffer(ema200handler, 0, 0, 3, ema200);
   CopyBuffer(ema400handler, 0, 0, 3, ema400);

   //================ CALCULATE VOLUME ==============================
   long currentVolume = 0, maxVolume = 0, minVolume = 0;
   string volumeSignal = "";
   CalculateVolumeLevels(currentVolume, maxVolume, minVolume, volumeSignal);

   //================ DETERMINE CURRENT SESSION =====================
   string current_session = GetMarketSession();

   //================ DRAW TIMEFRAME LEVELS ================
   if(show_max_min)
   {
      DrawTimeframeLevels(PERIOD_M1, clrLightGray, 0);
      DrawTimeframeLevels(PERIOD_M5, clrLightBlue, 1);
      DrawTimeframeLevels(PERIOD_M15, clrYellow, 2);
      DrawTimeframeLevels(PERIOD_M30, clrOrange, 3);
      DrawTimeframeLevels(PERIOD_H1, clrGreen, 4);
      DrawTimeframeLevels(PERIOD_H4, clrBlue, 5);
      DrawTimeframeLevels(PERIOD_D1, clrPurple, 6);
      DrawTimeframeLevels(PERIOD_W1, clrRed, 7);
   }

   //=================== CHECK STRUCTURES =====================
   bool perfect_bullish = PerfectBullishStructure();
   bool perfect_bearish = PerfectBearishStructure();

   string signal = "NO TRADE ⏸️";
   color signal_color = clrGray;

   if(perfect_bullish)
   {
      signal = "BUY ✅🚀";
      signal_color = clrLime;
   }
   else if(perfect_bearish)
   {
      signal = "SELL ❌";
      signal_color = clrRed;
   }

   //=================== UPDATE OBJECTS (NO FLICKERING) =======

   ObjectSetString(0, "CURRENT_SESSION", OBJPROP_TEXT, "SESSION: " + current_session);
   ObjectSetString(0, "CURRENT_SIGNAL", OBJPROP_TEXT, "SIGNAL: " + signal);
   ObjectSetInteger(0, "CURRENT_SIGNAL", OBJPROP_COLOR, signal_color);
   ObjectSetString(0, "EMA20_VALUE", OBJPROP_TEXT, "EMA20: " + DoubleToString(ema20[0], _Digits));
   ObjectSetString(0, "EMA200_VALUE", OBJPROP_TEXT, "EMA200: " + DoubleToString(ema200[0], _Digits));
   ObjectSetString(0, "EMA400_VALUE", OBJPROP_TEXT, "EMA400: " + DoubleToString(ema400[0], _Digits));
   ObjectSetString(0, "CURRENT_VOLUME", OBJPROP_TEXT, "CUR VOL: " + IntegerToString(currentVolume) + " - " + volumeSignal);
   ObjectSetString(0, "VOLUME_MAX", OBJPROP_TEXT, "MAX VOL: " + IntegerToString(maxVolume) + " (Last " + IntegerToString(volume_lookback) + " candle" + (volume_lookback > 1 ? "s" : "") + ")");
   ObjectSetString(0, "VOLUME_MIN", OBJPROP_TEXT, "MIN VOL: " + IntegerToString(minVolume));

   //=================== SHOW INFORMATION IN COMMENTS ========
   string comment = "🎯 EPIPHANY 2.0 - MULTI-TIMEFRAME LIQUIDITY SYSTEM\n" +
      "========================================\n" +
      "🌍 SESSION: " + current_session + "\n" +
      "📊 EMA STRUCTURE:\n" +
      "Price > EMA20: " + (iClose(_Symbol, _Period, 0) > ema20[0] ? "✅" : "❌") + "\n" +
      "EMA20 > EMA200: " + (ema20[0] > ema200[0] ? "✅" : "❌") + "\n" +
      "EMA200 > EMA400: " + (ema200[0] > ema400[0] ? "✅" : "❌") + "\n" +
      "========================================\n" +
      "📈 VOLUME ANALYSIS:\n" +
      "Current Volume: " + IntegerToString(currentVolume) + " - " + volumeSignal + "\n" +
      "Maximum Volume: " + IntegerToString(maxVolume) + "\n" +
      "Minimum Volume: " + IntegerToString(minVolume) + "\n" +
      "========================================\n" +
      "🎯 SIGNAL: " + signal + "\n" +
      "========================================\n" +
      "💡 EPIPHANY 2.0 STRATEGY:\n" +
      "• BUY: Price > EMA20 + EMA20 > EMA200 > EMA400 + High Volume\n" +
      "• SELL: Price < EMA20 + EMA20 < EMA200 < EMA400 + High Volume\n" +
      "• NO TRADE: Mixed structure or low volume\n" +
      "• EMA400 = CAMPO GRAVITATORIO PRIMARIO";

   Comment(comment);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, -1, -1);
   Comment("");
}
//+------------------------------------------------------------------+