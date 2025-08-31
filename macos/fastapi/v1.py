# main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import random
import math
import numpy as np
import uvicorn

app = FastAPI(title="Trading Platform API", version="1.0.0")

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models matching your Flutter models
class StockInfo(BaseModel):
    symbol: str
    name: str
    price: float
    change: float
    change_percent: float
    volume: int
    market_cap: Optional[float] = None
    pe_ratio: Optional[float] = None
    dividend_yield: Optional[float] = None
    fifty_two_week_high: Optional[float] = None
    fifty_two_week_low: Optional[float] = None
    description: Optional[str] = None

class PortfolioStock(BaseModel):
    symbol: str
    weight: float

class Portfolio(BaseModel):
    name: str
    stocks: List[PortfolioStock]
    initial_cash: float = 100000.0

class IndicatorCondition(BaseModel):
    operator: str  # 'less_than', 'greater_than', 'equals'
    value: float

class BacktestIndicator(BaseModel):
    name: str
    period: int = 14
    buy_condition: IndicatorCondition
    sell_condition: IndicatorCondition

class BacktestConfig(BaseModel):
    start_date: str
    end_date: str
    indicators: List[BacktestIndicator]
    strategy_logic: str = "AND"  # "AND" or "OR"
    rebalance_frequency: str = "monthly"  # "daily", "weekly", "monthly", "quarterly"

class BacktestRequest(BaseModel):
    portfolio: Portfolio
    config: BacktestConfig

class PerformancePoint(BaseModel):
    date: str
    value: float
    return_percent: float

class BacktestResult(BaseModel):
    final_value: float
    total_return: float
    total_return_pct: float
    sharpe_ratio: float
    max_drawdown: float
    volatility: float
    total_trades: int = 0
    winning_trades: int = 0
    losing_trades: int = 0
    avg_win: float = 0.0
    avg_loss: float = 0.0
    win_rate: float = 0.0
    performance_history: List[PerformancePoint]
    additional_metrics: Dict[str, float] = {}

class NotificationSetup(BaseModel):
    symbol: str
    indicators: List[str]
    strategy_logic: str = "AND"
    is_active: bool = True

class AlertResponse(BaseModel):
    symbol: str
    signal_type: str  # "BUY" or "SELL"
    price: float
    timestamp: str
    indicators_triggered: List[str] = []

