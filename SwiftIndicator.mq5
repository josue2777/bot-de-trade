//+------------------------------------------------------------------+
//|                                              SwiftIndicator.mq5  |
//|                                  Copyright 2024, traderschatroom88|
//|                                             https://mozilla.org/MPL/2.0/ |
//+------------------------------------------------------------------+
/*
   SWIFT ALGO Indicator for MQL5
   Based on Pine Script logic by traderschatroom88.
*/

#property copyright "Copyright 2024, traderschatroom88"
#property link      "https://mozilla.org/MPL/2.0/"
#property version   "2.10"
#property indicator_chart_window
#property indicator_buffers 20
#property indicator_plots   7

//--- plots
#property indicator_label1  "Buy Signal"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrGreen
#property indicator_width1  2

#property indicator_label2  "Sell Signal"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  2

#property indicator_label3  "Trend Color"
#property indicator_type3   DRAW_COLOR_CANDLES
#property indicator_color3  clrPurple, clrSkyBlue

#property indicator_label4  "Swing High"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrWhite

#property indicator_label5  "Swing Low"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrWhite

#property indicator_label6  "KC Upper"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrGray
#property indicator_style6  STYLE_DOT

#property indicator_label7  "KC Lower"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrGray
#property indicator_style7  STYLE_DOT

//--- Buffers
double BufferBuy[], BufferSell[], BufferCandleOpen[], BufferCandleHigh[], BufferCandleLow[], BufferCandleClose[], BufferColor[];
double BufferSwingHigh[], BufferSwingLow[], BufferKCUpper[], BufferKCLower[];
double BufferCloseMA[], BufferOpenMA[], BufferHAOpen[], BufferHAClose[], BufferTempHull1[], BufferTempHull2[], BufferATR[];

//--- Structures
struct Zone {
   double top;
   double bottom;
   datetime startTime;
   bool active;
   string name;
};

Zone zonesSupply[50], zonesDemand[50];
int supplyCount = 0, demandCount = 0;

//--- Enumerations
enum ENUM_MA_TYPE { MA_TEMA, MA_HULL, MA_ALMA };

//--- Inputs
input ENUM_MA_TYPE    InpMaType        = MA_ALMA;     // MA Type
input int             InpMaPeriod      = 2;           // MA Period
input int             InpOffsetSigma   = 5;           // Offset for ALMA
input double          InpOffsetALMA    = 0.85;        // Offset for ALMA
input bool            InpUseAltSignals = true;        // MTF Simulation
input int             InpMultiplier    = 8;           // Multiplier
input int             InpDelayOffset   = 0;           // Delay
input bool            InpShowBarColor  = true;        // Show Bar Color
input int             InpSwingLength   = 10;          // Swing Length
input double          InpBoxWidth      = 2.5;         // Zone Width (ATR Multiplier)
input bool            InpShowZones     = true;        // Show Zones
input bool            InpShowBOS       = true;        // Show BOS
input bool            InpUseHeikinAshi = false;       // Use Heikin Ashi for signals?

//--- Global Handles
int handleTEMA_Close, handleTEMA_Open, handleATR;

