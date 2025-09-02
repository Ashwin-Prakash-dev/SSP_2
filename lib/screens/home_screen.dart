import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/company_info_card.dart';
import '../widgets/technical_analysis_card.dart';
import '../widgets/sentiment_card.dart';
import '../widgets/stock_autocomplete.dart';
import 'backtest_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _stockData;
  String? _error;

  Future<void> _searchCompany([String? symbol]) async {
    final searchTerm = symbol ?? _searchController.text;
    if (searchTerm.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _stockData = null;
    });

    try {
      final data = await _apiService.getStockInfo(searchTerm.toUpperCase());
      setState(() {
        _stockData = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onStockSelected(String symbol, String companyName) {
    _searchController.text = '$symbol - $companyName';
    _searchCompany(symbol);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Analysis'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BacktestScreen(
                    initialTicker: _stockData?['symbol'] ?? '',
                  ),
                ),
              );
            },
            tooltip: 'Backtest Strategy',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar with Autocomplete
            StockAutocomplete(
              controller: _searchController,
              onStockSelected: _onStockSelected,
              onSearch: () => _searchCompany(),
              isLoading: _isLoading,
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_error != null)
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_stockData != null) ...[
                      CompanyInfoCard(stockData: _stockData!),
                      const SizedBox(height: 16),
                      TechnicalAnalysisCard(stockData: _stockData!),
                      const SizedBox(height: 16),
                      SentimentCard(stockData: _stockData!),
                    ],

                    if (_stockData == null && !_isLoading && _error == null)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Start typing a stock symbol or company name to search',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Examples: AAPL, Apple, Microsoft, TSLA',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}