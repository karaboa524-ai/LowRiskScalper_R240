// saved//+------------------------------------------------------------------+
//| Low Risk Scalping EA - Small Account (R240)                       |
//| Platform: MT5                                                     |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>
CTrade trade;

// ---- Inputs ----
input double RiskPercent      = 1.0;    // Risk per trade (%)
input int    StopLossPoints   = 150;    // SL in points
input int    TakeProfitPoints = 300;    // TP in points
input int    MaxSpreadPoints  = 30;     // Max allowed spread
input int    FastEMA          = 50;
input int    SlowEMA          = 200;
input int    RSIPeriod        = 14;
input double RSI_BuyLevel     = 30;
input double RSI_SellLevel    = 70;

// ---- Indicators ----
int emaFastHandle;
int emaSlowHandle;
int rsiHandle;

//+------------------------------------------------------------------+
int OnInit()
{
   emaFastHandle = iMA(_Symbol, PERIOD_M5, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   emaSlowHandle = iMA(_Symbol, PERIOD_M5, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   rsiHandle     = iRSI(_Symbol, PERIOD_M5, RSIPeriod, PRICE_CLOSE);

   if(emaFastHandle == INVALID_HANDLE ||
      emaSlowHandle == INVALID_HANDLE ||
      rsiHandle     == INVALID_HANDLE)
   {
      Print("Indicator error");
      return INIT_FAILED;
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTick()
{
   // Only 1 trade at a time
   if(PositionSelect(_Symbol))
      return;

   // Spread filter
   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                    SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;

   if(spread > MaxSpreadPoints)
      return;

   double emaFast[1], emaSlow[1], rsi[1];

   CopyBuffer(emaFastHandle, 0, 0, 1, emaFast);
   CopyBuffer(emaSlowHandle, 0, 0, 1, emaSlow);
   CopyBuffer(rsiHandle, 0, 0, 1, rsi);

   double lot = CalculateLotSize();

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // BUY condition
   if(emaFast[0] > emaSlow[0] && rsi[0] <= RSI_BuyLevel)
   {
      trade.Buy(
         lot,
         _Symbol,
         ask,
         ask - StopLossPoints * _Point,
         ask + TakeProfitPoints * _Point
      );
   }

   // SELL condition
   if(emaFast[0] < emaSlow[0] && rsi[0] >= RSI_SellLevel)
   {
      trade.Sell(
         lot,
         _Symbol,
         bid,
         bid + StopLossPoints * _Point,
         bid - TakeProfitPoints * _Point
      );
   }
}

//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * RiskPercent / 100.0;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   double lot = riskMoney / (StopLossPoints * tickValue / tickSize);

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   lot = MathMax(minLot, MathMin(lot, maxLot));
   return NormalizeDouble(lot, 2);
}
//+------------------------------------------------------------------+