int OnInit() {
   int length = InpMaPeriod;
   if(InpUseAltSignals) length *= InpMultiplier;

   SetIndexBuffer(0, BufferBuy); SetIndexBuffer(1, BufferSell);
   SetIndexBuffer(2, BufferCandleOpen); SetIndexBuffer(3, BufferCandleHigh);
   SetIndexBuffer(4, BufferCandleLow); SetIndexBuffer(5, BufferCandleClose);
   SetIndexBuffer(6, BufferColor, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(7, BufferSwingHigh); SetIndexBuffer(8, BufferSwingLow);
   SetIndexBuffer(9, BufferKCUpper); SetIndexBuffer(10, BufferKCLower);

   SetIndexBuffer(11, BufferCloseMA, INDICATOR_CALCULATIONS); SetIndexBuffer(12, BufferOpenMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, BufferHAOpen, INDICATOR_CALCULATIONS); SetIndexBuffer(14, BufferHAClose, INDICATOR_CALCULATIONS);
   SetIndexBuffer(15, BufferTempHull1, INDICATOR_CALCULATIONS); SetIndexBuffer(16, BufferTempHull2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(17, BufferATR, INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0, PLOT_ARROW, 233); PlotIndexSetInteger(1, PLOT_ARROW, 234);
   PlotIndexSetInteger(3, PLOT_ARROW, 119); PlotIndexSetInteger(4, PLOT_ARROW, 119);

   handleATR = iATR(_Symbol, _Period, 50);
   if(InpMaType == MA_TEMA) {
      handleTEMA_Close = iTEMA(_Symbol, _Period, length, 0, PRICE_CLOSE);
      handleTEMA_Open  = iTEMA(_Symbol, _Period, length, 0, PRICE_OPEN);
   }
   return(INIT_SUCCEEDED);
}

double CalculateALMA(const double &src[], int index, int length, double offset, double sigma) {
   if(index < length - 1) return(src[index]);
   double m = offset * (length - 1.0), s = (double)length / sigma, w_sum = 0, v_sum = 0;
   for(int i = 0; i < length; i++) {
      double w = MathExp(-MathPow(i - m, 2.0) / (2.0 * MathPow(s, 2.0)));
      v_sum += src[index - (length - 1 - i)] * w; w_sum += w;
   }
   return(w_sum != 0 ? v_sum / w_sum : src[index]);
}

double CalculateWMA(const double &src[], int index, int length) {
   if(index < length - 1 || length < 1) return(src[index]);
   double w_sum = 0, v_sum = 0;
   for(int i = 0; i < length; i++) { double w = length - i; v_sum += src[index - i] * w; w_sum += w; }
   return(v_sum / w_sum);
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]) {
   int length = InpMaPeriod; if(InpUseAltSignals) length *= InpMultiplier;
   if(rates_total < 50) return(0);

   if(CopyBuffer(handleATR, 0, 0, rates_total, BufferATR) <= 0) return(0);

   int start = prev_calculated - 1;
   if(start < 1) { start = 1; BufferHAOpen[0] = open[0]; BufferHAClose[0] = close[0]; }

   for(int i = start; i < rates_total; i++) {
      BufferHAClose[i] = (open[i] + high[i] + low[i] + close[i]) / 4.0;
      BufferHAOpen[i]  = (BufferHAOpen[i-1] + BufferHAClose[i-1]) / 2.0;
   }

   if(InpMaType == MA_TEMA) {
      double tC[], tO[];
      if(CopyBuffer(handleTEMA_Close, 0, 0, rates_total, tC) > 0 && CopyBuffer(handleTEMA_Open, 0, 0, rates_total, tO) > 0) {
         for(int i = start; i < rates_total; i++) { BufferCloseMA[i] = tC[i]; BufferOpenMA[i] = tO[i]; }
      }
   }

   for(int i = start; i < rates_total; i++) {
      int idx = i - InpDelayOffset; if(idx < 0) idx = 0;
      const double &sC = InpUseHeikinAshi ? BufferHAClose : close;
      const double &sO = InpUseHeikinAshi ? BufferHAOpen : open;

      if(InpMaType == MA_ALMA) {
         BufferCloseMA[i] = CalculateALMA(sC, idx, length, InpOffsetALMA, (double)InpOffsetSigma);
         BufferOpenMA[i]  = CalculateALMA(sO, idx, length, InpOffsetALMA, (double)InpOffsetSigma);
      } else if(InpMaType == MA_HULL) {
         BufferTempHull1[i] = 2.0 * CalculateWMA(sC, idx, length/2) - CalculateWMA(sC, idx, length);
         BufferCloseMA[i] = CalculateWMA(BufferTempHull1, i, (int)MathSqrt(length));
         BufferTempHull2[i] = 2.0 * CalculateWMA(sO, idx, length/2) - CalculateWMA(sO, idx, length);
         BufferOpenMA[i] = CalculateWMA(BufferTempHull2, i, (int)MathSqrt(length));
      }

      BufferBuy[i] = BufferSell[i] = BufferSwingHigh[i] = BufferSwingLow[i] = EMPTY_VALUE;

      //--- KC
      double basis = CalculateWMA(close, i, 20);
      BufferKCUpper[i] = basis + BufferATR[i] * 1.5;
      BufferKCLower[i] = basis - BufferATR[i] * 1.5;

      if(i >= InpSwingLength && i < rates_total - InpSwingLength) {
         bool isH = true, isL = true;
         for(int j = 1; j <= InpSwingLength; j++) {
            if(high[i] < high[i-j] || high[i] < high[i+j]) isH = false;
            if(low[i] > low[i-j] || low[i] > low[i+j]) isL = false;
         }
         if(isH) {
            BufferSwingHigh[i] = high[i];
            if(InpShowZones && i >= rates_total - 300) {
               string n = "Supply_"+IntegerToString(i);
               double bw = BufferATR[i] * (InpBoxWidth / 10.0);
               ObjectCreate(0, n, OBJ_RECTANGLE, 0, time[i], high[i], time[rates_total-1], high[i]-bw);
               ObjectSetInteger(0, n, OBJPROP_COLOR, clrRed); ObjectSetInteger(0, n, OBJPROP_BACK, true);
               if(supplyCount < 50) { zonesSupply[supplyCount].top = high[i]; zonesSupply[supplyCount].bottom = high[i]-bw; zonesSupply[supplyCount].active = true; zonesSupply[supplyCount].name = n; supplyCount++; }
            }
         }
         if(isL) {
            BufferSwingLow[i] = low[i];
            if(InpShowZones && i >= rates_total - 300) {
               string n = "Demand_"+IntegerToString(i);
               double bw = BufferATR[i] * (InpBoxWidth / 10.0);
               ObjectCreate(0, n, OBJ_RECTANGLE, 0, time[i], low[i], time[rates_total-1], low[i]+bw);
               ObjectSetInteger(0, n, OBJPROP_COLOR, clrGreen); ObjectSetInteger(0, n, OBJPROP_BACK, true);
               if(demandCount < 50) { zonesDemand[demandCount].top = low[i]+bw; zonesDemand[demandCount].bottom = low[i]; zonesDemand[demandCount].active = true; zonesDemand[demandCount].name = n; demandCount++; }
            }
         }
      }

      //--- BOS Optimized
      if(InpShowBOS) {
         for(int k=0; k<supplyCount; k++) { if(zonesSupply[k].active && close[i] > zonesSupply[k].top) { ObjectSetInteger(0, zonesSupply[k].name, OBJPROP_COLOR, clrOrange); zonesSupply[k].active = false; } }
         for(int k=0; k<demandCount; k++) { if(zonesDemand[k].active && close[i] < zonesDemand[k].bottom) { ObjectSetInteger(0, zonesDemand[k].name, OBJPROP_COLOR, clrOrange); zonesDemand[k].active = false; } }
      }

      if(i > 0) {
         if(BufferCloseMA[i] > BufferOpenMA[i] && BufferCloseMA[i-1] <= BufferOpenMA[i-1]) BufferBuy[i] = low[i] - 10 * _Point;
         else if(BufferCloseMA[i] < BufferOpenMA[i] && BufferCloseMA[i-1] >= BufferOpenMA[i-1]) BufferSell[i] = high[i] + 10 * _Point;
         if(InpShowBarColor) { BufferCandleOpen[i] = open[i]; BufferCandleHigh[i] = high[i]; BufferCandleLow[i] = low[i]; BufferCandleClose[i] = close[i]; BufferColor[i] = (BufferCloseMA[i] > BufferOpenMA[i]) ? 0 : 1; }
      }
   }
   return(rates_total);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, "Supply_"); ObjectsDeleteAll(0, "Demand_"); }
//+------------------------------------------------------------------+
