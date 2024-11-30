//+------------------------------------------------------------------+
//|                                       quadAlertEAModified_V1.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict 
//--- Input Parameters

//--- Stochastic 1 Parameters
input int magicNumber  = 0;                      // Magic Number
input int Sto1_KPeriod = 9;                      // Sto1 %K Period
input int Sto1_DPeriod = 3;                      // Sto1 %D Period
input int Sto1_Slowing = 1;                      // Sto1 Slowing
input double Sto1_UpperLevel = 80.0;             // Sto1 Upper Level
input double Sto1_LowerLevel = 20.0;             // Sto1 Lower Level
input bool Sto1_TriggerUpper = false;             // Sto1 Trigger on Upper Level
input bool Sto1_TriggerLower = true;             // Sto1 Trigger on Lower Level

//--- Stochastic 2 Parameters
input int Sto2_KPeriod = 14;                     // Sto2 %K Period
input int Sto2_DPeriod = 3;                      // Sto2 %D Period
input int Sto2_Slowing = 1;                      // Sto2 Slowing
input double Sto2_UpperLevel = 80.0;             // Sto2 Upper Level
input double Sto2_LowerLevel = 20.0;             // Sto2 Lower Level
input bool Sto2_TriggerUpper = false;             // Sto2 Trigger on Upper Level
input bool Sto2_TriggerLower = true;             // Sto2 Trigger on Lower Level

//--- Stochastic 3 Parameters
input int Sto3_KPeriod = 40;                     // Sto3 %K Period
input int Sto3_DPeriod = 4;                      // Sto3 %D Period
input int Sto3_Slowing = 1;                      // Sto3 Slowing
input double Sto3_UpperLevel = 80.0;             // Sto3 Upper Level
input double Sto3_LowerLevel = 20.0;             // Sto3 Lower Level
input bool Sto3_TriggerUpper = false;             // Sto3 Trigger on Upper Level
input bool Sto3_TriggerLower = true;             // Sto3 Trigger on Lower Level

//--- Stochastic 4 Parameters
input int Sto4_KPeriod = 60;                     // Sto4 %K Period
input int Sto4_DPeriod = 10;                     // Sto4 %D Period
input int Sto4_Slowing = 3;                      // Sto4 Slowing
input double Sto4_UpperLevel = 80.0;             // Sto4 Upper Level
input double Sto4_LowerLevel = 20.0;             // Sto4 Lower Level
input bool Sto4_TriggerUpper = false;             // Sto4 Trigger on Upper Level
input bool Sto4_TriggerLower = true;             // Sto4 Trigger on Lower Level

//--- Alert Parameters
input int AlertBars = 3;                          // Number of bars to look back
input string AlertSound = "news.wav";             // Custom alert sound
input bool EnableEmailAlert = false;               // Enable Email Alerts
input bool EnablePushAlert = false;                // Enable Push Notifications
input string EmailAddress = "";                    // Email Address for Alerts

