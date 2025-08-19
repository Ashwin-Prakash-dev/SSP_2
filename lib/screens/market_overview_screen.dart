// lib/screens/market_overview_screen.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class MarketOverviewScreen extends StatefulWidget {
  @override
  _MarketOverviewScreenState createState() => _MarketOverviewScreenState();
}

class _MarketOverviewScreenState extends State<MarketOverviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<StockInfo> _topGainers = [];
  List<StockInfo> _topLosers = [];
  List<StockInfo> _mostActive = [];
  List<Map<String, dynamic>> _marketIndices = [];
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMarketData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load mock data for now - you can replace with actual API calls later
      await Future.delayed(Duration(seconds: 1)); // Simulate API call
      
      setState(() {
        _topGainers = _generateMockStocks(isGainer: true);
        _topLosers = _generateMockStocks(isGainer: false);
        _mostActive = _generateMockStocks();
        _marketIndices = _generateMockIndices();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<StockInfo> _generateMockStocks({bool? isGainer}) {
    final symbols = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'META', 'NVDA', 'NFLX'];
    final companies = ['Apple Inc.', 'Alphabet Inc.', 'Microsoft Corp.', 'Tesla Inc.', 
                      'Amazon.com Inc.', 'Meta Platforms Inc.', 'NVIDIA Corp.', 'Netflix Inc.'];
    
    return List.generate(8, (index) {
      final basePrice = 150.0 + (index * 50);
      final changeMultiplier = isGainer == null ? 
        (index % 2 == 0 ? 1 : -1) : 
        (isGainer ? 1 : -1);
      final changePercent = (2.0 + (index * 0.5)) * changeMultiplier;
      final change = basePrice * (changePercent / 100);
      
      return StockInfo(
        symbol: symbols[index],
        name: companies[index],
        price: basePrice + change,
        change: change,
        changePercent: changePercent,
        volume: 1000000 + (index * 500000),
        marketCap: (basePrice * 1000000000) + (index * 100000000),
        peRatio: 15.0 + (index * 2.5),
        dividendYield: index % 3 == 0 ? 1.5 + (index * 0.2) : null,
      );
    });
  }

  List<Map<String, dynamic>> _generateMockIndices() {
    return [
      {
        'name': 'S&P 500',
        'symbol': 'SPX',
        'value': 4547.32,
        'change': 28.45,
        'changePercent': 0.63,
      },
      {
        'name': 'NASDAQ',
        'symbol': 'IXIC',
        'value': 14204.17,
        'change': -42.87,
        'changePercent': -0.30,
      },
      {
        'name': 'Dow Jones',
        'symbol': 'DJI',
        'value': 35312.53,
        'change': 156.82,
        'changePercent': 0.45,
      },
      {
        'name': 'Russell 2000',
        'symbol': 'RUT',
        'value': 2241.75,
        'change': -8.23,
        'changePercent': -0.37,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market Overview'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMarketData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMarketData,
        child: Column(
          children: [
            // Market Indices Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: _buildMarketIndices(),
            ),
            
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade800,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.blue.shade800,
                tabs: [
                  Tab(text: 'Gainers'),
                  Tab(text: 'Losers'),
                  Tab(text: 'Active'),
                  Tab(text: 'Watchlist'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorWidget()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStockList(_topGainers, 'Top Gainers'),
                            _buildStockList(_topLosers, 'Top Losers'),
                            _buildStockList(_mostActive, 'Most Active'),
                            _buildWatchlistTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketIndices() {
    if (_marketIndices.isEmpty) {
      return Container(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Market Indices',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _marketIndices.length,
            itemBuilder: (context, index) {
              final index_data = _marketIndices[index];
              final isPositive = index_data['change'] >= 0;
              
              return Container(
                width: 140,
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      index_data['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      NumberFormatter.formatNumber(index_data['value'].toInt()),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: isPositive ? Colors.green.shade300 : Colors.red.shade300,
                          size: 16,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${NumberFormatter.formatPercentage(index_data['changePercent'])}',
                          style: TextStyle(
                            color: isPositive ? Colors.green.shade300 : Colors.red.shade300,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStockList(List<StockInfo> stocks, String title) {
    if (stocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        return _buildStockCard(stocks[index], index + 1);
      },
    );
  }

  Widget _buildStockCard(StockInfo stock, int rank) {
    final isPositive = stock.changePercent >= 0;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              stock.symbol,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                stock.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Vol: ${NumberFormatter.formatNumber(stock.volume)}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormatter.formatCurrency(stock.price),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${NumberFormatter.formatPercentage(stock.changePercent)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to stock detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${stock.symbol} details...')),
          );
        },
      ),
    );
  }

  Widget _buildWatchlistTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Watchlist Coming Soon',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add stocks to your watchlist to track them here',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Watchlist feature coming soon!')),
              );
            },
            icon: Icon(Icons.add),
            label: Text('Add to Watchlist'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error loading market data',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMarketData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}