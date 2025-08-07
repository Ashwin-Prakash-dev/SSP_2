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