//+------------------------------------------------------------------+
//|                                              SwiftIndicator.mq5  |
//|                                  Copyright 2024, traderschatroom88|
//|                                             https://mozilla.org/MPL/2.0/ |
//+------------------------------------------------------------------+
/*
   SWIFT ALGO ULTIMATE - Optimized Rebuild
   Based on complete logic by traderschatroom88.
*/

#property copyright "Copyright 2024, traderschatroom88"
#property link      "https://mozilla.org/MPL/2.0/"
#property version   "9.00"
#property indicator_chart_window
#property indicator_buffers 20
#property indicator_plots   7

//--- Plots
#property indicator_label1  "Buy Signal"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrGreen

#property indicator_label2  "Sell Signal"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed

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

#property indicator_label7  "KC Lower"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrGray

//--- Buffers
double B_Buy[], B_Sell[];
double B_CandleO[], B_CandleH[], B_CandleL[], B_CandleC[], B_CandleColor[];
double B_SwingH[], B_SwingL[];
double B_KCU[], B_KCL[];
double B_CMA[], B_OMA[], B_ATR[], B_HAOpen[], B_HAClose[], B_Temp1[], B_Temp2[];

//--- Enum
enum ENUM_MA_PORT { MODE_SMA, MODE_EMA, MODE_HULL, MODE_ALMA };

//--- Inputs
input group "MAIN"
input ENUM_MA_PORT InpMaType         = MODE_ALMA;
input int          InpMaPeriod       = 2;
input bool         InpUseMult        = true;
input int          InpMult           = 8;
input double       InpALMA_Off       = 0.85;
input int          InpALMA_Sig       = 5;

input group "LOGIC"
input int          InpSwing          = 10;
input double       InpBox            = 2.5;

//--- Globals
int h_atr;

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit() {
   SetIndexBuffer(0, B_Buy); SetIndexBuffer(1, B_Sell);
   SetIndexBuffer(2, B_CandleO); SetIndexBuffer(3, B_CandleH);
   SetIndexBuffer(4, B_CandleL); SetIndexBuffer(5, B_CandleC);
   SetIndexBuffer(6, B_CandleColor, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(7, B_SwingH); SetIndexBuffer(8, B_SwingL);
   SetIndexBuffer(9, B_KCU); SetIndexBuffer(10, B_KCL);

   SetIndexBuffer(11, B_CMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(12, B_OMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, B_ATR, INDICATOR_CALCULATIONS);
   SetIndexBuffer(14, B_HAOpen, INDICATOR_CALCULATIONS);
   SetIndexBuffer(15, B_HAClose, INDICATOR_CALCULATIONS);
   SetIndexBuffer(16, B_Temp1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(17, B_Temp2, INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0, PLOT_ARROW, 233);
   PlotIndexSetInteger(1, PLOT_ARROW, 234);
   PlotIndexSetInteger(3, PLOT_ARROW, 119);
   PlotIndexSetInteger(4, PLOT_ARROW, 119);

   h_atr = iATR(_Symbol, _Period, 50);
   return(INIT_SUCCEEDED);
}

//--- Helper Calc
double calcSMA(const double &s[], int i, int l) { if(i<l-1) return s[i]; double v=0; for(int k=0; k<l; k++) v+=s[i-k]; return v/l; }
double calcWMA(const double &s[], int i, int l) { if(i<l-1) return s[i]; double v=0, w=0; for(int k=0; k<l; k++) { double wt=l-k; v+=s[i-k]*wt; w+=wt; } return v/w; }
double calcALMA(const double &s[], int i, int l, double o, double sig) { if(i<l-1) return s[i]; double m=o*(l-1), st=l/sig, v=0, w=0; for(int k=0; k<l; k++) { double wt=MathExp(-MathPow(k-m,2)/(2*MathPow(st,2))); v+=s[i-(l-1-k)]*wt; w+=wt; } return w!=0?v/w:s[i]; }

//+------------------------------------------------------------------+
//| OnCalculate                                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]) {
   int len = InpMaPeriod; if(InpUseMult) len *= InpMult;
   if(rates_total < 100) return 0;
   CopyBuffer(h_atr, 0, 0, rates_total, B_ATR);

   int start = prev_calculated - 1; if(start < 1) { start = 1; B_HAOpen[0]=open[0]; B_HAClose[0]=close[0]; }

   for(int i=start; i<rates_total; i++) {
      B_HAClose[i] = (open[i] + high[i] + low[i] + close[i]) / 4.0;
      B_HAOpen[i] = (B_HAOpen[i-1] + B_HAClose[i-1]) / 2.0;

      if(InpMaType == MODE_ALMA) {
         B_CMA[i] = calcALMA(close, i, len, InpALMA_Off, (double)InpALMA_Sig);
         B_OMA[i] = calcALMA(open, i, len, InpALMA_Off, (double)InpALMA_Sig);
      } else if(InpMaType == MODE_HULL) {
         B_Temp1[i] = 2.0 * calcWMA(close, i, len/2) - calcWMA(close, i, len);
         B_CMA[i] = calcWMA(B_Temp1, i, (int)MathSqrt(len));
         B_Temp2[i] = 2.0 * calcWMA(open, i, len/2) - calcWMA(open, i, len);
         B_OMA[i] = calcWMA(B_Temp2, i, (int)MathSqrt(len));
      } else {
         B_CMA[i] = calcSMA(close, i, len);
         B_OMA[i] = calcSMA(open, i, len);
      }

      B_Buy[i] = B_Sell[i] = EMPTY_VALUE;
      if(i > 0) {
         if(B_CMA[i] > B_OMA[i] && B_CMA[i-1] <= B_OMA[i-1]) B_Buy[i] = low[i] - B_ATR[i]*0.5;
         if(B_CMA[i] < B_OMA[i] && B_CMA[i-1] >= B_OMA[i-1]) B_Sell[i] = high[i] + B_ATR[i]*0.5;
         B_CandleO[i]=open[i]; B_CandleH[i]=high[i]; B_CandleL[i]=low[i]; B_CandleC[i]=close[i]; B_CandleColor[i]=(B_CMA[i]>B_OMA[i])?0:1;
      }

      B_SwingH[i]=B_SwingL[i]=EMPTY_VALUE;
      if(i >= InpSwing && i < rates_total - InpSwing) {
         bool isH=true, isL=true; for(int j=1; j<=InpSwing; j++) { if(high[i]<high[i-j] || high[i]<high[i+j]) isH=false; if(low[i]>low[i-j] || low[i]>low[i+j]) isL=false; }
         if(isH) B_SwingH[i]=high[i]; if(isL) B_SwingL[i]=low[i];
      }

      double b = calcSMA(close, i, 20); B_KCU[i] = b + 1.5 * B_ATR[i]; B_KCL[i] = b - 1.5 * B_ATR[i];
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
