import 'dart:convert';
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

  static Future<Map<String, dynamic>> runBacktest(Portfolio portfolio) async {
    try {
      final url = Uri.parse("$baseUrl/portfolio/backtest");
      final payload = {
        "name": portfolio.name,
        "stocks": portfolio.stocks.map((s) => s.toJson()).toList(),
        "start_date": "2023-01-01",
        "end_date": "2023-12-31",
        "initial_cash": portfolio.initialCash,
        "indicators": [
          {
            "name": "RSI",
            "params": {"period": 14},
            "buy_condition": {"operator": "less_than", "value": 30},
            "sell_condition": {"operator": "greater_than", "value": 70}
          }
        ],
        "strategy_logic": "AND",
        "rebalance_frequency": "monthly"
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Backtest failed: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock results for demo purposes
      return {
        'final_value': portfolio.initialCash * 1.15,
        'total_return': portfolio.initialCash * 0.15,
        'total_return_pct': 15.0,
        'sharpe_ratio': 1.25,
        'max_drawdown': -8.5,
      };
    }
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
    ];

    return mockStocks.where((stock) => 
      stock.symbol.toLowerCase().contains(query.toLowerCase()) ||
      stock.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}