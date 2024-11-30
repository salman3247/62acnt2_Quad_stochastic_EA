//+------------------------------------------------------------------+
//|                               QuadTransactionalEA_Modified.mq4   |
//|                            Modified by Assistant                 |
//+------------------------------------------------------------------+
#property copyright "Modified by Assistant"
#property link      ""
#property version   "2.02"
#property strict

//--- Input Parameters
input int    magicNumber    = 12345;                  // Magic Number

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
input int    LookbackPeriod = 3;                      // Lookback period for Stochastic conditions

//--- Trading Parameters
input int    StopBuffer     = 50;                     // Stop Buffer in points below fractal low
input double TrailingADR    = 0.5;                    // Trailing Stop as percentage of 14-period ADR
input double LotSize        = 0.1;                    // Fixed lot size for orders

//--- Global Variables
double ADRValue;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- Validate Input Parameters
   if (Sto1_KPeriod <= 0 || Sto1_DPeriod <= 0 || Sto1_Slowing <= 0 ||
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

   if (Bars < required_bars)
     {
      //--- Not enough bars to perform calculations
      return;
     }

   //--- Check for existing open positions
   if (CountOpenPositions() > 0)
     {
      //--- Manage existing positions (Trailing Stop)
      ManagePositions();
      return;
     }

   //--- Check for fractal on the low
   double fractalValue = iFractals(NULL, 0, MODE_LOWER, 2);
   if (fractalValue == 0 || fractalValue != Low[2])
     {
      //--- No valid fractal found at shift 2
      return;
     }

   //--- Check Stochastic Conditions
   if (!CheckStochasticConditions())
     {
      //--- Conditions not met
      return;
     }

   //--- All conditions met, place a buy order
   PlaceBuyOrder(fractalValue);
  }

//+------------------------------------------------------------------+
//| Check Open Positions                                             |
//+------------------------------------------------------------------+
int CountOpenPositions()
  {
   int total = OrdersTotal();
   int count = 0;
   for (int i = 0; i < total; i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if (OrderMagicNumber() == magicNumber && OrderSymbol() == Symbol())
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
bool CheckStochasticConditions()
  {
   bool conditionMet = true;

   //--- Check for each selected Stochastic
   if (UseSto1)
     {
      if (!IsStoBelowLevel(Sto1_KPeriod, Sto1_DPeriod, Sto1_Slowing))
        {
         conditionMet = false;
        }
     }
   if (UseSto2)
     {
      if (!IsStoBelowLevel(Sto2_KPeriod, Sto2_DPeriod, Sto2_Slowing))
        {
         conditionMet = false;
        }
     }
   if (UseSto3)
     {
      if (!IsStoBelowLevel(Sto3_KPeriod, Sto3_DPeriod, Sto3_Slowing))
        {
         conditionMet = false;
        }
     }
   if (UseSto4)
     {
      if (!IsStoBelowLevel(Sto4_KPeriod, Sto4_DPeriod, Sto4_Slowing))
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
   for (int shift = 0; shift < LookbackPeriod; shift++)
     {
      double sto_D = iStochastic(NULL, 0, KPeriod, Slowing, DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
      if (sto_D <= Sto_LowerLevel)
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

   if (lotSize < minLot)
     lotSize = minLot;
   if (lotSize > maxLot)
     lotSize = maxLot;

   double ask = NormalizeDouble(MarketInfo(Symbol(), MODE_ASK), Digits);
   double sl = NormalizeDouble(stopLoss, Digits);

   int ticket = OrderSend(Symbol(), OP_BUY, lotSize, ask, 3, sl, 0, "Quad EA Buy", magicNumber, 0, clrBlue);
   if (ticket < 0)
     {
      Print("OrderSend failed with error #", GetLastError());
     }
   else
     {
      Print("Buy order placed successfully. Ticket #", ticket);
     }
  }

//+------------------------------------------------------------------+
//| Manage Existing Positions (Trailing Stop)                        |
//+------------------------------------------------------------------+
void ManagePositions()
  {
   //--- Calculate the 14-period ADR
   ADRValue = CalculateADR(14);
   double trailStop = ADRValue * TrailingADR;

   int total = OrdersTotal();
   for (int i = 0; i < total; i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if (OrderMagicNumber() == magicNumber && OrderSymbol() == Symbol() && OrderType() == OP_BUY)
           {
            double newStopLoss = Bid - trailStop;
            if (newStopLoss > OrderStopLoss())
              {
               bool modified = OrderModify(OrderTicket(), OrderOpenPrice(), newStopLoss, OrderTakeProfit(), 0, clrBlue);
               if (modified)
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

   for (int i = 1; countedBars < period && i < Bars; i++)
     {
      datetime time = Time[i];
      if (TimeDay(time) != TimeDay(prevTime))
        {
         double high = iHigh(Symbol(), PERIOD_D1, countedBars);
         double low = iLow(Symbol(), PERIOD_D1, countedBars);
         totalRange += (high - low);
         countedBars++;
        }
      prevTime = time;
     }

   if (countedBars > 0)
     {
      return (totalRange / countedBars);
     }
   else
     {
      return (0);
     }
  }
