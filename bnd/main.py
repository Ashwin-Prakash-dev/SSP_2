from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
import backtrader as bt
import yfinance as yf
import traceback
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Optional, List
import requests
import json

app = FastAPI(title="Stock Analysis & Backtest API", version="1.0.0")

# Add CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class StockSuggestion(BaseModel):
    symbol: str
    company_name: str
    match_type: str = "symbol"

class StrategyInput(BaseModel):
    ticker: str = Field(..., min_length=1, max_length=10, description="Stock ticker symbol")
    start_date: str = Field(..., description="Start date in YYYY-MM-DD format")
    end_date: str = Field(..., description="End date in YYYY-MM-DD format")
    strategy: str = Field(default="RSI", description="Strategy type")
    rsi_period: int = Field(default=14, ge=5, le=50, description="RSI calculation period")
    rsi_buy: int = Field(default=30, ge=0, le=100, description="RSI buy threshold")
    rsi_sell: int = Field(default=70, ge=0, le=100, description="RSI sell threshold")
    initial_cash: float = Field(default=100000.0, ge=1000, description="Initial portfolio value")

    @validator('ticker')
    def ticker_must_be_uppercase(cls, v):
        return v.upper().strip()

    @validator('start_date', 'end_date')
    def validate_date_format(cls, v):
        try:
            datetime.strptime(v, '%Y-%m-%d')
            return v
        except ValueError:
            raise ValueError('Date must be in YYYY-MM-DD format')

    @validator('rsi_sell')
    def rsi_sell_must_be_greater_than_buy(cls, v, values):
        if 'rsi_buy' in values and v <= values['rsi_buy']:
            raise ValueError('RSI sell threshold must be greater than buy threshold')
        return v

class BacktestResult(BaseModel):
    final_value: float
    initial_value: float
    total_return: float
    total_return_pct: float
    total_trades: int
    winning_trades: int
    losing_trades: int
    win_rate: float
    max_drawdown: float

class StockInfo(BaseModel):
    symbol: str
    company_name: str
    sector: str
    current_price: float
    change: float
    change_percent: float
    volume: int
    market_cap: float
    pe_ratio: float
    
    # Technical indicators
    support_level: float
    resistance_level: float
    rsi: float
    macd: float
    stochastic_k: float
    stochastic_d: float
    
    # Fibonacci levels
    fib_236: float
    fib_382: float
    fib_500: float
    fib_618: float
    
    # Sentiment data
    overall_sentiment: str
    sentiment_score: float
    short_term_sentiment: str
    short_term_score: float
    long_term_sentiment: str
    long_term_score: float
    sentiment_factors: list
    
    # Analyst data
    analyst_buy: int
    analyst_hold: int
    analyst_sell: int
    target_price: float

