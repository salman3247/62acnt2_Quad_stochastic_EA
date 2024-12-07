//+------------------------------------------------------------------+
//|                  |
//|                                   |
//+------------------------------------------------------------------+
#property copyright "Salman Soltaniyan"
#property link      ""
#property version   "2.02"
#property strict
enum ENUM_TRADE_DIRECTION
  {
   BUY_ONLY=0,
   SELL_ONLY=1,
   BOTH=2,

  };


//--- Input Parameters
input int    magicNumber    = 12345;                  // Magic Number
input ENUM_TRADE_DIRECTION trade_direction = BOTH;
//--- Stochastic 1 Parameters
input bool   UseSto1        = true;                   // Use Stochastic 1
input int    Sto1_KPeriod   = 9;                      // Sto1 %K Period
input int    Sto1_DPeriod   = 3;                      // Sto1 %D Period
input int    Sto1_Slowing   = 1;                      // Sto1 Slowing

//--- Stochastic 2 Parameters
input bool   UseSto2        = true;                   // Use Stochastic 2
input int    Sto2_KPeriod   = 14;                     // Sto2 %K Period
input int    Sto2_DPeriod   = 3;                      // Sto2 %D Period
input int    Sto2_Slowing   = 1;                      // Sto2 Slowing

//--- Stochastic 3 Parameters
input bool   UseSto3        = true;                   // Use Stochastic 3
input int    Sto3_KPeriod   = 40;                     // Sto3 %K Period
input int    Sto3_DPeriod   = 4;                      // Sto3 %D Period
input int    Sto3_Slowing   = 1;                      // Sto3 Slowing

//--- Stochastic 4 Parameters
input bool   UseSto4        = true;                   // Use Stochastic 4
input int    Sto4_KPeriod   = 60;                     // Sto4 %K Period
input int    Sto4_DPeriod   = 10;                     // Sto4 %D Period
input int    Sto4_Slowing   = 3;                      // Sto4 Slowing

//--- Common Parameters
input double Sto_LowerLevel = 20.0;                   // Lower Level for all Stochastics
input double Sto_UpperLevel = 80.0;
input int    LookbackPeriod = 3;                      // Lookback period for Stochastic conditions

//--- Trading Parameters
input int    StopBuffer     = 50;                     // Stop Buffer in points below fractal low
input double TrailingADR    = 0.5;                    // Trailing Stop as percentage of 14-period ADR
input double LotSize        = 0.1;                    // Fixed lot size for orders

//--- MA Parameters
input ENUM_MA_METHOD MA1_method = MODE_EMA;
input ENUM_MA_METHOD MA2_method = MODE_EMA;
input ENUM_MA_METHOD MA3_method = MODE_EMA;
input int MA1_period = 10;
input int MA2_period = 50;
input int MA3_period = 200;
input bool MA1_active = false;
input bool MA2_active = false;
input bool MA3_active = false;

input bool MACD_active= false;

int          fast_ema_period=12;   // Fast EMA period
int          slow_ema_period= 26; // Slow EMA period
int          signal_period=9;    // Signal line period

//--- Global Variables
double ADRValue;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Validate Input Parameters
   if(Sto1_KPeriod <= 0 || Sto1_DPeriod <= 0 || Sto1_Slowing <= 0 ||
      Sto2_KPeriod <= 0 || Sto2_DPeriod <= 0 || Sto2_Slowing <= 0 ||
      Sto3_KPeriod <= 0 || Sto3_DPeriod <= 0 || Sto3_Slowing <= 0 ||
      Sto4_KPeriod <= 0 || Sto4_DPeriod <= 0 || Sto4_Slowing <= 0)
     {
      Print("Error: All KPeriod, DPeriod, and Slowing parameters must be positive integers.");
      return (INIT_FAILED);
     }

