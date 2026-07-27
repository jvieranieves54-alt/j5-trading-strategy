//+------------------------------------------------------------------+
//|                                  EA-Epiphany-Market-Sessions.mq5 |
//|                                  Copyright 2026, Julio Viera     |
//|                                  Version 7.0 - Con EMA600        |
//+------------------------------------------------------------------+
//| META ADMINISTRATOR (Baruc, el escriba fiel)                      |
//| "Julio, tu balance es X. Tu riesgo del 10% es Y.                 |
//|  Hoy operas conmigo. Dos pérdidas y nos retiramos."              |
//|  ABANICO COMPLETO: 20,40,80,200,400,600                         |
//+------------------------------------------------------------------+
#property copyright "Julio Viera"
#property version   "7.0"
#property strict

enum ENUM_TREND { TREND_ALCISTA, TREND_BAJISTA, TREND_NEUTRAL };

// --- ADMINISTRACIÓN DE CAPITAL (Meta Administrator) ---
input double InpRiskPercent = 10.0;      // Porcentaje de riesgo por operación (10% por defecto)
input int    InpMaxDailyLosses = 2;      // Máximo de pérdidas permitidas por día
input double InpMinRiskReward = 1.0;     // Ratio mínimo Riesgo/Beneficio (1:1)

double g_initialBalance = 0.0;           // Balance al inicio del día
int    g_dailyLosses = 0;                // Pérdidas del día
bool   g_tradingEnabled = true;           // Si se permite operar hoy
datetime g_lastResetDate = 0;             // Fecha del último reset diario