# Mock stock data - In production, integrate with real API like Alpha Vantage, Yahoo Finance, etc.
MOCK_STOCKS = {
    "AAPL": StockInfo(
        symbol="AAPL",
        name="Apple Inc.",
        price=175.43,
        change=2.15,
        change_percent=1.24,
        volume=45678900,
        market_cap=2800000000000,
        pe_ratio=28.5,
        dividend_yield=0.0043,
        fifty_two_week_high=198.23,
        fifty_two_week_low=124.17,
        description="Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide."
    ),
    "GOOGL": StockInfo(
        symbol="GOOGL",
        name="Alphabet Inc.",
        price=2750.12,
        change=-15.67,
        change_percent=-0.57,
        volume=1234567,
        market_cap=1800000000000,
        pe_ratio=25.3,
        dividend_yield=0.0,
        fifty_two_week_high=3030.93,
        fifty_two_week_low=2193.62,
        description="Alphabet Inc. provides online advertising services in the United States, Europe, the Middle East, Africa, the Asia-Pacific, Canada, and Latin America."
    ),
    "TSLA": StockInfo(
        symbol="TSLA",
        name="Tesla, Inc.",
        price=245.67,
        change=8.32,
        change_percent=3.51,
        volume=23456789,
        market_cap=780000000000,
        pe_ratio=65.2,
        dividend_yield=0.0,
        fifty_two_week_high=414.50,
        fifty_two_week_low=101.81,
        description="Tesla, Inc. designs, develops, manufactures, leases, and sells electric vehicles, and energy generation and storage systems."
    ),
    "MSFT": StockInfo(
        symbol="MSFT",
        name="Microsoft Corporation",
        price=338.11,
        change=4.23,
        change_percent=1.27,
        volume=12345678,
        market_cap=2500000000000,
        pe_ratio=32.1,
        dividend_yield=0.0072,
        fifty_two_week_high=384.30,
        fifty_two_week_low=213.43,
        description="Microsoft Corporation develops, licenses, and supports software, services, devices, and solutions worldwide."
    ),
    "AMZN": StockInfo(
        symbol="AMZN",
        name="Amazon.com Inc.",
        price=145.32,
        change=-2.18,
        change_percent=-1.48,
        volume=18765432,
        market_cap=1500000000000,
        pe_ratio=45.8,
        dividend_yield=0.0,
        fifty_two_week_high=188.11,
        fifty_two_week_low=118.35,
        description="Amazon.com Inc. engages in the retail sale of consumer products and subscriptions in North America and internationally."
    ),
    "NVDA": StockInfo(
        symbol="NVDA",
        name="NVIDIA Corporation",
        price=875.28,
        change=23.45,
        change_percent=2.75,
        volume=8765432,
        market_cap=2200000000000,
        pe_ratio=58.3,
        dividend_yield=0.0012,
        fifty_two_week_high=950.02,
        fifty_two_week_low=180.96,
        description="NVIDIA Corporation operates as a visual computing company worldwide."
    ),
    "META": StockInfo(
        symbol="META",
        name="Meta Platforms Inc.",
        price=298.75,
        change=5.67,
        change_percent=1.94,
        volume=12987654,
        market_cap=800000000000,
        pe_ratio=22.4,
        dividend_yield=0.0035,
        fifty_two_week_high=384.33,
        fifty_two_week_low=185.82,
        description="Meta Platforms Inc. develops products that enable people to connect and share with friends and family through mobile devices, personal computers, virtual reality headsets, and wearables worldwide."
    ),
    "BRK.B": StockInfo(
        symbol="BRK.B",
        name="Berkshire Hathaway Inc.",
        price=354.82,
        change=1.23,
        change_percent=0.35,
        volume=2345678,
        market_cap=850000000000,
        pe_ratio=18.9,
        dividend_yield=0.0,
        fifty_two_week_high=365.14,
        fifty_two_week_low=295.04,
        description="Berkshire Hathaway Inc., through its subsidiaries, engages in the insurance, freight rail transportation, and utility businesses worldwide."
    ),
    "JPM": StockInfo(
        symbol="JPM",
        name="JPMorgan Chase & Co.",
        price=142.56,
        change=-0.89,
        change_percent=-0.62,
        volume=9876543,
        market_cap=420000000000,
        pe_ratio=12.8,
        dividend_yield=0.0285,
        fifty_two_week_high=148.36,
        fifty_two_week_low=126.06,
        description="JPMorgan Chase & Co. operates as a financial services company worldwide."
    ),
    "V": StockInfo(
        symbol="V",
        name="Visa Inc.",
        price=245.18,
        change=3.24,
        change_percent=1.34,
        volume=5432167,
        market_cap=520000000000,
        pe_ratio=29.7,
        dividend_yield=0.0075,
        fifty_two_week_high=250.46,
        fifty_two_week_low=201.73,
        description="Visa Inc. operates as a payments technology company worldwide."
    )
}

def add_price_volatility(base_price: float) -> tuple:
    """Add realistic price volatility to mock data"""
    volatility = random.uniform(-0.05, 0.05)  # ±5% daily volatility
    new_price = base_price * (1 + volatility)
    change = new_price - base_price
    change_percent = (change / base_price) * 100
    return new_price, change, change_percent

def calculate_rsi(prices: List[float], period: int = 14) -> float:
    """Calculate RSI indicator"""
    if len(prices) < period + 1:
        return 50.0  # Neutral RSI
    
    gains = []
    losses = []
    
    for i in range(1, len(prices)):
        change = prices[i] - prices[i-1]
        if change > 0:
            gains.append(change)
            losses.append(0)
        else:
            gains.append(0)
            losses.append(abs(change))
    
    if len(gains) < period:
        return 50.0
        
    avg_gain = sum(gains[-period:]) / period
    avg_loss = sum(losses[-period:]) / period
    
    if avg_loss == 0:
        return 100.0
    
    rs = avg_gain / avg_loss
    rsi = 100 - (100 / (1 + rs))
    return rsi

def generate_stock_price_history(base_price: float, days: int) -> List[float]:
    """Generate realistic stock price history"""
    prices = [base_price]
    
    for _ in range(days):
        # Random walk with slight upward bias
        daily_return = random.normalvariate(0.0008, 0.02)  # 0.08% daily average, 2% volatility
        new_price = prices[-1] * (1 + daily_return)
        prices.append(max(new_price, 0.01))  # Prevent negative prices
    
    return prices

