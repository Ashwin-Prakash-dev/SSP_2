class StockInfo {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final int volume;
  final double? marketCap;
  final double? peRatio;
  final double? dividendYield;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final String? description;

  StockInfo({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    this.marketCap,
    this.peRatio,
    this.dividendYield,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.description,
  });

  factory StockInfo.fromJson(Map<String, dynamic> json) {
    return StockInfo(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['change_percent'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
      marketCap: json['market_cap']?.toDouble(),
      peRatio: json['pe_ratio']?.toDouble(),
      dividendYield: json['dividend_yield']?.toDouble(),
      fiftyTwoWeekHigh: json['fifty_two_week_high']?.toDouble(),
      fiftyTwoWeekLow: json['fifty_two_week_low']?.toDouble(),
      description: json['description'],
    );
  }
}

class Portfolio {
  String name;
  List<PortfolioStock> stocks;
  double initialCash;

  Portfolio({
    required this.name,
    required this.stocks,
    this.initialCash = 100000.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stocks': stocks.map((stock) => stock.toJson()).toList(),
      'initial_cash': initialCash,
    };
  }
}

class PortfolioStock {
  String symbol;
  double weight;
  StockInfo? stockInfo;

  PortfolioStock({
    required this.symbol,
    required this.weight,
    this.stockInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'weight': weight,
    };
  }
}

class NotificationSetup {
  String symbol;
  List<String> indicators;
  String strategyLogic;
  bool isActive;

  NotificationSetup({
    required this.symbol,
    required this.indicators,
    this.strategyLogic = "AND",
    this.isActive = true,
  });
}

// Backtest-related models
class BacktestConfig {
  final DateTime startDate;
  final DateTime endDate;
  final List<BacktestIndicator> indicators;
  final String strategyLogic;
  final String rebalanceFrequency;

  BacktestConfig({
    required this.startDate,
    required this.endDate,
    required this.indicators,
    required this.strategyLogic,
    required this.rebalanceFrequency,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'indicators': indicators.map((i) => i.toJson()).toList(),
      'strategy_logic': strategyLogic,
      'rebalance_frequency': rebalanceFrequency,
    };
  }

  int get durationInDays => endDate.difference(startDate).inDays;
}

class BacktestIndicator {
  final String name;
  int period; // Made mutable for dialog editing
  final IndicatorCondition buyCondition;
  final IndicatorCondition sellCondition;

  BacktestIndicator({
    required this.name,
    required this.period,
    required this.buyCondition,
    required this.sellCondition,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'period': period,
      'buy_condition': buyCondition.toJson(),
      'sell_condition': sellCondition.toJson(),
    };
  }
}

class IndicatorCondition {
  String operator; // Made mutable for dialog editing
  double value; // Made mutable for dialog editing

  IndicatorCondition({
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'operator': operator,
      'value': value,
    };
  }
}

class BacktestResult {
  final double finalValue;
  final double totalReturn;
  final double totalReturnPercent;
  final double sharpeRatio;
  final double maxDrawdown;
  final double volatility;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final double avgWin;
  final double avgLoss;
  final List<PerformancePoint> performanceHistory;
  final Map<String, dynamic> additionalMetrics;

  BacktestResult({
    required this.finalValue,
    required this.totalReturn,
    required this.totalReturnPercent,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.volatility,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.avgWin,
    required this.avgLoss,
    required this.performanceHistory,
    required this.additionalMetrics,
  });

  factory BacktestResult.fromJson(Map<String, dynamic> json) {
    return BacktestResult(
      finalValue: (json['final_value'] ?? 0).toDouble(),
      totalReturn: (json['total_return'] ?? 0).toDouble(),
      totalReturnPercent: (json['total_return_pct'] ?? 0).toDouble(),
      sharpeRatio: (json['sharpe_ratio'] ?? 0).toDouble(),
      maxDrawdown: (json['max_drawdown'] ?? 0).toDouble(),
      volatility: (json['volatility'] ?? 0).toDouble(),
      totalTrades: json['total_trades'] ?? 0,
      winningTrades: json['winning_trades'] ?? 0,
      losingTrades: json['losing_trades'] ?? 0,
      avgWin: (json['avg_win'] ?? 0).toDouble(),
      avgLoss: (json['avg_loss'] ?? 0).toDouble(),
      performanceHistory: (json['performance_history'] as List?)
          ?.map((item) => PerformancePoint.fromJson(item))
          .toList() ?? [],
      additionalMetrics: json['additional_metrics'] ?? {},
    );
  }

  double get winRate {
    if (totalTrades == 0) return 0.0;
    return (winningTrades / totalTrades) * 100;
  }
}

class PerformancePoint {
  final DateTime date;
  final double value;
  final double returnPercent;

  PerformancePoint({
    required this.date,
    required this.value,
    required this.returnPercent,
  });

  factory PerformancePoint.fromJson(Map<String, dynamic> json) {
    return PerformancePoint(
      date: DateTime.parse(json['date']),
      value: (json['value'] ?? 0).toDouble(),
      returnPercent: (json['return_percent'] ?? 0).toDouble(),
    );
  }
}

// Backtest criteria models for the portfolio detail screen
class BacktestCriteria {
  final String startDate;
  final String endDate;
  final double initialCash;
  final List<TechnicalIndicator> indicators;
  final String strategyLogic;
  final String rebalanceFrequency;

  BacktestCriteria({
    required this.startDate,
    required this.endDate,
    required this.initialCash,
    required this.indicators,
    required this.strategyLogic,
    required this.rebalanceFrequency,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate,
      'end_date': endDate,
      'initial_cash': initialCash,
      'indicators': indicators.map((i) => i.toJson()).toList(),
      'strategy_logic': strategyLogic,
      'rebalance_frequency': rebalanceFrequency,
    };
  }

  BacktestCriteria copyWith({
    String? startDate,
    String? endDate,
    double? initialCash,
    List<TechnicalIndicator>? indicators,
    String? strategyLogic,
    String? rebalanceFrequency,
  }) {
    return BacktestCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      initialCash: initialCash ?? this.initialCash,
      indicators: indicators ?? this.indicators,
      strategyLogic: strategyLogic ?? this.strategyLogic,
      rebalanceFrequency: rebalanceFrequency ?? this.rebalanceFrequency,
    );
  }
}

class TechnicalIndicator {
  final String name;
  final Map<String, dynamic> params;
  final IndicatorCondition buyCondition;
  final IndicatorCondition sellCondition;

  TechnicalIndicator({
    required this.name,
    required this.params,
    required this.buyCondition,
    required this.sellCondition,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'params': params,
      'buy_condition': buyCondition.toJson(),
      'sell_condition': sellCondition.toJson(),
    };
  }
}