// Handles para EMAs
int g_ma20_handle = INVALID_HANDLE;
int g_ma40_handle = INVALID_HANDLE;
int g_ma80_handle = INVALID_HANDLE;
int g_ma200_handle = INVALID_HANDLE;
int g_ma400_handle = INVALID_HANDLE;
int g_ma600_handle = INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit() 
{ 
   ResetDailyStats();
   
   // Crear handles de EMAs
   g_ma20_handle = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_EMA, PRICE_CLOSE);
   g_ma40_handle = iMA(_Symbol, PERIOD_CURRENT, 40, 0, MODE_EMA, PRICE_CLOSE);
   g_ma80_handle = iMA(_Symbol, PERIOD_CURRENT, 80, 0, MODE_EMA, PRICE_CLOSE);
   g_ma200_handle = iMA(_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
   g_ma400_handle = iMA(_Symbol, PERIOD_CURRENT, 400, 0, MODE_EMA, PRICE_CLOSE);
   g_ma600_handle = iMA(_Symbol, PERIOD_CURRENT, 600, 0, MODE_EMA, PRICE_CLOSE);
   
   if(g_ma20_handle == INVALID_HANDLE || g_ma40_handle == INVALID_HANDLE ||
      g_ma80_handle == INVALID_HANDLE || g_ma200_handle == INVALID_HANDLE ||
      g_ma400_handle == INVALID_HANDLE || g_ma600_handle == INVALID_HANDLE)
   {
      Print("[Error] No se pudieron crear los handles de EMAs");
      return INIT_FAILED;
   }
   
   Print("[Meta Administrator] EMA600 integrada. Abanico completo: 20,40,80,200,400,600");
   return(INIT_SUCCEEDED); 
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
{ 
   ObjectsDeleteAll(0, "Epi_"); 
   ObjectsDeleteAll(0, "Meta_");
   
   if(g_ma20_handle != INVALID_HANDLE) IndicatorRelease(g_ma20_handle);
   if(g_ma40_handle != INVALID_HANDLE) IndicatorRelease(g_ma40_handle);
   if(g_ma80_handle != INVALID_HANDLE) IndicatorRelease(g_ma80_handle);
   if(g_ma200_handle != INVALID_HANDLE) IndicatorRelease(g_ma200_handle);
   if(g_ma400_handle != INVALID_HANDLE) IndicatorRelease(g_ma400_handle);
   if(g_ma600_handle != INVALID_HANDLE) IndicatorRelease(g_ma600_handle);
   
   ChartRedraw(); 
}

//+------------------------------------------------------------------+
void OnTick()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   // Reset diario de estadísticas
   ResetDailyStats();
   
   // --- LÓGICA DE SESIONES ---
   bool isSydney = (dt.hour >= 22 || dt.hour < 7);
   bool isTokyo  = (dt.hour >= 0  && dt.hour < 9);
   bool isLondon = (dt.hour >= 8  && dt.hour < 17);
   bool isNY     = (dt.hour >= 13 && dt.hour < 22);

   // --- CONFIGURACIÓN DE POSICIÓN (ESQUINA SUPERIOR DERECHA) ---
   int x_base = 230;
   int y_base = 40;
   int p_width = 280;

   // 1. RECTÁNGULO DE FONDO
   if(ObjectFind(0, "Epi_Fondo") < 0) ObjectCreate(0, "Epi_Fondo", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "Epi_Fondo", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "Epi_Fondo", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "Epi_Fondo", OBJPROP_YDISTANCE, y_base);
   ObjectSetInteger(0, "Epi_Fondo", OBJPROP_XSIZE, p_width);
   ObjectSetInteger(0, "Epi_Fondo", OBJPROP_YSIZE, 360);
   ObjectSetInteger(0, "Epi_Fondo", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "Epi_Fondo", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "Epi_Fondo", OBJPROP_BACK, false);

   // 2. SESIONES ACTIVAS
   DibujarDerecha("Epi_T", "MERCADOS ACTIVOS", x_base - 20, y_base + 15, clrWhite, 9);
   
   string activas = "";
   if(isSydney) activas += "SIDNEY ";
   if(isTokyo)  activas += "TOKIO ";
   if(isLondon) activas += "LONDRES ";
   if(isNY)     activas += "NY ";
   DibujarDerecha("Epi_Act", activas, x_base - 20, y_base + 35, clrCyan, 9);

   // 3. OVERLAPS
   string overlapMsg = "SOLO UNA SESIÓN";
   color overlapCol = clrGray;
   if(isLondon && isNY) { overlapMsg = "LONDRES + NY"; overlapCol = clrMagenta; }
   else if(isTokyo && isLondon) { overlapMsg = "TOKIO + LONDRES"; overlapCol = clrSpringGreen; }
   else if(isSydney && isTokyo) { overlapMsg = "SIDNEY + TOKIO"; overlapCol = clrDodgerBlue; }
   else if(isSydney && isNY)    { overlapMsg = "NY + SIDNEY"; overlapCol = clrOrange; }
   
   DibujarDerecha("Epi_Over", overlapMsg, x_base - 20, y_base + 60, overlapCol, 10);
   DibujarDerecha("Epi_L", "__________________________", x_base - 20, y_base + 70, clrWhite, 8);

   // 4. TIMEFRAMES EPIPHANY (CON EMA600)
   ENUM_TIMEFRAMES tfs[6] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4};
   string tfNames[6] = {"M1", "M5", "M15", "M30", "H1", "H4"};
   int alcistas = 0, bajistas = 0;

   for(int i=0; i<6; i++)
   {
      ENUM_TREND res = GetTrendFull(tfs[i]);
      string tfTxt = tfNames[i] + ": " + (res==TREND_ALCISTA?"ALCISTA":(res==TREND_BAJISTA?"BAJISTA":"NEUTRAL"));
      color c = (res==TREND_ALCISTA?clrLime:(res==TREND_BAJISTA?clrRed:clrYellow));
      if(res==TREND_ALCISTA) alcistas++; else if(res==TREND_BAJISTA) bajistas++;

      DibujarDerecha("Epi_TF_"+IntegerToString(i), tfTxt, x_base - 20, y_base + 95 + (i * 15), c, 9);
   }

   // 5. RECOMENDACIÓN
   string rec = (alcistas==6?"¡¡BUY!!":(bajistas==6?"¡¡SELL!!":"ESPERAR"));
   color recColor = (alcistas==6?clrLime:(bajistas==6?clrRed:clrWhite));
   DibujarDerecha("Epi_Rec", "ORDEN: " + rec, x_base - 20, y_base + 195, recColor, 10);
   
   // 6. ABANICO INSTITUCIONAL (PANEL DE EMAs)
   DisplayEmaFan(x_base, y_base + 215);
   
   // 7. PANEL DE ADMINISTRACIÓN
   DisplayAdminPanel(x_base, y_base + 310);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| PANEL DE ABANICO INSTITUCIONAL (20,40,80,200,400,600)           |
