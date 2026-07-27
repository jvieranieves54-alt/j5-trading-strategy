//+------------------------------------------------------------------+

//|                                           Epiphany_Dashboard.mq5 |

//|                                         Dashboard Visual para EA |

//|                               Incluye Filtro Anti-Zanahoria (D1) |

//|                             Incluye Medición de Fuerza de EMAs   |

//|                 Incluye HUD Dinámico sobre EMAs (Julio Viera)    |

//|                 Creador: Julio Viera email:jvieranieves54@gmail.com |

//|                 v1.5 - Adaptado para Scalping (20/40/80/200)     |

//+------------------------------------------------------------------+

#property copyright "Epiphany Trading - Julio Viera"

#property version   "1.5"

#property indicator_chart_window

#property indicator_buffers 0

#property indicator_plots   0



// Parámetros (EMAs para Scalping en Oro)

input int emaFast       = 20;      // EMA Rápida (acción inmediata)

input int emaMedium     = 40;      // EMA de Soporte de corto plazo

input int emaSlow       = 80;      // EMA de Tendencia de medio plazo

input int emaVerySlow   = 200;     // EMA Institucional (campo gravitatorio)

input int MomentumPeriod = 7;      // Velas para momentum y pendiente



// Handlers

int hFast, hMedium, hSlow, hVerySlow, hFastDaily;

double bFast[], bMedium[], bSlow[], bVerySlow[], bFastDaily[], closePrices[];



//+------------------------------------------------------------------+

//| FUNCIÓN: DIBUJAR HUD DINÁMICO                                    |

//+------------------------------------------------------------------+

void DrawEmaHUD(string name, double price, string text, color clr)

{

   if(ObjectFind(0, name) < 0)

      ObjectCreate(0, name, OBJ_TEXT, 0, 0, 0);

   

   ObjectMove(0, name, 0, iTime(_Symbol, _Period, 1), price);

   ObjectSetString(0, name, OBJPROP_TEXT, text);

   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);

   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);

   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");

   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT);

   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

}



//+------------------------------------------------------------------+

//| OnInit                                                           |

//+------------------------------------------------------------------+

int OnInit()

{

   ArraySetAsSeries(bFast, true);

   ArraySetAsSeries(bMedium, true);

   ArraySetAsSeries(bSlow, true);

   ArraySetAsSeries(bVerySlow, true);

   ArraySetAsSeries(bFastDaily, true);

   ArraySetAsSeries(closePrices, true);

   

   hFast      = iMA(_Symbol, _Period, emaFast,      0, MODE_EMA, PRICE_CLOSE);

   hMedium    = iMA(_Symbol, _Period, emaMedium,    0, MODE_EMA, PRICE_CLOSE);

   hSlow      = iMA(_Symbol, _Period, emaSlow,      0, MODE_EMA, PRICE_CLOSE);

   hVerySlow  = iMA(_Symbol, _Period, emaVerySlow,  0, MODE_EMA, PRICE_CLOSE);

   hFastDaily = iMA(_Symbol, PERIOD_D1, emaFast,    0, MODE_EMA, PRICE_CLOSE);

   

   if(hFast == INVALID_HANDLE || hMedium == INVALID_HANDLE || hSlow == INVALID_HANDLE || hVerySlow == INVALID_HANDLE || hFastDaily == INVALID_HANDLE)

      return(INIT_FAILED);

   

   return(INIT_SUCCEEDED);

}



//+------------------------------------------------------------------+

//| Funciones de Cálculo                                             |

//+------------------------------------------------------------------+

double CalculateSlope(double &buffer[], int period, double &slopePerCandle)

{

   if(ArraySize(buffer) < period + 2) return 0;

   slopePerCandle = (buffer[1] - buffer[period + 1]) / period;

   return slopePerCandle;

}



string ClassifyTrendStrength(double slope)

{

   double absSlope = MathAbs(slope);

   string strength = "";

   if(absSlope < 0.5) strength = "DÉBIL ⚪";

   else if(absSlope < 1.5) strength = "MODERADA 🟡";

   else if(absSlope < 3.0) strength = "FUERTE 🟢";

   else strength = "MUY FUERTE 🔴";

   

   if(slope > 0) strength = "ALCISTA ↑ " + strength;

   else if(slope < 0) strength = "BAJISTA ↓ " + strength;

   else strength = "PLANA → " + strength;

   return strength;

}