# Popular stock symbols for suggestions - expanded list
POPULAR_STOCKS = {
    # Technology
    'AAPL': 'Apple Inc.',
    'MSFT': 'Microsoft Corporation',
    'GOOGL': 'Alphabet Inc. Class A',
    'GOOG': 'Alphabet Inc. Class C',
    'AMZN': 'Amazon.com Inc.',
    'TSLA': 'Tesla Inc.',
    'META': 'Meta Platforms Inc.',
    'NVDA': 'NVIDIA Corporation',
    'NFLX': 'Netflix Inc.',
    'ORCL': 'Oracle Corporation',
    'ADBE': 'Adobe Inc.',
    'CRM': 'Salesforce Inc.',
    'INTC': 'Intel Corporation',
    'AMD': 'Advanced Micro Devices Inc.',
    'IBM': 'International Business Machines Corporation',
    
    # Financial
    'JPM': 'JPMorgan Chase & Co.',
    'BAC': 'Bank of America Corporation',
    'WFC': 'Wells Fargo & Company',
    'GS': 'The Goldman Sachs Group Inc.',
    'MS': 'Morgan Stanley',
    'C': 'Citigroup Inc.',
    'BRK.A': 'Berkshire Hathaway Inc. Class A',
    'BRK.B': 'Berkshire Hathaway Inc. Class B',
    'V': 'Visa Inc.',
    'MA': 'Mastercard Incorporated',
    'PYPL': 'PayPal Holdings Inc.',
    'AXP': 'American Express Company',
    
    # Healthcare
    'JNJ': 'Johnson & Johnson',
    'PFE': 'Pfizer Inc.',
    'UNH': 'UnitedHealth Group Incorporated',
    'ABBV': 'AbbVie Inc.',
    'TMO': 'Thermo Fisher Scientific Inc.',
    'ABT': 'Abbott Laboratories',
    'DHR': 'Danaher Corporation',
    'BMY': 'Bristol-Myers Squibb Company',
    'LLY': 'Eli Lilly and Company',
    'MRK': 'Merck & Co. Inc.',
    
    # Consumer
    'WMT': 'Walmart Inc.',
    'PG': 'The Procter & Gamble Company',
    'KO': 'The Coca-Cola Company',
    'PEP': 'PepsiCo Inc.',
    'NKE': 'NIKE Inc.',
    'MCD': 'McDonald\'s Corporation',
    'SBUX': 'Starbucks Corporation',
    'HD': 'The Home Depot Inc.',
    'TGT': 'Target Corporation',
    'COST': 'Costco Wholesale Corporation',
    
    # Energy
    'XOM': 'Exxon Mobil Corporation',
    'CVX': 'Chevron Corporation',
    'COP': 'ConocoPhillips',
    'SLB': 'Schlumberger Limited',
    'EOG': 'EOG Resources Inc.',
    
    # Industrial
    'BA': 'The Boeing Company',
    'GE': 'General Electric Company',
    'CAT': 'Caterpillar Inc.',
    'MMM': '3M Company',
    'HON': 'Honeywell International Inc.',
    
    # Telecommunications
    'VZ': 'Verizon Communications Inc.',
    'T': 'AT&T Inc.',
    'TMUS': 'T-Mobile US Inc.',
    
    # Real Estate
    'AMT': 'American Tower Corporation',
    'PLD': 'Prologis Inc.',
    'CCI': 'Crown Castle International Corp.',
}

class RSIStrategy(bt.Strategy):
    params = (
        ("rsi_period", 14),
        ("rsi_buy", 30),
        ("rsi_sell", 70),
    )

    def __init__(self):
        self.rsi = bt.indicators.RSI_SMA(self.data.close, period=self.params.rsi_period)
        self.trade_count = 0
        self.winning_trades = 0
        self.losing_trades = 0

    def next(self):
        if not self.position:
            # Buy signal: RSI below buy threshold
            if self.rsi < self.params.rsi_buy:
                self.buy(size=None)  # Buy with all available cash
        else:
            # Sell signal: RSI above sell threshold
            if self.rsi > self.params.rsi_sell:
                self.sell(size=self.position.size)

    def notify_trade(self, trade):
        if trade.isclosed:
            self.trade_count += 1
            if trade.pnl > 0:
                self.winning_trades += 1
            else:
                self.losing_trades += 1

def calculate_rsi(prices, window=14):
    """Calculate RSI manually without TA-Lib"""
    try:
        delta = pd.Series(prices).diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=window).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=window).mean()
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return float(rsi.iloc[-1]) if not pd.isna(rsi.iloc[-1]) else 50.0
    except:
        return 50.0

def calculate_macd(prices, fast=12, slow=26, signal=9):
    """Calculate MACD manually without TA-Lib"""
    try:
        prices_series = pd.Series(prices)
        exp1 = prices_series.ewm(span=fast).mean()
        exp2 = prices_series.ewm(span=slow).mean()
        macd = exp1 - exp2
        return float(macd.iloc[-1]) if not pd.isna(macd.iloc[-1]) else 0.0
    except:
        return 0.0

def calculate_stochastic(high, low, close, k_period=14, d_period=3):
    """Calculate Stochastic Oscillator manually without TA-Lib"""
    try:
        high_series = pd.Series(high)
        low_series = pd.Series(low)
        close_series = pd.Series(close)
        
        lowest_low = low_series.rolling(window=k_period).min()
        highest_high = high_series.rolling(window=k_period).max()
        
        k_percent = 100 * ((close_series - lowest_low) / (highest_high - lowest_low))
        d_percent = k_percent.rolling(window=d_period).mean()
        
        k_val = float(k_percent.iloc[-1]) if not pd.isna(k_percent.iloc[-1]) else 50.0
        d_val = float(d_percent.iloc[-1]) if not pd.isna(d_percent.iloc[-1]) else 50.0
        
        return k_val, d_val
    except:
        return 50.0, 50.0

