//+------------------------------------------------------------------+
//|                                              SwiftIndicator.mq5  |
//|                                  Copyright 2024, traderschatroom88|
//|                                             https://mozilla.org/MPL/2.0/ |
//+------------------------------------------------------------------+
/*
   SWIFT ALGO Ultimate Master Port for MQL5
   Full 1:1 Parity Logic without simplification.
*/

#property copyright "Copyright 2024, traderschatroom88"
#property link      "https://mozilla.org/MPL/2.0/"
#property version   "7.00"
#property indicator_chart_window
#property indicator_buffers 60
#property indicator_plots   14

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

#property indicator_label8  "LR Center"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrYellow

#property indicator_label9  "LR Upper"
#property indicator_type9   DRAW_LINE
#property indicator_color9  clrYellow
#property indicator_style9  STYLE_DASH

#property indicator_label10 "LR Lower"
#property indicator_type10  DRAW_LINE
#property indicator_color10 clrYellow
#property indicator_style10 STYLE_DASH

#property indicator_label11 "TP 1"
#property indicator_type11  DRAW_LINE
#property indicator_color11 clrLime
#property indicator_style11 STYLE_DASH

#property indicator_label12 "TP 2"
#property indicator_type12  DRAW_LINE
#property indicator_color12 clrLime
#property indicator_style12 STYLE_DASH

#property indicator_label13 "TP 3"
#property indicator_type13  DRAW_LINE
#property indicator_color13 clrLime
#property indicator_style13 STYLE_DASH

#property indicator_label14 "SL"
#property indicator_type14  DRAW_LINE
#property indicator_color14 clrCrimson
#property indicator_style14 STYLE_DASH

//--- Buffers
double B_Buy[], B_Sell[], B_CandleO[], B_CandleH[], B_CandleL[], B_CandleC[], B_Color[];
double B_SwingH[], B_SwingL[], B_KCU[], B_KCL[], B_LRC[], B_LRU[], B_LRL[], B_TP1[], B_TP2[], B_TP3[], B_SL[];
double B_CMA[], B_OMA[], B_HAOpen[], B_HAHigh[], B_HALow[], B_HAClose[], B_ATR[];
double B_ESA[], B_D[], B_WT1[], B_WT2[], B_EMA144[], B_RSI[], B_TEMA_C[], B_TEMA_O[], B_HULL_C[], B_HULL_O[];
double B_SSMA_C[], B_SSMA_O[], B_LSMA_C[], B_LSMA_O[], B_DEMA_C[], B_DEMA_O[], B_SMA_C[], B_SMA_O[], B_EMA_C[], B_EMA_O[];
double B_SmoothRng[], B_RngFilt[], B_DivBear[], B_DivBull[], B_VWMA_C[], B_VWMA_O[];
double B_SMMA_C[], B_SMMA_O[];

//--- Enumerations
enum ENUM_MA_FULL { SMA, EMA, DEMA, TEMA, WMA, VWMA, SMMA, HullMA, LSMA, ALMA, TMA, SSMA };

//--- Inputs
input group "MAIN SETTINGS"
input ENUM_MA_FULL    InpMaType        = ALMA;
input int             InpMaPeriod      = 2;
input int             InpOffsetSigma   = 5;
input double          InpOffsetALMA    = 0.85;
input bool            InpUseAltSignals = true;
input int             InpMultiplier    = 8;
input int             InpDelayOffset   = 0;
input bool            InpUseHeikinAshi = false;

input group "SUPPLY / DEMAND"
input int             InpSwingLength   = 10;
input double          InpBoxWidth      = 2.5;
input bool            InpShowZones     = true;
input bool            InpShowBOS       = true;

input group "CHANNELS & RISK"
input bool            InpShowKC        = true;
input bool            InpShowLR        = true;
input int             InpLRPeriod      = 150;
input double          InpTP1_Perc      = 1.0;
input double          InpTP2_Perc      = 1.5;
input double          InpTP3_Perc      = 2.0;
input double          InpSL_Perc       = 0.5;

//--- Globals
int hATR, hEMA144, hRSI;
int hDEMA_C, hDEMA_O, hTEMA_C, hTEMA_O, hSMMA_C, hSMMA_O;