//--- Initialization Successful
   Print("Quad Transactional EA Initialized Successfully.");
   return (INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Ensure there are enough bars
   int required_bars_sto1 = Sto1_KPeriod + Sto1_Slowing + Sto1_DPeriod;
   int required_bars_sto2 = Sto2_KPeriod + Sto2_Slowing + Sto2_DPeriod;
   int required_bars_sto3 = Sto3_KPeriod + Sto3_Slowing + Sto3_DPeriod;
   int required_bars_sto4 = Sto4_KPeriod + Sto4_Slowing + Sto4_DPeriod;
   int required_bars = MathMax(MathMax(required_bars_sto1, required_bars_sto2),
                               MathMax(required_bars_sto3, required_bars_sto4));

   required_bars = MathMax(required_bars, 5); // Minimum bars for fractal calculation

   if(Bars < required_bars)
     {
      //--- Not enough bars to perform calculations
      return;
     }

//--- Check for existing open positions
   if(CountOpenPositions() > 0)
     {
      //--- Manage existing positions (Trailing Stop)
      ManagePositions();
      return;
     }

//--- Check for fractal on the low


////--- Check Stochastic Conditions
//   if(!CheckStochasticConditions_Buy())
//     {
//      //--- Conditions not met
//      return;
//     }
   double ma1= iMA(_Symbol, PERIOD_CURRENT, MA1_period, 0, MA1_method, PRICE_CLOSE, 0);
   double ma2=  iMA(_Symbol, PERIOD_CURRENT, MA2_period, 0, MA2_method, PRICE_CLOSE, 0);
   double ma3=  iMA(_Symbol, PERIOD_CURRENT, MA3_period, 0, MA3_method, PRICE_CLOSE, 0);

   double macd_fast= iMACD(_Symbol, PERIOD_CURRENT, fast_ema_period, slow_ema_period, signal_period, PRICE_CLOSE, MODE_SIGNAL, 0);
   double macd_slow= iMACD(_Symbol, PERIOD_CURRENT, fast_ema_period, slow_ema_period, signal_period, PRICE_CLOSE, MODE_MAIN, 0);
//--- All conditions met, place a buy order
//place buy
   if(trade_direction !=SELL_ONLY  && CheckStochasticConditions_Buy())
     {
      double fractalValue = iFractals(NULL, 0, MODE_LOWER, 2);
      if(fractalValue == 0 || fractalValue != Low[2])
        {
         //--- No valid fractal found at shift 2
         return;
        }
      if((!MA1_active || Bid> ma1) && (!MA2_active || Bid> ma2)&& (!MA3_active || Bid> ma3) && (!MACD_active || macd_fast > macd_slow))
         PlaceBuyOrder(fractalValue);

     }

//place sell
   if(trade_direction !=BUY_ONLY  && CheckStochasticConditions_Sell())
     {
      double fractalValue = iFractals(NULL, 0, MODE_UPPER, 2);
      if(fractalValue == 0 || fractalValue != High[2])
        {
         //--- No valid fractal found at shift 2
         return;
        }

      if((!MA1_active || Bid< ma1) && (!MA2_active || Bid< ma2)&& (!MA3_active || Bid< ma3) && (!MACD_active || macd_fast < macd_slow))
         PlaceSellOrder(fractalValue);

     }


  }