def calculate_support_resistance(df, window=20):
    """Calculate support and resistance levels using pivot points"""
    try:
        high_prices = df['High'].rolling(window=window).max()
        low_prices = df['Low'].rolling(window=window).min()
        
        # Recent support and resistance
        recent_high = high_prices.iloc[-1] if len(high_prices) > 0 else df['Close'].iloc[-1]
        recent_low = low_prices.iloc[-1] if len(low_prices) > 0 else df['Close'].iloc[-1]
        
        return recent_low, recent_high
    except:
        current_price = df['Close'].iloc[-1]
        return current_price * 0.95, current_price * 1.05

def calculate_fibonacci_levels(df, periods=50):
    """Calculate Fibonacci retracement levels"""
    try:
        recent_data = df.tail(periods)
        high = recent_data['High'].max()
        low = recent_data['Low'].min()
        diff = high - low
        
        return {
            'fib_236': high - (diff * 0.236),
            'fib_382': high - (diff * 0.382),
            'fib_500': high - (diff * 0.500),
            'fib_618': high - (diff * 0.618),
        }
    except:
        current_price = df['Close'].iloc[-1]
        return {
            'fib_236': current_price * 0.98,
            'fib_382': current_price * 0.95,
            'fib_500': current_price * 0.92,
            'fib_618': current_price * 0.90,
        }

def calculate_technical_indicators(df):
    """Calculate various technical indicators using manual calculations"""
    try:
        close_prices = df['Close'].values
        high_prices = df['High'].values
        low_prices = df['Low'].values
        
        # RSI
        rsi = calculate_rsi(close_prices, window=14)
        
        # MACD
        macd_value = calculate_macd(close_prices)
        
        # Stochastic
        stoch_k, stoch_d = calculate_stochastic(high_prices, low_prices, close_prices)
        
        return {
            'rsi': rsi,
            'macd': macd_value,
            'stochastic_k': stoch_k,
            'stochastic_d': stoch_d,
        }
    except Exception as e:
        print(f"Error calculating indicators: {e}")
        return {
            'rsi': 50.0,
            'macd': 0.0,
            'stochastic_k': 50.0,
            'stochastic_d': 50.0,
        }

def generate_sentiment_data(symbol, current_price, change_percent):
    """Generate mock sentiment data based on price movement"""
    try:
        # Simple sentiment based on price movement
        if change_percent > 2:
            overall_sentiment = "Bullish"
            sentiment_score = 7.5
            short_term = "Positive"
            short_term_score = 8.0
        elif change_percent < -2:
            overall_sentiment = "Bearish"
            sentiment_score = 3.0
            short_term = "Negative"
            short_term_score = 2.5
        else:
            overall_sentiment = "Neutral"
            sentiment_score = 5.5
            short_term = "Neutral"
            short_term_score = 5.0
        
        # Mock sentiment factors
        factors = [
            {"factor": "Market Trends", "impact": "Positive" if change_percent > 0 else "Negative"},
            {"factor": "Company Earnings", "impact": "Neutral"},
            {"factor": "Industry Growth", "impact": "Positive"},
            {"factor": "Economic Indicators", "impact": "Neutral"},
        ]
        
        return {
            'overall_sentiment': overall_sentiment,
            'sentiment_score': sentiment_score,
            'short_term_sentiment': short_term,
            'short_term_score': short_term_score,
            'long_term_sentiment': "Bullish",
            'long_term_score': 6.5,
            'sentiment_factors': factors,
        }
    except:
        return {
            'overall_sentiment': "Neutral",
            'sentiment_score': 5.0,
            'short_term_sentiment': "Neutral",
            'short_term_score': 5.0,
            'long_term_sentiment': "Neutral",
            'long_term_score': 5.0,
            'sentiment_factors': [{"factor": "Market Analysis", "impact": "Neutral"}],
        }

