import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000";

  static Future<List<StockInfo>> searchStocks(String query) async {
    try {
      final url = Uri.parse("$baseUrl/search/$query");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['results'] as List)
            .map((json) => StockInfo.fromJson(json))
            .toList();
        return results;
      } else {
        throw Exception('Failed to search stocks: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for demo purposes
      return _getMockStocks(query);
    }
  }

  static Future<BacktestResult> runBacktestWithConfig(Portfolio portfolio, BacktestConfig config) async {
    try {
      final url = Uri.parse("$baseUrl/portfolio/backtest/custom");
      final payload = {
        "portfolio": portfolio.toJson(),
        "config": config.toJson(),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BacktestResult.fromJson(data);
      } else {
        throw Exception('Backtest failed: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock results for demo purposes with realistic simulation
      return _generateMockBacktestResult(portfolio, config);
    }
  }

  // Legacy method for backward compatibility
  static Future<Map<String, dynamic>> runBacktest(Portfolio portfolio) async {
    final defaultConfig = BacktestConfig(
      startDate: DateTime.now().subtract(Duration(days: 365)),
      endDate: DateTime.now(),
      indicators: [
        BacktestIndicator(
          name: 'RSI',
          period: 14,
          buyCondition: IndicatorCondition(operator: 'less_than', value: 30),
          sellCondition: IndicatorCondition(operator: 'greater_than', value: 70),
        ),
      ],
      strategyLogic: 'AND',
      rebalanceFrequency: 'monthly',
    );

    final result = await runBacktestWithConfig(portfolio, defaultConfig);
    
    // Convert to legacy format
    return {
      'final_value': result.finalValue,
      'total_return': result.totalReturn,
      'total_return_pct': result.totalReturnPercent,
      'sharpe_ratio': result.sharpeRatio,
      'max_drawdown': result.maxDrawdown,
    };
  }

  static Future<List<Map<String, dynamic>>> checkAlerts(String symbol) async {
    try {
      final url = Uri.parse("$baseUrl/notifications/check/$symbol");
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['alerts'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to check alerts: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock alerts for demo purposes
      if (DateTime.now().minute % 5 == 0) {
        return [
          {
            'symbol': symbol,
            'signal_type': DateTime.now().second % 2 == 0 ? 'BUY' : 'SELL',
            'price': 150.0 + (DateTime.now().millisecond / 10),
            'timestamp': DateTime.now().toIso8601String(),
          }
        ];
      }
      return [];
    }
  }

  // Enhanced mock data generation with more realistic results
  static BacktestResult _generateMockBacktestResult(Portfolio portfolio, BacktestConfig config) {
    final random = Random();
    final durationInDays = config.durationInDays;
    final initialValue = portfolio.initialCash;
    
    // Simulate market performance based on duration and indicators
    double baseReturn = _calculateBaseReturn(durationInDays, config.indicators.length);
    double volatility = _calculateVolatility(config.indicators);
    
    // Add some randomness but keep it realistic
    final returnVariation = (random.nextDouble() - 0.5) * 0.3; // ±15% variation
    final totalReturnPct = baseReturn + returnVariation;
    
    final finalValue = initialValue * (1 + totalReturnPct / 100);
    final totalReturn = finalValue - initialValue;
    
    // Calculate other metrics
    final sharpeRatio = _calculateSharpeRatio(totalReturnPct, volatility);
    final maxDrawdown = _calculateMaxDrawdown(totalReturnPct, volatility);
    
    // Trading statistics (if using active strategy)
    final isActiveStrategy = config.indicators.any((i) => 
        i.name.toUpperCase() == 'RSI' || i.name.toUpperCase() == 'MACD');
    
    int totalTrades = 0;
    int winningTrades = 0;
    int losingTrades = 0;
    double avgWin = 0.0;
    double avgLoss = 0.0;
    
    if (isActiveStrategy && config.rebalanceFrequency != 'never') {
      totalTrades = _calculateTotalTrades(durationInDays, config.rebalanceFrequency);
      winningTrades = (totalTrades * (0.4 + random.nextDouble() * 0.3)).round(); // 40-70% win rate
      losingTrades = totalTrades - winningTrades;
      avgWin = (totalReturn / max(winningTrades, 1)) * 1.5; // Winners are bigger
      avgLoss = (totalReturn / max(losingTrades, 1)) * -0.8; // Losses are smaller
    }
    
    // Generate performance history
    final performanceHistory = _generatePerformanceHistory(
      initialValue, finalValue, durationInDays, config.startDate);
    
    return BacktestResult(
      finalValue: finalValue,
      totalReturn: totalReturn,
      totalReturnPercent: totalReturnPct,
      sharpeRatio: sharpeRatio,
      maxDrawdown: maxDrawdown,
      volatility: volatility,
      totalTrades: totalTrades,
      winningTrades: winningTrades,
      losingTrades: losingTrades,
      avgWin: avgWin,
      avgLoss: avgLoss,
      performanceHistory: performanceHistory,
      additionalMetrics: {
        'beta': 0.8 + random.nextDouble() * 0.6, // 0.8 - 1.4
        'alpha': (totalReturnPct - 8) / 100, // Excess return over 8% market
        'correlation': 0.6 + random.nextDouble() * 0.3, // 0.6 - 0.9
      },
    );
  }

  static double _calculateBaseReturn(int days, int indicatorCount) {
    // Base annual return expectation: 8-12%
    double annualReturn = 8.0 + (indicatorCount * 1.5); // More indicators = potentially better
    return (annualReturn * days / 365);
  }

  static double _calculateVolatility(List<BacktestIndicator> indicators) {
    double baseVolatility = 15.0; // 15% base volatility
    
    // RSI and other momentum indicators might increase volatility
    for (var indicator in indicators) {
      switch (indicator.name.toUpperCase()) {
        case 'RSI':
        case 'STOCHASTIC':
          baseVolatility += 2.0;
          break;
        case 'SMA':
        case 'EMA':
          baseVolatility -= 1.0; // Moving averages reduce volatility
          break;
        case 'MACD':
          baseVolatility += 1.0;
          break;
      }
    }
    
    return max(5.0, min(25.0, baseVolatility)); // Clamp between 5-25%
  }

  static double _calculateSharpeRatio(double returnPct, double volatility) {
    final excessReturn = returnPct - 2.0; // Assume 2% risk-free rate
    return excessReturn / volatility;
  }

  static double _calculateMaxDrawdown(double returnPct, double volatility) {
    // Max drawdown is typically related to volatility
    final baseDrawdown = volatility * 0.6; // 60% of volatility
    final returnAdjustment = returnPct < 0 ? returnPct.abs() * 0.3 : 0;
    return -(baseDrawdown + returnAdjustment);
  }

  static int _calculateTotalTrades(int days, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return (days * 0.1).round(); // 10% of days have trades
      case 'weekly':
        return (days / 7 * 0.3).round(); // 30% of weeks have trades
      case 'monthly':
        return (days / 30 * 0.8).round(); // 80% of months have trades
      case 'quarterly':
        return (days / 90).round(); // One trade per quarter
      default:
        return 0; // Buy and hold
    }
  }

  static List<PerformancePoint> _generatePerformanceHistory(
      double initialValue, double finalValue, int days, DateTime startDate) {
    final points = <PerformancePoint>[];
    final random = Random();
    
    // Generate weekly data points
    final totalWeeks = (days / 7).ceil();
    final weeklyReturn = pow(finalValue / initialValue, 1.0 / totalWeeks) - 1;
    
    double currentValue = initialValue;
    DateTime currentDate = startDate;
    
    for (int week = 0; week <= totalWeeks; week++) {
      if (week > 0) {
        // Add some volatility to the weekly returns
        final volatilityFactor = 1 + (random.nextDouble() - 0.5) * 0.1; // ±5% weekly volatility
        currentValue *= (1 + weeklyReturn) * volatilityFactor;
        currentDate = currentDate.add(Duration(days: 7));
      }
      
      final returnPercent = ((currentValue - initialValue) / initialValue) * 100;
      
      points.add(PerformancePoint(
        date: currentDate,
        value: currentValue,
        returnPercent: returnPercent,
      ));
    }
    
    return points;
  }

  static List<StockInfo> _getMockStocks(String query) {
    final mockStocks = [
      StockInfo(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        price: 175.43,
        change: 2.15,
        changePercent: 1.24,
        volume: 45678900,
        marketCap: 2800000000000,
        peRatio: 28.5,
        dividendYield: 0.0043,
        fiftyTwoWeekHigh: 198.23,
        fiftyTwoWeekLow: 124.17,
        description: 'Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide.',
      ),
      StockInfo(
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        price: 2750.12,
        change: -15.67,
        changePercent: -0.57,
        volume: 1234567,
        marketCap: 1800000000000,
        peRatio: 25.3,
        dividendYield: 0.0,
        fiftyTwoWeekHigh: 3030.93,
        fiftyTwoWeekLow: 2193.62,
        description: 'Alphabet Inc. provides online advertising services in the United States, Europe, the Middle East, Africa, the Asia-Pacific, Canada, and Latin America.',
      ),
      StockInfo(
        symbol: 'TSLA',
        name: 'Tesla, Inc.',
        price: 245.67,
        change: 8.32,
        changePercent: 3.51,
        volume: 23456789,
        marketCap: 780000000000,
        peRatio: 65.2,
        dividendYield: 0.0,
        fiftyTwoWeekHigh: 414.50,
        fiftyTwoWeekLow: 101.81,
        description: 'Tesla, Inc. designs, develops, manufactures, leases, and sells electric vehicles, and energy generation and storage systems.',
      ),
      StockInfo(
        symbol: 'MSFT',
        name: 'Microsoft Corporation',
        price: 338.11,
        change: 4.23,
        changePercent: 1.27,
        volume: 12345678,
        marketCap: 2500000000000,
        peRatio: 32.1,
        dividendYield: 0.0072,
        fiftyTwoWeekHigh: 384.30,
        fiftyTwoWeekLow: 213.43,
        description: 'Microsoft Corporation develops, licenses, and supports software, services, devices, and solutions worldwide.',
      ),
      StockInfo(
        symbol: 'AMZN',
        name: 'Amazon.com Inc.',
        price: 145.32,
        change: -2.18,
        changePercent: -1.48,
        volume: 18765432,
        marketCap: 1500000000000,
        peRatio: 45.8,
        dividendYield: 0.0,
        fiftyTwoWeekHigh: 188.11,
        fiftyTwoWeekLow: 118.35,
        description: 'Amazon.com Inc. engages in the retail sale of consumer products and subscriptions in North America and internationally.',
      ),
      StockInfo(
        symbol: 'NVDA',
        name: 'NVIDIA Corporation',
        price: 875.28,
        change: 23.45,
        changePercent: 2.75,
        volume: 8765432,
        marketCap: 2200000000000,
        peRatio: 58.3,
        dividendYield: 0.0012,
        fiftyTwoWeekHigh: 950.02,
        fiftyTwoWeekLow: 180.96,
        description: 'NVIDIA Corporation operates as a visual computing company worldwide. It operates in two segments, Graphics and Compute & Networking.',
      ),
      StockInfo(
        symbol: 'META',
        name: 'Meta Platforms Inc.',
        price: 298.75,
        change: 5.67,
        changePercent: 1.94,
        volume: 12987654,
        marketCap: 800000000000,
        peRatio: 22.4,
        dividendYield: 0.0035,
        fiftyTwoWeekHigh: 384.33,
        fiftyTwoWeekLow: 185.82,
        description: 'Meta Platforms Inc. develops products that enable people to connect and share with friends and family through mobile devices, personal computers, virtual reality headsets, and wearables worldwide.',
      ),
      StockInfo(
        symbol: 'BRK.B',
        name: 'Berkshire Hathaway Inc.',
        price: 354.82,
        change: 1.23,
        changePercent: 0.35,
        volume: 2345678,
        marketCap: 850000000000,
        peRatio: 18.9,
        dividendYield: 0.0,
        fiftyTwoWeekHigh: 365.14,
        fiftyTwoWeekLow: 295.04,
        description: 'Berkshire Hathaway Inc., through its subsidiaries, engages in the insurance, freight rail transportation, and utility businesses worldwide.',
      ),
      StockInfo(
        symbol: 'JPM',
        name: 'JPMorgan Chase & Co.',
        price: 142.56,
        change: -0.89,
        changePercent: -0.62,
        volume: 9876543,
        marketCap: 420000000000,
        peRatio: 12.8,
        dividendYield: 0.0285,
        fiftyTwoWeekHigh: 148.36,
        fiftyTwoWeekLow: 126.06,
        description: 'JPMorgan Chase & Co. operates as a financial services company worldwide. It operates in four segments: Consumer & Community Banking, Corporate & Investment Bank, Commercial Banking, and Asset & Wealth Management.',
      ),
      StockInfo(
        symbol: 'V',
        name: 'Visa Inc.',
        price: 245.18,
        change: 3.24,
        changePercent: 1.34,
        volume: 5432167,
        marketCap: 520000000000,
        peRatio: 29.7,
        dividendYield: 0.0075,
        fiftyTwoWeekHigh: 250.46,
        fiftyTwoWeekLow: 201.73,
        description: 'Visa Inc. operates as a payments technology company worldwide. The company facilitates digital payments among consumers, merchants, financial institutions, businesses, strategic partners, and government entities.',
      ),
    ];

    return mockStocks.where((stock) => 
      stock.symbol.toLowerCase().contains(query.toLowerCase()) ||
      stock.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}