//--- Global Variables
bool alertTriggered = false;                        // Alert Triggered Flag

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  { 
   //PlaySound(AlertSound);
   //--- Validate Input Parameters
   if(Sto1_KPeriod <=0 || Sto1_DPeriod <=0 || Sto1_Slowing <=0 ||
      Sto2_KPeriod <=0 || Sto2_DPeriod <=0 || Sto2_Slowing <=0 ||
      Sto3_KPeriod <=0 || Sto3_DPeriod <=0 || Sto3_Slowing <=0 ||
      Sto4_KPeriod <=0 || Sto4_DPeriod <=0 || Sto4_Slowing <=0)
     {
      Print("Error: All KPeriod, DPeriod, and Slowing parameters must be positive integers.");
      return(INIT_FAILED);
     }
   
   if(Sto1_UpperLevel <= Sto1_LowerLevel ||
      Sto2_UpperLevel <= Sto2_LowerLevel ||
      Sto3_UpperLevel <= Sto3_LowerLevel ||
      Sto4_UpperLevel <= Sto4_LowerLevel)
     {
      Print("Error: For each Stochastic Oscillator, UpperLevel must be greater than LowerLevel.");
      return(INIT_FAILED);
     }
   
   //--- Check Email Configuration if Enabled
   if(EnableEmailAlert && EmailAddress == "")
     {
      Print("Warning: Email Alert is enabled but EmailAddress is not set.");
     }
   
   //--- Check Push Notifications if Enabled
   if(EnablePushAlert)
     {
      // Ensure Push Notifications are configured in MetaTrader
      if(StringLen(StringConcatenate(AccountNumber(), Symbol(), Period())) == 0)
        {
         Print("Warning: Push Notifications are enabled but not configured in MetaTrader.");
        }
     }
   
   //--- Check Alert Sound File
   if(FileIsExist(AlertSound) == false)
     {
      //Print("Warning: Alert sound file ", AlertSound, " not found in the Sounds directory.");
     }
   
   //--- Initialization Successful
   Print("Quad Stochastic Alert EA Initialized Successfully.");
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- Cleanup if necessary
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   comment = "";
   //--- Ensure there are enough bars
   int required_bars_sto1 = Sto1_KPeriod + Sto1_Slowing + Sto1_DPeriod;
   int required_bars_sto2 = Sto2_KPeriod + Sto2_Slowing + Sto2_DPeriod;
   int required_bars_sto3 = Sto3_KPeriod + Sto3_Slowing + Sto3_DPeriod;
   int required_bars_sto4 = Sto4_KPeriod + Sto4_Slowing + Sto4_DPeriod;
   
   int required_bars = MathMax(MathMax(required_bars_sto1, required_bars_sto2),
                               MathMax(required_bars_sto3, required_bars_sto4));
   
   if(Bars < required_bars)
     {
      //--- Not enough bars to perform calculations
      return;
     }
   
   //--- Get %D values for each Stochastic Oscillator
   double Sto1_D = iStochastic(NULL, 0, Sto1_KPeriod, Sto1_Slowing, Sto1_DPeriod, MODE_SMA, 1, MODE_SIGNAL, 0);
   double Sto2_D = iStochastic(NULL, 0, Sto2_KPeriod, Sto2_Slowing, Sto2_DPeriod, MODE_SMA, 1, MODE_SIGNAL, 0);
   double Sto3_D = iStochastic(NULL, 0, Sto3_KPeriod, Sto3_Slowing, Sto3_DPeriod, MODE_SMA, 1, MODE_SIGNAL, 0);
   double Sto4_D = iStochastic(NULL, 0, Sto4_KPeriod, Sto4_Slowing, Sto4_DPeriod, MODE_SMA, 1, MODE_SIGNAL, 0);
   
   //--- Check Alert Conditions
   bool Sto1_Upper_Triggered = false;
   bool Sto1_Lower_Triggered = false;
   
   bool Sto2_Upper_Triggered = false;
   bool Sto2_Lower_Triggered = false;
   
   bool Sto3_Upper_Triggered = false;
   bool Sto3_Lower_Triggered = false;
   
   bool Sto4_Upper_Triggered = false;
   bool Sto4_Lower_Triggered = false;
   
   //--- Iterate through the last AlertBars bars
   for(int i=0; i < AlertBars; i++)
     {
      //--- Bar Index
      int shift = i;
      
      //--- Stochastic 1
      if(Sto1_TriggerUpper && !Sto1_Upper_Triggered)
        {
         double prev_D = iStochastic(NULL, 0, Sto1_KPeriod, Sto1_Slowing, Sto1_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift+1);
         double current_D = iStochastic(NULL, 0, Sto1_KPeriod, Sto1_Slowing, Sto1_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
         
         // Check for Cross Above UpperLevel
         if(current_D >= Sto1_UpperLevel)
            Sto1_Upper_Triggered = true;
        }
      
      if(Sto1_TriggerLower && !Sto1_Lower_Triggered)
        {
         double prev_D = iStochastic(NULL, 0, Sto1_KPeriod, Sto1_Slowing, Sto1_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift+1);
         double current_D = iStochastic(NULL, 0, Sto1_KPeriod, Sto1_Slowing, Sto1_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
         
         // Check for Cross Below LowerLevel
         if(current_D <= Sto1_LowerLevel)
            Sto1_Lower_Triggered = true;
        }
      
      //--- Stochastic 2
      if(Sto2_TriggerUpper && !Sto2_Upper_Triggered)
        {
         double prev_D = iStochastic(NULL, 0, Sto2_KPeriod, Sto2_Slowing, Sto2_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift+1);
         double current_D = iStochastic(NULL, 0, Sto2_KPeriod, Sto2_Slowing, Sto2_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
         
         // Check for Cross Above UpperLevel
         if( current_D >= Sto2_UpperLevel)
            Sto2_Upper_Triggered = true;
        }
      
      if(Sto2_TriggerLower && !Sto2_Lower_Triggered)
        {
         double prev_D = iStochastic(NULL, 0, Sto2_KPeriod, Sto2_Slowing, Sto2_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift+1);
         double current_D = iStochastic(NULL, 0, Sto2_KPeriod, Sto2_Slowing, Sto2_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
         
         // Check for Cross Below LowerLevel
         if(current_D <= Sto2_LowerLevel)
            Sto2_Lower_Triggered = true;
        }
      
      //--- Stochastic 3
      if(Sto3_TriggerUpper && !Sto3_Upper_Triggered)
        {
         double prev_D = iStochastic(NULL, 0, Sto3_KPeriod, Sto3_Slowing, Sto3_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift+1);
         double current_D = iStochastic(NULL, 0, Sto3_KPeriod, Sto3_Slowing, Sto3_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
         
         // Check for Cross Above UpperLevel
         if(current_D >= Sto3_UpperLevel)
            Sto3_Upper_Triggered = true;
        }
      
      if(Sto3_TriggerLower && !Sto3_Lower_Triggered)
        {
         double prev_D = iStochastic(NULL, 0, Sto3_KPeriod, Sto3_Slowing, Sto3_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift+1);
         double current_D = iStochastic(NULL, 0, Sto3_KPeriod, Sto3_Slowing, Sto3_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
         
         // Check for Cross Below LowerLevel
         if(current_D <= Sto3_LowerLevel)
            Sto3_Lower_Triggered = true;
        }
      
      //--- Stochastic 4
      if(Sto4_TriggerUpper && !Sto4_Upper_Triggered)
        {
         double prev_D = iStochastic(NULL, 0, Sto4_KPeriod, Sto4_Slowing, Sto4_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift+1);
         double current_D = iStochastic(NULL, 0, Sto4_KPeriod, Sto4_Slowing, Sto4_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
         
         // Check for Cross Above UpperLevel
         if( current_D >= Sto4_UpperLevel)
            Sto4_Upper_Triggered = true;
        }
      
      if(Sto4_TriggerLower && !Sto4_Lower_Triggered)
        {
         double prev_D = iStochastic(NULL, 0, Sto4_KPeriod, Sto4_Slowing, Sto4_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift+1);
         double current_D = iStochastic(NULL, 0, Sto4_KPeriod, Sto4_Slowing, Sto4_DPeriod, MODE_SMA, 1, MODE_SIGNAL, shift);
         
         // Check for Cross Below LowerLevel
         if(current_D <= Sto4_LowerLevel)
            Sto4_Lower_Triggered = true;
        }
     }
   
   //--- Evaluate if All Conditions are Met
   bool allConditionsMet = true;
   bool overboughtConditionMet = true;
   bool oversoldConditionMet   = true;
   
   if(Sto1_TriggerUpper && !Sto1_Upper_Triggered){
      allConditionsMet = false; overboughtConditionMet = false;}
   if(Sto1_TriggerLower && !Sto1_Lower_Triggered){
      allConditionsMet = false; oversoldConditionMet   = false;}
   
   if(Sto2_TriggerUpper && !Sto2_Upper_Triggered){
      allConditionsMet = false; overboughtConditionMet = false;}
   if(Sto2_TriggerLower && !Sto2_Lower_Triggered){
      allConditionsMet = false; oversoldConditionMet   = false;}
   
   if(Sto3_TriggerUpper && !Sto3_Upper_Triggered){
      allConditionsMet = false; overboughtConditionMet = false;}
   if(Sto3_TriggerLower && !Sto3_Lower_Triggered){
      allConditionsMet = false; oversoldConditionMet   = false;}
   
   if(Sto4_TriggerUpper && !Sto4_Upper_Triggered){
      allConditionsMet = false; overboughtConditionMet = false;}
   if(Sto4_TriggerLower && !Sto4_Lower_Triggered){
      allConditionsMet = false; oversoldConditionMet   = false;}
   //---
   if((overboughtConditionMet || oversoldConditionMet))
     {
      allConditionsMet  = true;
     }
   comment = ""+allConditionsMet;
   comment += "\n OB Met "+overboughtConditionMet;
   comment += "\n OS Met "+oversoldConditionMet;
   //---
   comment +="\n ";
   comment +="\n 1UT  "+Sto1_Upper_Triggered;
   comment +="\n 1LT  "+Sto1_Lower_Triggered;
   //---
   comment +="\n ";
   comment +="\n 2UT  "+Sto2_Upper_Triggered;
   comment +="\n 2LT  "+Sto2_Lower_Triggered;
   //---
   comment +="\n ";
   comment +="\n 3UT  "+Sto3_Upper_Triggered;
   comment +="\n 3LT  "+Sto3_Lower_Triggered;
   //---
   comment +="\n ";
   comment +="\n 4UT  "+Sto4_Upper_Triggered;
   comment +="\n 4LT  "+Sto4_Lower_Triggered;
   
   
   Comment(comment); 
   //--- Trigger Alert if All Conditions are Met and Not in Cooldown
   if(allConditionsMet && !alertTriggered)
     {
      PlayAlert();
      alertTriggered = true;
     }
   else if(!allConditionsMet)
     {
      //--- Reset Alert Trigger if Conditions are Not Met
      alertTriggered = false;
     }
  }
string comment;
//+------------------------------------------------------------------+
//| Play Alert Function                                              |
//+------------------------------------------------------------------+
void PlayAlert()
  {
   //--- Play Custom Sound
   //if(FileIsExist(AlertSound))
   if(PlaySound(AlertSound))
     {
      Print("Alert Sound Found And Played:");
     }
   else
     {
      Print("Alert Sound File not found: ", AlertSound);
     } 
   //--- Display Alert Message on Chart
   Alert("Quad Stochastic Alert Triggered! ",Symbol()," Magic Number ",string(magicNumber));
   
   //--- Send Email if Enabled
   if(EnableEmailAlert && EmailAddress != "")
     {
      string subject = "Quad Stochastic Alert Triggered!";
      string body = "All four Stochastic Oscillators have met the specified conditions."+_Symbol+" Magic Number: "+string(magicNumber);
      bool emailSent = SendMail(subject, body);
      if(!emailSent)
         Print("Error: Failed to send email alert.");
     }
   
   //--- Send Push Notification if Enabled
   if(EnablePushAlert)
     {
      string pushMessage = "Quad Stochastic Alert Triggered! "+_Symbol+" Magic Number "+string(magicNumber);
      bool pushSent = SendNotification(pushMessage);
      if(!pushSent)
         Print("Error: Failed to send push notification.");
     }
   
   //--- Log Alert in Journal
   Print("Quad Stochastic Alert Triggered at ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
  }