def search_stock_suggestions(query: str, limit: int = 10) -> List[StockSuggestion]:
    """Search for stock suggestions based on query"""
    suggestions = []
    query_upper = query.upper().strip()
    query_lower = query.lower().strip()
    
    if not query_upper:
        return []
    
    # First, search by exact symbol match
    for symbol, name in POPULAR_STOCKS.items():
        if symbol == query_upper:
            suggestions.append(StockSuggestion(
                symbol=symbol,
                company_name=name,
                match_type="symbol"
            ))
    
    # Then, search by symbol prefix
    for symbol, name in POPULAR_STOCKS.items():
        if symbol != query_upper and symbol.startswith(query_upper):
            suggestions.append(StockSuggestion(
                symbol=symbol,
                company_name=name,
                match_type="symbol"
            ))
    
    # Then, search by company name
    for symbol, name in POPULAR_STOCKS.items():
        if (symbol not in [s.symbol for s in suggestions] and 
            query_lower in name.lower()):
            suggestions.append(StockSuggestion(
                symbol=symbol,
                company_name=name,
                match_type="company"
            ))
    
    # Try to validate with yfinance for unknown symbols
    if len(suggestions) == 0 and len(query_upper) <= 5:
        try:
            # Quick validation with yfinance
            ticker = yf.Ticker(query_upper)
            info = ticker.info
            if info and 'longName' in info:
                suggestions.append(StockSuggestion(
                    symbol=query_upper,
                    company_name=info.get('longName', f"{query_upper} Corporation"),
                    match_type="symbol"
                ))
        except:
            pass  # If validation fails, just return empty list
    
    return suggestions[:limit]