//+------------------------------------------------------------------+

//| OnCalculate                                                      |

//+------------------------------------------------------------------+

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],

                const double &open[], const double &high[], const double &low[],

                const double &close[], const long &tick_volume[], const long &volume[],

                const int &spread[])

{

   int requiredBars = MomentumPeriod + 10;

   if(CopyBuffer(hFast, 0, 0, requiredBars, bFast) < requiredBars) return(0);

   if(CopyBuffer(hMedium, 0, 0, requiredBars, bMedium) < requiredBars) return(0);

   if(CopyBuffer(hSlow, 0, 0, requiredBars, bSlow) < requiredBars) return(0);

   if(CopyBuffer(hVerySlow, 0, 0, requiredBars, bVerySlow) < requiredBars) return(0);

   if(CopyClose(_Symbol, _Period, 0, requiredBars+1, closePrices) < requiredBars+1) return(0);

   if(CopyBuffer(hFastDaily, 0, 0, 2, bFastDaily) < 2) return(0);

   

   double dailyCloseArray[];

   ArraySetAsSeries(dailyCloseArray, true);

   if(CopyClose(_Symbol, PERIOD_D1, 0, 1, dailyCloseArray) < 1) return(0);

   double dailyClose = dailyCloseArray[0];

   

   double sFast, sMedium, sSlow, sVerySlow;

   CalculateSlope(bFast, MomentumPeriod, sFast);

   CalculateSlope(bMedium, MomentumPeriod, sMedium);

   CalculateSlope(bSlow, MomentumPeriod, sSlow);

   CalculateSlope(bVerySlow, MomentumPeriod, sVerySlow);

   

   string strFast = ClassifyTrendStrength(sFast);

   string strMedium = ClassifyTrendStrength(sMedium);

   string strSlow = ClassifyTrendStrength(sSlow);

   string strVerySlow = ClassifyTrendStrength(sVerySlow);

   

   // --- DATA DE PRECIO PARA HUD ---

   double currentP = closePrices[0];

   double pastP = closePrices[MomentumPeriod];

   double diffP = currentP - pastP;

   double diffPerc = (diffP / pastP) * 100;

   string pDir = (diffP > 0) ? "ALCISTA ↑" : (diffP < 0 ? "BAJISTA ↓" : "LATERAL →");

   

   // DIBUJAR HUD EN LÍNEAS (sobre el precio)

   DrawEmaHUD("HUD_FAST",     bFast[1],     "  ◄ [20] " + strFast,     (sFast > 0 ? clrLime : clrRed));

   DrawEmaHUD("HUD_MEDIUM",   bMedium[1],   "  ◄ [40] " + strMedium,   (sMedium > 0 ? clrCyan : clrOrangeRed));

   DrawEmaHUD("HUD_SLOW",     bSlow[1],     "  ◄ [80] " + strSlow,     (sSlow > 0 ? clrGold : clrTomato));

   DrawEmaHUD("HUD_VERYSLOW", bVerySlow[1], "  ◄ [200] " + strVerySlow, (sVerySlow > 0 ? clrDodgerBlue : clrMagenta));

   DrawEmaHUD("HUD_PRICE",    currentP,     "  ◄ PRICE: " + DoubleToString(diffP, _Digits) + " pts (" + DoubleToString(diffPerc, 2) + "%) " + pDir, clrWhite);

   

   // LÓGICA DASHBOARD (CUADRO IZQUIERDA)

   bool dailyAllowBuy  = (dailyClose > bFastDaily[1]);

   bool dailyAllowSell = (dailyClose < bFastDaily[1]);

   string dailyStatus = dailyAllowBuy ? "COMPRAS PERMITIDAS ✅ (D1 > EMA20)" : (dailyAllowSell ? "VENTAS PERMITIDAS ❌ (D1 < EMA20)" : "NEUTRO ⚪");

   

   bool isBullFan = (bFast[1] > bMedium[1] && bMedium[1] > bSlow[1] && bSlow[1] > bVerySlow[1]);

   bool isBearFan = (bFast[1] < bMedium[1] && bMedium[1] < bSlow[1] && bSlow[1] < bVerySlow[1]);

   

   string entry = "NO";

   if(isBullFan && currentP > pastP && close[rates_total-1] > bFast[1] && dailyAllowBuy)

      entry = "BUY ✅ (CON filtro D1)";

   if(isBearFan && currentP < pastP && close[rates_total-1] < bFast[1] && dailyAllowSell)

      entry = "SELL ❌ (CON filtro D1)";

 //  

   Comment("╔══════════════════════════════════════════════════════════════════════════════════════════╗\n" +

           "║                    🎯 EPIPHANY DASHBOARD v1.5 (SCALPER) - " + _Symbol + "                     ║\n" +

           "╠══════════════════════════════════════════════════════════════════════════════════════════╣\n" +

           "║                                                                                          ║\n" +

           "║  📊 TIMEFRAME ACTUAL (" + EnumToString(_Period) + ")                                             ║\n" +

           "║  ─────────────────────────────────────────────────────────────────────────────────────── ║\n" +

           "║                                                                                          ║\n" +

           "║  📈 PATRÓN DE EMAs: " + (isBullFan ? "ABANICO ALCISTA 📈" : (isBearFan ? "ABANICO BAJISTA 📉" : "DESORDENADAS ⚠️")) + "                    ║\n" +

           "║                                                                                          ║\n" +

           "║  📉 ANÁLISIS DE PENDIENTE (últimas " + IntegerToString(MomentumPeriod) + " velas):                                ║\n" +

           "║       EMA20:  " + DoubleToString(bFast[1], _Digits) + "  |  Pendiente: " + strFast + "                           ║\n" +

           "║       EMA40:  " + DoubleToString(bMedium[1], _Digits) + "  |  Pendiente: " + strMedium + "                          ║\n" +

           "║       EMA80:  " + DoubleToString(bSlow[1], _Digits) + "  |  Pendiente: " + strSlow + "                           ║\n" +

           "║       EMA200: " + DoubleToString(bVerySlow[1], _Digits) + "  |  Pendiente: " + strVerySlow + "                         ║\n" +

           "║                                                                                          ║\n" +

           "║  💰 PRECIO vs PRECIO HACE " + IntegerToString(MomentumPeriod) + " VELAS:                                     ║\n" +

           "║       Precio actual: " + DoubleToString(currentP, _Digits) + "  |  Precio hace " + IntegerToString(MomentumPeriod) + ": " + DoubleToString(pastP, _Digits) + "         ║\n" +

           "║       Diferencia: " + DoubleToString(diffP, _Digits) + " pts (" + DoubleToString(diffPerc, 2) + "%) — " + pDir + "                       ║\n" +

           "║                                                                                          ║\n" +

           "║  🛡️ FILTRO ANTI-ZANAHORIA (DIARIO)                                                       ║\n" +

           "║  ─────────────────────────────────────────────────────────────────────────────────────── ║\n" +

           "║  " + dailyStatus + "                                                  ║\n" +

           "║  PRECIO D1: " + DoubleToString(dailyClose, _Digits) + "  |  EMA20 D1: " + DoubleToString(bFastDaily[1], _Digits) + "                                     ║\n" +

           "║                                                                                          ║\n" +

           "║  🎯 CONDICIÓN DE ENTRADA REAL (EA con filtro D1)                                            ║\n" +

           "║  ─────────────────────────────────────────────────────────────────────────────────────── ║\n" +

           "║  ▶ " + entry + "                                                                  ║\n" +

           "║                                                                                          ║\n" +

           "║  📈 POSICIONES ABIERTAS: " + IntegerToString(PositionsTotal()) + "                                                        ║\n" +

           "║                                                                                          ║\n" +

           "║  💰 BALANCE: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "                                                            ║\n" +

           "║                                                                                          ║\n" +

           "╚══════════════════════════════════════════════════════════════════════════════════════════╝");

   

   return(rates_total);

}
//


void OnDeinit(const int reason)

{

   Comment("");

   ObjectDelete(0, "HUD_FAST");

   ObjectDelete(0, "HUD_MEDIUM");

   ObjectDelete(0, "HUD_SLOW");

   ObjectDelete(0, "HUD_VERYSLOW");

   ObjectDelete(0, "HUD_PRICE");

} 