//+------------------------------------------------------------------+
//| Check Open Positions                                             |
//+------------------------------------------------------------------+
int CountOpenPositions()
  {
   int total = OrdersTotal();
   int count = 0;
   for(int i = 0; i < total; i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderMagicNumber() == magicNumber && OrderSymbol() == Symbol())
           {
            count++;
           }
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Check Stochastic Conditions                                      |
//+------------------------------------------------------------------+
bool CheckStochasticConditions_Buy()
  {
   bool conditionMet = true;

//--- Check for each selected Stochastic
   if(UseSto1)
     {
      if(!IsStoBelowLevel(Sto1_KPeriod, Sto1_DPeriod, Sto1_Slowing))
        {
         conditionMet = false;
        }
     }
   if(UseSto2)
     {
      if(!IsStoBelowLevel(Sto2_KPeriod, Sto2_DPeriod, Sto2_Slowing))
        {
         conditionMet = false;
        }
     }
   if(UseSto3)
     {
      if(!IsStoBelowLevel(Sto3_KPeriod, Sto3_DPeriod, Sto3_Slowing))
        {
         conditionMet = false;
        }
     }
   if(UseSto4)
     {
      if(!IsStoBelowLevel(Sto4_KPeriod, Sto4_DPeriod, Sto4_Slowing))
        {
         conditionMet = false;
        }
     }
   return conditionMet;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckStochasticConditions_Sell()
  {
   bool conditionMet = true;

//--- Check for each selected Stochastic
   if(UseSto1)
     {
      if(!IsStoAboveLevel(Sto1_KPeriod, Sto1_DPeriod, Sto1_Slowing))
        {
         conditionMet = false;
        }
     }
   if(UseSto2)
     {
      if(!IsStoAboveLevel(Sto2_KPeriod, Sto2_DPeriod, Sto2_Slowing))
        {
         conditionMet = false;
        }
     }
   if(UseSto3)
     {
      if(!IsStoAboveLevel(Sto3_KPeriod, Sto3_DPeriod, Sto3_Slowing))
        {
         conditionMet = false;
        }
     }
   if(UseSto4)
     {
      if(!IsStoAboveLevel(Sto4_KPeriod, Sto4_DPeriod, Sto4_Slowing))
        {
         conditionMet = false;
        }
     }
   return conditionMet;
  }


//+------------------------------------------------------------------+
//| Check if Stochastic %D is below Lower Level within Lookback      |
//+------------------------------------------------------------------+
bool IsStoBelowLevel(int KPeriod, int DPeriod, int Slowing)
  {
   for(int shift = 0; shift < LookbackPeriod; shift++)
     {
      double sto_D = iStochastic(NULL, 0, KPeriod, Slowing, DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
      if(sto_D <= Sto_LowerLevel)
        {
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//| Check if Stochastic %D is above Upper Level within Lookback      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsStoAboveLevel(int KPeriod, int DPeriod, int Slowing)
  {
   for(int shift = 0; shift < LookbackPeriod; shift++)
     {
      double sto_D = iStochastic(NULL, 0, KPeriod, Slowing, DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
      if(sto_D >= Sto_UpperLevel)
        {
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//| Place Buy Order                                                  |
//+------------------------------------------------------------------+
void PlaceBuyOrder(double fractalLow)
  {
   double stopLoss = fractalLow - StopBuffer * Point;

// Ensure the lot size is within allowed limits
   double lotSize = LotSize; // Use the input LotSize directly
   double minLot  = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot  = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

// Adjust the lot size to the broker's lot step
   lotSize = NormalizeDouble(MathFloor(lotSize / lotStep) * lotStep, 2);

   if(lotSize < minLot)
      lotSize = minLot;
   if(lotSize > maxLot)
      lotSize = maxLot;

   double ask = NormalizeDouble(MarketInfo(Symbol(), MODE_ASK), Digits);
   double sl = NormalizeDouble(stopLoss, Digits);

   int ticket = OrderSend(Symbol(), OP_BUY, lotSize, ask, 3, sl, 0, "Quad EA Buy", magicNumber, 0, clrBlue);
   if(ticket < 0)
     {
      Print("OrderSend failed with error #", GetLastError());
     }
   else
     {
      Print("Buy order placed successfully. Ticket #", ticket);
     }
  }
//+------------------------------------------------------------------+
//| Place Buy Order                                                  |
//+------------------------------------------------------------------+
void PlaceSellOrder(double fractalHigh)
  {
   double stopLoss = fractalHigh + StopBuffer * Point;

// Ensure the lot size is within allowed limits
   double lotSize = LotSize; // Use the input LotSize directly
   double minLot  = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot  = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

// Adjust the lot size to the broker's lot step
   lotSize = NormalizeDouble(MathFloor(lotSize / lotStep) * lotStep, 2);

   if(lotSize < minLot)
      lotSize = minLot;
   if(lotSize > maxLot)
      lotSize = maxLot;

   double bid = NormalizeDouble(MarketInfo(Symbol(), MODE_BID), Digits);
   double sl = NormalizeDouble(stopLoss, Digits);

   int ticket = OrderSend(Symbol(), OP_SELL, lotSize, bid, 3, sl, 0, "Quad EA Sell", magicNumber, 0, clrRed);
   if(ticket < 0)
     {
      Print("OrderSend failed with error #", GetLastError());
     }
   else
     {
      Print("Sell order placed successfully. Ticket #", ticket);
     }
  }
//+------------------------------------------------------------------+
//| Manage Existing Positions (Trailing Stop)                        |
//+------------------------------------------------------------------+
void ManagePositions()
  {
//--- Calculate the 14-period ADR
 ADRValue = iATR(NULL, PERIOD_D1, 14, 1);
   //ADRValue = CalculateADR(14);
   double trailStop = ADRValue * TrailingADR;

   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderMagicNumber() == magicNumber && OrderSymbol() == Symbol())
            if((OrderType() == OP_BUY))
              {
               double newStopLoss = NormalizeDouble(Bid - trailStop, Digits());
               if(newStopLoss > OrderStopLoss())
                 {
                  bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), newStopLoss, OrderTakeProfit(), 0, clrBlue);
                  if(modified)
                    {
                     Print("Order #", OrderTicket(), " stop loss modified to ", DoubleToString(newStopLoss, Digits));
                    }
                  else
                    {
                     Print("Failed to modify stop loss for Order #", OrderTicket(), " Error: ", GetLastError());
                    }
                 }
              }
            else
               if((OrderType() == OP_SELL))
                 {
                  double newStopLoss = NormalizeDouble(Ask + trailStop,Digits());
                  if(newStopLoss < OrderStopLoss())
                    {
                     bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), newStopLoss, OrderTakeProfit(), 0, clrRed);
                     if(modified)
                       {
                        Print("Order #", OrderTicket(), " stop loss modified to ", DoubleToString(newStopLoss, Digits));
                       }
                     else
                       {
                        Print("Failed to modify stop loss for Order #", OrderTicket(), " Error: ", GetLastError());
                       }
                    }




                 }
        }
     }
  }

//+------------------------------------------------------------------+
//| Calculate Average Daily Range (ADR)                              |
//+------------------------------------------------------------------+
double CalculateADR(int period)
  {
   double totalRange = 0;
   int countedBars = 0;
   datetime prevTime = 0;

   for(int i = 1; countedBars < period && i < Bars; i++)
     {
      datetime time = Time[i];
      if(TimeDay(time) != TimeDay(prevTime))
        {
         double high = iHigh(Symbol(), PERIOD_D1, countedBars);
         double low = iLow(Symbol(), PERIOD_D1, countedBars);
         totalRange += (high - low);
         countedBars++;
        }
      prevTime = time;
     }

   if(countedBars > 0)
     {
      return (totalRange / countedBars);
     }
   else
     {
      return (0);
     }
  }
//+------------------------------------------------------------------+