@app.get("/")
def read_root():
    return {"message": "Stock Analysis & Backtest API is running"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/stock-suggestions", response_model=List[StockSuggestion])
def get_stock_suggestions(q: str = Query(..., min_length=1, description="Search query for stock symbols or company names")):
    """Get stock suggestions based on search query"""
    try:
        suggestions = search_stock_suggestions(q, limit=10)
        return suggestions
    except Exception as e:
        print(f"Error in stock suggestions: {str(e)}")
        # Return empty list instead of error to prevent Flutter app crashes
        return []

@app.get("/stock-info/{symbol}", response_model=StockInfo)
def get_stock_info(symbol: str):
    try:
        symbol = symbol.upper().strip()
        
        # Download recent stock data (last 3 months for analysis)
        end_date = datetime.now()
        start_date = end_date - timedelta(days=90)
        
        stock = yf.Ticker(symbol)
        df = yf.download(symbol, start=start_date, end=end_date, progress=False)
        
        if df.empty:
            raise HTTPException(status_code=404, detail=f"Stock symbol '{symbol}' not found")
        
        # Handle multi-level columns
        if isinstance(df.columns, pd.MultiIndex):
            df.columns = [col[0] if isinstance(col, tuple) else col for col in df.columns]
        
        # Get stock info
        info = stock.info
        current_price = df['Close'].iloc[-1]
        previous_close = df['Close'].iloc[-2] if len(df) > 1 else current_price
        change = current_price - previous_close
        change_percent = (change / previous_close) * 100
        
        # Calculate technical indicators
        support, resistance = calculate_support_resistance(df)
        fib_levels = calculate_fibonacci_levels(df)
        tech_indicators = calculate_technical_indicators(df)
        sentiment_data = generate_sentiment_data(symbol, current_price, change_percent)
        
        return StockInfo(
            symbol=symbol,
            company_name=info.get('longName', f"{symbol} Corporation"),
            sector=info.get('sector', 'Technology'),
            current_price=float(current_price),
            change=float(change),
            change_percent=float(change_percent),
            volume=int(df['Volume'].iloc[-1]),
            market_cap=float(info.get('marketCap', 0)),
            pe_ratio=float(info.get('trailingPE', 0)) if info.get('trailingPE') else 0.0,
            
            # Technical levels
            support_level=float(support),
            resistance_level=float(resistance),
            rsi=tech_indicators['rsi'],
            macd=tech_indicators['macd'],
            stochastic_k=tech_indicators['stochastic_k'],
            stochastic_d=tech_indicators['stochastic_d'],
            
            # Fibonacci levels
            fib_236=float(fib_levels['fib_236']),
            fib_382=float(fib_levels['fib_382']),
            fib_500=float(fib_levels['fib_500']),
            fib_618=float(fib_levels['fib_618']),
            
            # Sentiment data
            overall_sentiment=sentiment_data['overall_sentiment'],
            sentiment_score=sentiment_data['sentiment_score'],
            short_term_sentiment=sentiment_data['short_term_sentiment'],
            short_term_score=sentiment_data['short_term_score'],
            long_term_sentiment=sentiment_data['long_term_sentiment'],
            long_term_score=sentiment_data['long_term_score'],
            sentiment_factors=sentiment_data['sentiment_factors'],
            
            # Mock analyst data based on sentiment and price movement
            analyst_buy=max(1, int(5 + (change_percent * 0.5) + np.random.normal(0, 1))),
            analyst_hold=max(1, int(3 + np.random.normal(0, 0.5))),
            analyst_sell=max(0, int(2 - (change_percent * 0.3) + np.random.normal(0, 0.5))),
            target_price=float(current_price * np.random.uniform(1.05, 1.15)),
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error fetching stock info: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Failed to fetch stock information: {str(e)}")

@app.post("/backtest", response_model=BacktestResult)
def run_backtest(data: StrategyInput):
    try:
        # Validate date range
        start_dt = datetime.strptime(data.start_date, '%Y-%m-%d')
        end_dt = datetime.strptime(data.end_date, '%Y-%m-%d')
        
        if start_dt >= end_dt:
            raise HTTPException(status_code=400, detail="Start date must be before end date")
        
        if end_dt > datetime.now():
            raise HTTPException(status_code=400, detail="End date cannot be in the future")

        # Create Cerebro engine
        cerebro = bt.Cerebro()
        
        # Add strategy
        cerebro.addstrategy(
            RSIStrategy,
            rsi_period=data.rsi_period,
            rsi_buy=data.rsi_buy,
            rsi_sell=data.rsi_sell
        )

        # Download stock data
        try:
            df = yf.download(data.ticker, start=data.start_date, end=data.end_date, progress=False)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to download data for {data.ticker}: {str(e)}")

        # Handle multi-level columns if present
        if isinstance(df.columns, pd.MultiIndex):
            df.columns = [col[0] if isinstance(col, tuple) else col for col in df.columns]

        if df is None or df.empty:
            raise HTTPException(status_code=404, detail=f"No data found for {data.ticker} in the specified date range")

        # Reset index to make Date a column
        df.reset_index(inplace=True)

        # Ensure required columns exist
        required_columns = ['Date', 'Open', 'High', 'Low', 'Close', 'Volume']
        missing_columns = [col for col in required_columns if col not in df.columns]
        if missing_columns:
            raise HTTPException(status_code=400, detail=f"Missing required columns: {missing_columns}")

        # Create data feed
        data_feed = bt.feeds.PandasData(
            dataname=df,
            datetime='Date',
            open='Open',
            high='High',
            low='Low',
            close='Close',
            volume='Volume',
            openinterest=None
        )

        cerebro.adddata(data_feed)
        
        # Set initial cash
        cerebro.broker.set_cash(data.initial_cash)
        initial_value = cerebro.broker.getvalue()

        # Add analyzers
        cerebro.addanalyzer(bt.analyzers.TradeAnalyzer, _name="trades")
        cerebro.addanalyzer(bt.analyzers.DrawDown, _name="drawdown")

        # Run backtest
        results = cerebro.run()
        final_value = cerebro.broker.getvalue()

        # Extract strategy and analyzers
        strategy = results[0]
        trade_analyzer = strategy.analyzers.trades.get_analysis()
        drawdown_analyzer = strategy.analyzers.drawdown.get_analysis()

        # Calculate metrics
        total_return = final_value - initial_value
        total_return_pct = (total_return / initial_value) * 100
        
        total_trades = trade_analyzer.get('total', {}).get('total', 0)
        won_trades = trade_analyzer.get('won', {}).get('total', 0)
        lost_trades = trade_analyzer.get('lost', {}).get('total', 0)
        win_rate = (won_trades / total_trades * 100) if total_trades > 0 else 0
        max_drawdown = drawdown_analyzer.get('max', {}).get('drawdown', 0)

        return BacktestResult(
            final_value=round(final_value, 2),
            initial_value=round(initial_value, 2),
            total_return=round(total_return, 2),
            total_return_pct=round(total_return_pct, 2),
            total_trades=total_trades,
            winning_trades=won_trades,
            losing_trades=lost_trades,
            win_rate=round(win_rate, 2),
            max_drawdown=round(max_drawdown, 2)
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)