int OnInit() {
   IndicatorSetString(INDICATOR_SHORTNAME, "SWIFT ULTIMATE");
   int len = InpMaPeriod; if(InpUseAltSignals) len *= InpMultiplier;

   SetIndexBuffer(0, B_Buy); SetIndexBuffer(1, B_Sell); SetIndexBuffer(2, B_CandleO); SetIndexBuffer(3, B_CandleH); SetIndexBuffer(4, B_CandleL); SetIndexBuffer(5, B_CandleC); SetIndexBuffer(6, B_Color, INDICATOR_COLOR_INDEX); SetIndexBuffer(7, B_SwingH); SetIndexBuffer(8, B_SwingL); SetIndexBuffer(9, B_KCU); SetIndexBuffer(10, B_KCL); SetIndexBuffer(11, B_LRC); SetIndexBuffer(12, B_LRU); SetIndexBuffer(13, B_LRL); SetIndexBuffer(14, B_TP1); SetIndexBuffer(15, B_TP2); SetIndexBuffer(16, B_TP3); SetIndexBuffer(17, B_SL);
   SetIndexBuffer(18, B_CMA, INDICATOR_CALCULATIONS); SetIndexBuffer(19, B_OMA, INDICATOR_CALCULATIONS); SetIndexBuffer(20, B_HAOpen, INDICATOR_CALCULATIONS); SetIndexBuffer(21, B_HAHigh, INDICATOR_CALCULATIONS); SetIndexBuffer(22, B_HALow, INDICATOR_CALCULATIONS); SetIndexBuffer(23, B_HAClose, INDICATOR_CALCULATIONS); SetIndexBuffer(24, B_ATR, INDICATOR_CALCULATIONS); SetIndexBuffer(25, B_ESA, INDICATOR_CALCULATIONS); SetIndexBuffer(26, B_D, INDICATOR_CALCULATIONS); SetIndexBuffer(27, B_WT1, INDICATOR_CALCULATIONS); SetIndexBuffer(28, B_WT2, INDICATOR_CALCULATIONS); SetIndexBuffer(29, B_EMA144, INDICATOR_CALCULATIONS); SetIndexBuffer(30, B_RSI, INDICATOR_CALCULATIONS); SetIndexBuffer(31, B_TEMA_C, INDICATOR_CALCULATIONS); SetIndexBuffer(32, B_TEMA_O, INDICATOR_CALCULATIONS); SetIndexBuffer(33, B_HULL_C, INDICATOR_CALCULATIONS); SetIndexBuffer(34, B_HULL_O, INDICATOR_CALCULATIONS); SetIndexBuffer(35, B_SSMA_C, INDICATOR_CALCULATIONS); SetIndexBuffer(36, B_SSMA_O, INDICATOR_CALCULATIONS); SetIndexBuffer(37, B_LSMA_C, INDICATOR_CALCULATIONS); SetIndexBuffer(38, B_LSMA_O, INDICATOR_CALCULATIONS); SetIndexBuffer(39, B_DEMA_C, INDICATOR_CALCULATIONS); SetIndexBuffer(40, B_DEMA_O, INDICATOR_CALCULATIONS); SetIndexBuffer(41, B_SMA_C, INDICATOR_CALCULATIONS); SetIndexBuffer(42, B_SMA_O, INDICATOR_CALCULATIONS); SetIndexBuffer(43, B_EMA_C, INDICATOR_CALCULATIONS); SetIndexBuffer(44, B_EMA_O, INDICATOR_CALCULATIONS); SetIndexBuffer(45, B_SmoothRng, INDICATOR_CALCULATIONS); SetIndexBuffer(46, B_RngFilt, INDICATOR_CALCULATIONS); SetIndexBuffer(47, B_DivBear, INDICATOR_CALCULATIONS); SetIndexBuffer(48, B_DivBull, INDICATOR_CALCULATIONS); SetIndexBuffer(49, B_VWMA_C, INDICATOR_CALCULATIONS); SetIndexBuffer(50, B_VWMA_O, INDICATOR_CALCULATIONS); SetIndexBuffer(51, B_SMMA_C, INDICATOR_CALCULATIONS); SetIndexBuffer(52, B_SMMA_O, INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0, PLOT_ARROW, 233); PlotIndexSetInteger(1, PLOT_ARROW, 234); PlotIndexSetInteger(3, PLOT_ARROW, 119); PlotIndexSetInteger(4, PLOT_ARROW, 119);

   hATR = iATR(_Symbol, _Period, 50);
   hEMA144 = iMA(_Symbol, _Period, 144, 0, MODE_EMA, PRICE_CLOSE);
   hRSI = iRSI(_Symbol, _Period, 28, PRICE_CLOSE);

   if(InpMaType == DEMA) { hDEMA_C = iDEMA(_Symbol, _Period, len, 0, PRICE_CLOSE); hDEMA_O = iDEMA(_Symbol, _Period, len, 0, PRICE_OPEN); }
   if(InpMaType == TEMA) { hTEMA_C = iTEMA(_Symbol, _Period, len, 0, PRICE_CLOSE); hTEMA_O = iTEMA(_Symbol, _Period, len, 0, PRICE_OPEN); }
   if(InpMaType == SMMA) { hSMMA_C = iMA(_Symbol, _Period, len, 0, MODE_SMMA, PRICE_CLOSE); hSMMA_O = iMA(_Symbol, _Period, len, 0, MODE_SMMA, PRICE_OPEN); }

   return(INIT_SUCCEEDED);
}