//+------------------------------------------------------------------+
void DisplayEmaFan(int x_base, int y_base)
{
   // Obtener valores de EMAs en H1
   double price = GetCurrentPrice();
   double e20 = GetMAValue(PERIOD_H1, 20);
   double e40 = GetMAValue(PERIOD_H1, 40);
   double e80 = GetMAValue(PERIOD_H1, 80);
   double e200 = GetMAValue(PERIOD_H1, 200);
   double e400 = GetMAValue(PERIOD_H1, 400);
   double e600 = GetMAValue(PERIOD_H1, 600);
   
   // Verificar abanico ALCISTA
   bool fanAlcista = (price > e20 && e20 > e40 && e40 > e80 && e80 > e200 && e200 > e400 && e400 > e600);
   bool fanBajista = (price < e20 && e20 < e40 && e40 < e80 && e80 < e200 && e200 < e400 && e400 < e600);
   
   string fanText = "";
   color fanColor = clrGray;
   
   if(fanAlcista)
   {
      fanText = "🔺 ABANICO ALCISTA COMPLETO";
      fanColor = clrLime;
   }
   else if(fanBajista)
   {
      fanText = "🔻 ABANICO BAJISTA COMPLETO";
      fanColor = clrRed;
   }
   else
   {
      fanText = "📊 ABANICO INCOMPLETO / TRANSICIÓN";
      fanColor = clrYellow;
   }
   
   DibujarDerecha("Epi_FanTitle", fanText, x_base - 20, y_base + 5, fanColor, 8);
   
   // Dibujar cada EMA con su valor
   string emaTexts[7];
   color emaColors[7];
   emaTexts[0] = "PRECIO: " + DoubleToString(price, 2);
   emaColors[0] = (price > e20 && price > e200) ? clrLime : clrRed;
   
   emaTexts[1] = "EMA20:  " + DoubleToString(e20, 2);
   emaColors[1] = (e20 > e40) ? clrLime : clrRed;
   
   emaTexts[2] = "EMA40:  " + DoubleToString(e40, 2);
   emaColors[2] = (e40 > e80) ? clrLime : clrRed;
   
   emaTexts[3] = "EMA80:  " + DoubleToString(e80, 2);
   emaColors[3] = (e80 > e200) ? clrLime : clrRed;
   
   emaTexts[4] = "EMA200: " + DoubleToString(e200, 2);
   emaColors[4] = (e200 > e400) ? clrLime : clrRed;
   
   emaTexts[5] = "EMA400: " + DoubleToString(e400, 2);
   emaColors[5] = (e400 > e600) ? clrLime : clrRed;
   
   emaTexts[6] = "EMA600: " + DoubleToString(e600, 2);
   emaColors[6] = (e600 > 0) ? clrOrange : clrGray;
   
   for(int i=0; i<7; i++)
   {
      DibujarDerecha("Epi_EMA_"+IntegerToString(i), emaTexts[i], 
                     x_base - 20, y_base + 25 + (i * 14), 
                     emaColors[i], 7);
   }
}

//+------------------------------------------------------------------+
//| FUNCIÓN DE DIBUJO AJUSTADA A LA DERECHA                         |
//+------------------------------------------------------------------+
void DibujarDerecha(string name, string txt, int x, int y, color c, int size)
{
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
}

//+------------------------------------------------------------------+
//| RESET DIARIO DE ESTADÍSTICAS                                     |
//+------------------------------------------------------------------+
void ResetDailyStats()
{
   MqlDateTime now, last;
   TimeToStruct(TimeCurrent(), now);
   TimeToStruct(g_lastResetDate, last);
   
   if(now.day != last.day || now.mon != last.mon || now.year != last.year)
   {
      g_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_dailyLosses = 0;
      g_tradingEnabled = true;
      g_lastResetDate = TimeCurrent();
      Print("[Meta Administrator] Nuevo día. Balance inicial: ", g_initialBalance);
   }
}

//+------------------------------------------------------------------+
//| PANEL DE ADMINISTRACIÓN                                          |
//+------------------------------------------------------------------+
void DisplayAdminPanel(int x_base, int y_base)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double maxRisk = balance * (InpRiskPercent / 100.0);
   double availableRisk = maxRisk * (1.0 - g_dailyLosses / (double)InpMaxDailyLosses);
   
   if(availableRisk < 0) availableRisk = 0;
   
   string adminStatus = "";
   color adminColor = clrWhite;
   
   if(!g_tradingEnabled)
   {
      adminStatus = "BLOQUEADO - LIMITE DIARIO";
      adminColor = clrRed;
   }
   else if(g_dailyLosses == 0)
   {
      adminStatus = "ACTIVO - RIESGO DISPONIBLE";
      adminColor = clrLime;
   }
   else
   {
      adminStatus = "PRECAUCION - " + IntegerToString(g_dailyLosses) + " PERDIDA(S)";
      adminColor = clrYellow;
   }
   
   DibujarDerecha("Epi_Sep", "╔════════════════════════════════╗", x_base - 20, y_base + 5, clrWhite, 7);
   DibujarDerecha("Epi_AdminTitle", "     META ADMINISTRATOR     ", x_base - 20, y_base + 18, clrDodgerBlue, 8);
   DibujarDerecha("Epi_Sep2", "╚════════════════════════════════╝", x_base - 20, y_base + 30, clrWhite, 7);
   
   DibujarDerecha("Meta_Balance", "Balance: $" + DoubleToString(balance, 2), x_base - 20, y_base + 46, clrCyan, 8);
   DibujarDerecha("Meta_Risk10", "10% Riesgo: $" + DoubleToString(maxRisk, 2), x_base - 20, y_base + 60, clrLime, 8);
   DibujarDerecha("Meta_Status", "Estado: " + adminStatus, x_base - 20, y_base + 74, adminColor, 8);
   DibujarDerecha("Meta_Limit", "Limite: " + IntegerToString(g_dailyLosses) + "/" + IntegerToString(InpMaxDailyLosses), x_base - 20, y_base + 88, clrGray, 8);
   
   DibujarDerecha("Meta_Signature", "v7.0 | EMA600 | Baruc", x_base - 20, y_base + 105, clrDarkOrange, 7);
}