def simulate_backtest(portfolio: Portfolio, config: BacktestConfig) -> BacktestResult:
    """Simulate a realistic backtest based on portfolio and configuration"""
    
    # Parse dates
    start_date = datetime.strptime(config.start_date, "%Y-%m-%d")
    end_date = datetime.strptime(config.end_date, "%Y-%m-%d")
    duration_days = (end_date - start_date).days
    
    if duration_days <= 0:
        raise HTTPException(status_code=400, detail="End date must be after start date")
    
    # Generate price histories for all stocks in portfolio
    stock_histories = {}
    for stock in portfolio.stocks:
        base_price = MOCK_STOCKS.get(stock.symbol, 
                                   StockInfo(symbol=stock.symbol, name=f"{stock.symbol} Corp", 
                                           price=100.0, change=0, change_percent=0, volume=1000000)).price
        stock_histories[stock.symbol] = generate_stock_price_history(base_price, duration_days + 1)
    
    # Calculate portfolio performance
    portfolio_values = []
    current_date = start_date
    
    for day in range(duration_days + 1):
        portfolio_value = 0.0
        
        for stock in portfolio.stocks:
            if stock.symbol in stock_histories:
                stock_price = stock_histories[stock.symbol][day]
                stock_allocation = portfolio.initial_cash * (stock.weight / 100.0)
                shares = stock_allocation / stock_histories[stock.symbol][0]  # Initial shares
                portfolio_value += shares * stock_price
        
        portfolio_values.append(portfolio_value)
        
        # Apply indicator-based trading signals (simplified)
        if config.indicators and day > 14:  # Need some history for indicators
            for indicator in config.indicators:
                if indicator.name.upper() == "RSI":
                    # Calculate portfolio-wide RSI (simplified)
                    rsi = calculate_rsi(portfolio_values[-15:], indicator.period)
                    
                    # Apply trading logic (very simplified)
                    if rsi < indicator.buy_condition.value:
                        portfolio_values[-1] *= 1.001  # Small boost for buy signal
                    elif rsi > indicator.sell_condition.value:
                        portfolio_values[-1] *= 0.999  # Small reduction for sell signal
        
        current_date += timedelta(days=1)
    
    # Calculate metrics
    final_value = portfolio_values[-1]
    total_return = final_value - portfolio.initial_cash
    total_return_pct = (total_return / portfolio.initial_cash) * 100
    
    # Calculate volatility (annualized)
    daily_returns = []
    for i in range(1, len(portfolio_values)):
        daily_return = (portfolio_values[i] - portfolio_values[i-1]) / portfolio_values[i-1]
        daily_returns.append(daily_return)
    
    volatility = np.std(daily_returns) * np.sqrt(252) * 100  # Annualized volatility
    
    # Calculate Sharpe ratio (assuming 2% risk-free rate)
    risk_free_rate = 2.0
    sharpe_ratio = (total_return_pct - risk_free_rate) / volatility if volatility > 0 else 0
    
    # Calculate max drawdown
    running_max = portfolio.initial_cash
    max_drawdown = 0.0
    for value in portfolio_values:
        if value > running_max:
            running_max = value
        drawdown = (running_max - value) / running_max * 100
        max_drawdown = max(max_drawdown, drawdown)
    
    # Trading statistics (simplified)
    total_trades = max(1, duration_days // 30)  # Roughly monthly rebalancing
    winning_trades = int(total_trades * random.uniform(0.4, 0.7))  # 40-70% win rate
    losing_trades = total_trades - winning_trades
    
    avg_win = abs(total_return / max(winning_trades, 1)) * 1.2 if winning_trades > 0 else 0
    avg_loss = abs(total_return / max(losing_trades, 1)) * 0.8 if losing_trades > 0 else 0
    win_rate = (winning_trades / total_trades * 100) if total_trades > 0 else 0
    
    # Generate performance history (weekly points)
    performance_history = []
    week_interval = max(1, duration_days // 52)  # Weekly data points
    
    for i in range(0, len(portfolio_values), week_interval):
        date_point = start_date + timedelta(days=i)
        value = portfolio_values[i]
        return_pct = ((value - portfolio.initial_cash) / portfolio.initial_cash) * 100
        
        performance_history.append(PerformancePoint(
            date=date_point.isoformat(),
            value=value,
            return_percent=return_pct
        ))
    
    return BacktestResult(
        final_value=final_value,
        total_return=total_return,
        total_return_pct=total_return_pct,
        sharpe_ratio=sharpe_ratio,
        max_drawdown=-max_drawdown,
        volatility=volatility,
        total_trades=total_trades,
        winning_trades=winning_trades,
        losing_trades=losing_trades,
        avg_win=avg_win,
        avg_loss=avg_loss,
        win_rate=win_rate,
        performance_history=performance_history,
        additional_metrics={
            "beta": random.uniform(0.8, 1.4),
            "alpha": (total_return_pct - 8) / 100,  # Excess return over 8% market
            "correlation": random.uniform(0.6, 0.9)
        }
    )

# API Endpoints

@app.get("/")
async def root():
    return {"message": "Trading Platform API", "version": "1.0.0"}

@app.get("/search/{query}")
async def search_stocks(query: str):
    """Search for stocks by symbol or name"""
    query_lower = query.lower()
    results = []
    
    for symbol, stock in MOCK_STOCKS.items():
        if (query_lower in symbol.lower() or 
            query_lower in stock.name.lower()):
            
            # Add some realistic price volatility
            new_price, change, change_percent = add_price_volatility(stock.price)
            updated_stock = stock.copy()
            updated_stock.price = new_price
            updated_stock.change = change
            updated_stock.change_percent = change_percent
            
            results.append(updated_stock)
    
    return {"results": results}

@app.get("/stock/{symbol}")
async def get_stock_details(symbol: str):
    """Get detailed information for a specific stock"""
    symbol_upper = symbol.upper()
    
    if symbol_upper not in MOCK_STOCKS:
        raise HTTPException(status_code=404, detail=f"Stock {symbol} not found")
    
    stock = MOCK_STOCKS[symbol_upper]
    new_price, change, change_percent = add_price_volatility(stock.price)
    
    updated_stock = stock.copy()
    updated_stock.price = new_price
    updated_stock.change = change
    updated_stock.change_percent = change_percent
    
    return updated_stock

@app.post("/portfolio/backtest/custom", response_model=BacktestResult)
async def run_custom_backtest(request: BacktestRequest):
    """Run a backtest with custom configuration"""
    try:
        result = simulate_backtest(request.portfolio, request.config)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/portfolio/backtest")
async def run_simple_backtest(portfolio: Portfolio):
    """Run a basic backtest with default settings"""
    # Default configuration
    default_config = BacktestConfig(
        start_date="2023-01-01",
        end_date="2023-12-31",
        indicators=[
            BacktestIndicator(
                name="RSI",
                period=14,
                buy_condition=IndicatorCondition(operator="less_than", value=30),
                sell_condition=IndicatorCondition(operator="greater_than", value=70)
            )
        ],
        strategy_logic="AND",
        rebalance_frequency="monthly"
    )
    
    try:
        result = simulate_backtest(portfolio, default_config)
        
        # Return in legacy format for compatibility
        return {
            "final_value": result.final_value,
            "total_return": result.total_return,
            "total_return_pct": result.total_return_pct,
            "sharpe_ratio": result.sharpe_ratio,
            "max_drawdown": result.max_drawdown,
            "win_rate": result.win_rate,
            "total_trades": result.total_trades
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/notifications/check/{symbol}")
async def check_alerts(symbol: str):
    """Check for alerts on a specific symbol"""
    alerts = []
    
    # Simulate alert generation (5% chance every minute)
    if random.random() < 0.05:
        signal_type = random.choice(["BUY", "SELL"])
        base_price = MOCK_STOCKS.get(symbol.upper(), 
                                   StockInfo(symbol=symbol, name=f"{symbol} Corp", 
                                           price=100.0, change=0, change_percent=0, volume=1000000)).price
        
        current_price = base_price * random.uniform(0.95, 1.05)
        
        alert = AlertResponse(
            symbol=symbol.upper(),
            signal_type=signal_type,
            price=current_price,
            timestamp=datetime.now().isoformat(),
            indicators_triggered=["RSI"] if signal_type == "BUY" else ["MACD"]
        )
        alerts.append(alert)
    
    return {"alerts": alerts}

@app.post("/notifications/create")
async def create_notification(notification: NotificationSetup):
    """Create a new notification setup"""
    # In a real app, you'd store this in a database
    return {
        "message": f"Notification created for {notification.symbol}",
        "notification_id": random.randint(1000, 9999)
    }

@app.get("/market/status")
async def get_market_status():
    """Get current market status"""
    now = datetime.now()
    is_open = 9 <= now.hour < 16 and now.weekday() < 5  # Simplified market hours
    
    return {
        "is_open": is_open,
        "current_time": now.isoformat(),
        "next_open": "2024-01-01T09:00:00" if not is_open else None,
        "session": "regular" if is_open else "closed"
    }

@app.get("/market/movers")
async def get_market_movers():
    """Get top market movers"""
    movers = []
    stock_list = list(MOCK_STOCKS.values())
    random.shuffle(stock_list)
    
    for stock in stock_list[:5]:  # Top 5 movers
        new_price, change, change_percent = add_price_volatility(stock.price)
        updated_stock = stock.copy()
        updated_stock.price = new_price
        updated_stock.change = change
        updated_stock.change_percent = change_percent
        movers.append(updated_stock)
    
    # Sort by absolute change percentage
    movers.sort(key=lambda x: abs(x.change_percent), reverse=True)
    
    return {"movers": movers}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)