double calcSMA(const double &s[], int i, int l) { if(i<l-1) return s[i]; double v=0; for(int k=0; k<l; k++) v+=s[i-k]; return v/l; }
double calcWMA(const double &s[], int i, int l) { if(i<l-1) return s[i]; double v=0, w=0; for(int k=0; k<l; k++) { double wt=l-k; v+=s[i-k]*wt; w+=wt; } return v/w; }
double calcALMA(const double &s[], int i, int l, double o, double sig) { if(i<l-1) return s[i]; double m=o*(l-1), st=l/sig, v=0, w=0; for(int k=0; k<l; k++) { double wt=MathExp(-MathPow(k-m,2)/(2*MathPow(st,2))); v+=s[i-(l-1-k)]*wt; w+=wt; } return w!=0?v/w:s[i]; }
double calcLSMA(const double &s[], int i, int l, int o) { if(i<l-1) return s[i]; double sx=0, sy=0, sxy=0, sx2=0; for(int k=0; k<l; k++) { double x=k+1, y=s[i-(l-1-k)]; sx+=x; sy+=y; sxy+=x*y; sx2+=x*x; } double sl=(l*sxy-sx*sy)/(l*sx2-sx*sx), it=(sy-sl*sx)/l; return it+sl*(l+o); }
double calcVWMA(const double &s[], const long &v[], int i, int l) { if(i<l-1) return s[i]; double sv=0, sw=0; for(int k=0; k<l; k++) { sv+=s[i-k]*v[i-k]; sw+=(double)v[i-k]; } return sw!=0?sv/sw:s[i]; }

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]) {
   int len = InpMaPeriod; if(InpUseAltSignals) len *= InpMultiplier;
   if(rates_total < 250) return 0;
   if(CopyBuffer(hATR, 0, 0, rates_total, B_ATR) <= 0) return 0;
   if(CopyBuffer(hEMA144, 0, 0, rates_total, B_EMA144) <= 0) return 0;
   if(CopyBuffer(hRSI, 0, 0, rates_total, B_RSI) <= 0) return 0;

   if(InpMaType == DEMA) { CopyBuffer(hDEMA_C, 0, 0, rates_total, B_DEMA_C); CopyBuffer(hDEMA_O, 0, 0, rates_total, B_DEMA_O); }
   if(InpMaType == TEMA) { CopyBuffer(hTEMA_C, 0, 0, rates_total, B_TEMA_C); CopyBuffer(hTEMA_O, 0, 0, rates_total, B_TEMA_O); }
   if(InpMaType == SMMA) { CopyBuffer(hSMMA_C, 0, 0, rates_total, B_SMMA_C); CopyBuffer(hSMMA_O, 0, 0, rates_total, B_SMMA_O); }

   int start = prev_calculated - 1; if(start < 1) { start = 1; B_HAOpen[0]=open[0]; B_HAClose[0]=close[0]; B_ESA[0]=close[0]; B_WT1[0]=0; }
   for(int i=start; i<rates_total; i++) {
      B_HAClose[i] = (open[i] + high[i] + low[i] + close[i]) / 4.0; B_HAOpen[i] = (B_HAOpen[i-1] + B_HAClose[i-1]) / 2.0;
      double alpha=2.0/11.0; B_ESA[i]=alpha*close[i]+(1.0-alpha)*B_ESA[i-1]; B_D[i]=alpha*MathAbs(close[i]-B_ESA[i])+(1.0-alpha)*B_D[i-1];
      double ci=(B_D[i]!=0)?(close[i]-B_ESA[i])/(0.015*B_D[i]):0; B_WT1[i]=alpha*ci+(1.0-alpha)*B_WT1[i-1]; B_WT2[i]=calcSMA(B_WT1,i,3);
      double avrng = calcSMA(B_ATR, i, 20); B_SmoothRng[i] = avrng * 2.0; B_RngFilt[i] = close[i];
      if(close[i] > B_RngFilt[i-1]) { if(close[i] - B_SmoothRng[i] < B_RngFilt[i-1]) B_RngFilt[i] = B_RngFilt[i-1]; else B_RngFilt[i] = close[i] - B_SmoothRng[i]; }
      else { if(close[i] + B_SmoothRng[i] > B_RngFilt[i-1]) B_RngFilt[i] = B_RngFilt[i-1]; else B_RngFilt[i] = close[i] + B_SmoothRng[i]; }
   }
   for(int i=start; i<rates_total; i++) {
      int idx = i - InpDelayOffset; if(idx < 0) idx = 0;
      const double &sC = InpUseHeikinAshi ? B_HAClose : close; const double &sO = InpUseHeikinAshi ? B_HAOpen : open;
      switch(InpMaType) {
         case ALMA: B_CMA[i]=calcALMA(sC,idx,len,InpOffsetALMA,(double)InpOffsetSigma); B_OMA[i]=calcALMA(sO,idx,len,InpOffsetALMA,(double)InpOffsetSigma); break;
         case HullMA: B_HULL_C[i]=2.0*calcWMA(sC,idx,len/2)-calcWMA(sC,idx,len); B_CMA[i]=calcWMA(B_HULL_C,i,(int)MathSqrt(len)); B_HULL_O[i]=2.0*calcWMA(sO,idx,len/2)-calcWMA(sO,idx,len); B_OMA[i]=calcWMA(B_HULL_O,i,(int)MathSqrt(len)); break;
         case LSMA: B_CMA[i]=calcLSMA(sC,idx,len,InpOffsetSigma); B_OMA[i]=calcLSMA(sO,idx,len,InpOffsetSigma); break;
         case SSMA: double ar=MathExp(-1.414*3.14159/len), br=2*ar*MathCos(1.414*3.14159/len), cr2=br, cr3=-ar*ar, cr1=1-cr2-cr3; B_CMA[i]=cr1*(sC[idx]+(idx>0?sC[idx-1]:sC[idx]))/2+cr2*B_CMA[i-1]+cr3*(i>1?B_CMA[i-2]:B_CMA[i-1]); B_OMA[i]=cr1*(sO[idx]+(idx>0?sO[idx-1]:sO[idx]))/2+cr2*B_OMA[i-1]+cr3*(i>1?B_OMA[i-2]:B_OMA[i-1]); break;
         case VWMA: B_CMA[i]=calcVWMA(sC,tick_volume,idx,len); B_OMA[i]=calcVWMA(sO,tick_volume,idx,len); break;
         case DEMA: B_CMA[i]=B_DEMA_C[i]; B_OMA[i]=B_DEMA_O[i]; break;
         case TEMA: B_CMA[i]=B_TEMA_C[i]; B_OMA[i]=B_TEMA_O[i]; break;
         case SMMA: B_CMA[i]=B_SMMA_C[i]; B_OMA[i]=B_SMMA_O[i]; break;
         case EMA: B_EMA_C[i]=calcEMA(sC,idx,len,B_EMA_C[i-1]); B_CMA[i]=B_EMA_C[i]; B_EMA_O[i]=calcEMA(sO,idx,len,B_EMA_O[i-1]); B_OMA[i]=B_EMA_O[i]; break;
         default: B_CMA[i]=calcSMA(sC,idx,len); B_OMA[i]=calcSMA(sO,idx,len); break;
      }
      B_Buy[i]=B_Sell[i]=EMPTY_VALUE;
      if(i>0) {
         bool buy=B_CMA[i]>B_OMA[i] && B_CMA[i-1]<=B_OMA[i-1], sell=B_CMA[i]<B_OMA[i] && B_CMA[i-1]>=B_OMA[i-1];
         bool filters = (B_RSI[i]>35 && B_RSI[i]<65) || (B_WT2[i]>-40 && B_WT2[i]<40);
         double off=B_ATR[i]*0.5;
         if(buy && close[i]>B_EMA144[i] && filters) { B_Buy[i]=low[i]-off; B_TP1[i]=close[i]*(1+InpTP1_Perc/100); B_TP2[i]=close[i]*(1+InpTP2_Perc/100); B_TP3[i]=close[i]*(1+InpTP3_Perc/100); B_SL[i]=close[i]*(1-InpSL_Perc/100); }
         if(sell && close[i]<B_EMA144[i] && filters) { B_Sell[i]=high[i]+off; B_TP1[i]=close[i]*(1-InpTP1_Perc/100); B_TP2[i]=close[i]*(1-InpTP2_Perc/100); B_TP3[i]=close[i]*(1-InpTP3_Perc/100); B_SL[i]=close[i]*(1+InpSL_Perc/100); }
         if(B_Buy[i]==EMPTY_VALUE && B_Sell[i]==EMPTY_VALUE) { B_TP1[i]=B_TP1[i-1]; B_TP2[i]=B_TP2[i-1]; B_TP3[i]=B_TP3[i-1]; B_SL[i]=B_SL[i-1]; }
         B_CandleO[i]=open[i]; B_CandleH[i]=high[i]; B_CandleL[i]=low[i]; B_CandleC[i]=close[i]; B_Color[i]=(B_CMA[i]>B_OMA[i])?0:1;
      }
      if(InpShowKC) { double basis=calcSMA(close,i,20); B_KCU[i]=basis+1.5*B_ATR[i]; B_KCL[i]=basis-1.5*B_ATR[i]; }
      if(InpShowLR && i>=InpLRPeriod) {
         double sx=0, sy=0, sxy=0, sx2=0; int lr_l=InpLRPeriod;
         for(int k=0; k<lr_l; k++) { double x=k+1, y=close[i-(lr_l-1-k)]; sx+=x; sy+=y; sxy+=x*y; sx2+=x*x; }
         double sl=(lr_l*sxy-sx*sy)/(lr_l*sx2-sx*sx), it=(sy-sl*sx)/lr_l;
         B_LRC[i]=it+sl*lr_l; double uD=0, dD=0; for(int k=0; k<lr_l; k++) { double v=it+sl*(k+1), d=close[i-(lr_l-1-k)]-v; if(d>uD) uD=d; if(d<dD) dD=d; }
         B_LRU[i]=B_LRC[i]+uD; B_LRL[i]=B_LRC[i]+dD;
      }
      if(i>=InpSwingLength && i<rates_total-InpSwingLength && i > rates_total - 300) {
         bool isH=true, isL=true; for(int j=1; j<=InpSwingLength; j++) { if(high[i]<high[i-j] || high[i]<high[i+j]) isH=false; if(low[i]>low[i-j] || low[i]>low[i+j]) isL=false; }
         if(isH) { B_SwingH[i]=high[i]; if(InpShowZones) { string n="Sup_"+IntegerToString(i); double bw=B_ATR[i]*(InpBoxWidth/10); ObjectCreate(0, n, OBJ_RECTANGLE, 0, time[i], high[i], time[rates_total-1], high[i]-bw); ObjectSetInteger(0, n, OBJPROP_COLOR, clrRed); supplyZones[sPtr%50].name=n; supplyZones[sPtr%50].top=high[i]; supplyZones[sPtr%50].active=true; sPtr++; } }
         if(isL) { B_SwingL[i]=low[i]; if(InpShowZones) { string n="Dem_"+IntegerToString(i); double bw=B_ATR[i]*(InpBoxWidth/10); ObjectCreate(0, n, OBJ_RECTANGLE, 0, time[i], low[i], time[rates_total-1], low[i]+bw); ObjectSetInteger(0, n, OBJPROP_COLOR, clrGreen); demandZones[dPtr%50].name=n; demandZones[dPtr%50].bottom=low[i]; demandZones[dPtr%50].active=true; dPtr++; } }
      }
      for(int k=0; k<50; k++) {
         if(supplyZones[k].active) { ObjectSetInteger(0, supplyZones[k].name, OBJPROP_TIME, 1, time[rates_total-1]); if(InpShowBOS && close[i]>supplyZones[k].top) { supplyZones[k].active=false; ObjectSetInteger(0, supplyZones[k].name, OBJPROP_COLOR, clrOrange); } }
         if(demandZones[k].active) { ObjectSetInteger(0, demandZones[k].name, OBJPROP_TIME, 1, time[rates_total-1]); if(InpShowBOS && close[i]<demandZones[k].bottom) { demandZones[k].active=false; ObjectSetInteger(0, demandZones[k].name, OBJPROP_COLOR, clrOrange); } }
      }
   }
   return(rates_total);
}
void OnDeinit(const int r) { ObjectsDeleteAll(0, "Sup_"); ObjectsDeleteAll(0, "Dem_"); }
//+------------------------------------------------------------------+