//+------------------------------------------------------------------+
//| FUNCIÓN PARA REGISTRAR PÉRDIDAS                                  |
//+------------------------------------------------------------------+
void RegisterLoss()
{
   g_dailyLosses++;
   if(g_dailyLosses >= InpMaxDailyLosses)
   {
      g_tradingEnabled = false;
      Print("[Meta Administrator] LIMITE ALCANZADO. Trading bloqueado hasta mañana.");
   }
   Print("[Meta Administrator] Perdida registrada. Total hoy: ", g_dailyLosses, "/", InpMaxDailyLosses);
}

//+------------------------------------------------------------------+
//| FUNCIÓN PARA REGISTRAR GANANCIAS                                |
//+------------------------------------------------------------------+
void RegisterWin()
{
   Print("[Meta Administrator] Ganancia registrada. Balance: ", AccountInfoDouble(ACCOUNT_BALANCE));
}

//+------------------------------------------------------------------+
//| FUNCIÓN DE VALIDACIÓN DE TRADE                                   |
//+------------------------------------------------------------------+
bool ValidateTrade(double potentialRisk, double potentialReward)
{
   ResetDailyStats();
   
   if(!g_tradingEnabled)
   {
      Print("[Meta Administrator] Trading bloqueado.");
      return false;
   }
   
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double maxRisk = currentBalance * (InpRiskPercent / 100.0);
   
   if(potentialRisk > maxRisk)
   {
      Print("[Meta Administrator] Riesgo excesivo: $", potentialRisk, " > $", maxRisk);
      return false;
   }
   
   if(potentialReward < potentialRisk * InpMinRiskReward)
   {
      Print("[Meta Administrator] Ratio R:R insuficiente");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| FUNCIONES TÉCNICAS CON EMA600                                    |
//+------------------------------------------------------------------+
ENUM_TREND GetTrendFull(ENUM_TIMEFRAMES tf)
{
   double price[1];
   if(CopyClose(_Symbol, tf, 0, 1, price) <= 0) return TREND_NEUTRAL;
   
   double e20 = GetMAValue(tf, 20);
   double e40 = GetMAValue(tf, 40);
   double e80 = GetMAValue(tf, 80);
   double e200 = GetMAValue(tf, 200);
   double e400 = GetMAValue(tf, 400);
   double e600 = GetMAValue(tf, 600);
   
   if(e20 == 0 || e40 == 0 || e80 == 0 || e200 == 0 || e400 == 0 || e600 == 0) 
      return TREND_NEUTRAL;
   
   // ABANICO ALCISTA COMPLETO: Precio > 20 > 40 > 80 > 200 > 400 > 600
   if(price[0] > e20 && e20 > e40 && e40 > e80 && e80 > e200 && e200 > e400 && e400 > e600)
      return TREND_ALCISTA;
   
   // ABANICO BAJISTA COMPLETO: Precio < 20 < 40 < 80 < 200 < 400 < 600
   if(price[0] < e20 && e20 < e40 && e40 < e80 && e80 < e200 && e200 < e400 && e400 < e600)
      return TREND_BAJISTA;
   
   return TREND_NEUTRAL;
}

//+------------------------------------------------------------------+
double GetMAValue(ENUM_TIMEFRAMES tf, int period)
{
   int handle = iMA(_Symbol, tf, period, 0, MODE_EMA, PRICE_CLOSE);
   if(handle == INVALID_HANDLE) return 0;
   double buffer[1];
   if(CopyBuffer(handle, 0, 0, 1, buffer) > 0) 
   { 
      IndicatorRelease(handle); 
      return buffer[0]; 
   }
   IndicatorRelease(handle);
   return 0;
}

//+------------------------------------------------------------------+
double GetCurrentPrice()
{
   MqlTick tick;
   if(SymbolInfoTick(_Symbol, tick)) return tick.bid;
   return 0;
}
//+------------------------------------------------------------------+