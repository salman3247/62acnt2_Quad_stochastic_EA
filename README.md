
https://www.mql5.com/en/job/229028

Quad stochastic EA (personal job) 

EA#2 stox transaction EA (indicator that was used to create EA (quadAlertEAModified_V3)

RULES

 to trigger a trade the EA checks that THE %D OF all selected stochastic indicators (up to four, based on user selection) have readings below a specified lower level (typically 20) within a defined lookback period. This condition suggests that the market is oversold and may be poised for a bullish move. If the conditions are met,  it looks for a confirmed fractal on the low of the price bar (at shift 2), indicating a possible reversal point. It takes the trade if there are no existing open positions for the symbol and magic number, the EA proceeds to place a buy order.

Upon entering a trade, the EA sets a stop loss a certain number of points below the fractal low, as determined by the StopBuffer input parameter. This helps to limit potential losses if the market moves against the position. To manage the trade and protect profits, the EA implements a trailing stop based on a percentage ( TrailingADR ) of the 14-period Average Daily Range (ADR). As the market moves in favor of the trade, the trailing stop adjusts accordingly, locking in gains while allowing for normal market fluctuations. The lot size for each trade is specified directly through an input parameter ( LotSize ), giving the user control over position sizing based on their risk management preferences.

Requirement:

A: Also buggy Sometimes takes trades When all %D are not below 20. I think it is a bug derived from the indictor code. Developer needs to review code and debug. Also fix any other issue you might find. 

B: provide a way to visual backtest

C:  add 3 moving averages  in the input dialogue. add type for each and period. If any of them are set to true the condition is take trade  Above for long Below for shorts.

D: Add a MACD filter


