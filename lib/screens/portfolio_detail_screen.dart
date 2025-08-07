import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final Portfolio portfolio;
  final Function(Portfolio) onPortfolioUpdated;

  const PortfolioDetailScreen({
    Key? key,
    required this.portfolio,
    required this.onPortfolioUpdated,
  }) : super(key: key);

  @override
  _PortfolioDetailScreenState createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  bool _isBacktesting = false;
  Map<String, dynamic>? _backtestResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.portfolio.name),
        actions: [
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: _runBacktest,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio Summary
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text('Initial Cash: \$${widget.portfolio.initialCash.toStringAsFixed(0)}'),
                    Text('Number of Stocks: ${widget.portfolio.stocks.length}'),
                    Text('Total Weight: ${widget.portfolio.stocks.fold(0.0, (sum, stock) => sum + stock.weight).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Stocks List
            Text(
              'Holdings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...widget.portfolio.stocks.map((stock) => Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(stock.symbol),
                subtitle: Text('Weight: ${stock.weight.toStringAsFixed(1)}%'),
                trailing: Text(
                  'Allocation: \$${(widget.portfolio.initialCash * stock.weight / 100).toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )).toList(),

            SizedBox(height: 16),

            // Backtest Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isBacktesting ? null : _runBacktest,
                icon: _isBacktesting 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.analytics),
                label: Text(_isBacktesting ? 'Running Backtest...' : 'Run Backtest'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Backtest Results
            if (_backtestResult != null) ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backtest Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      _buildResultRow('Final Value', '\$${(_backtestResult!['final_value'] ?? 0.0).toStringAsFixed(2)}'),
                      _buildResultRow('Total Return', '\$${(_backtestResult!['total_return'] ?? 0.0).toStringAsFixed(2)}'),
                      _buildResultRow('Return %', '${(_backtestResult!['total_return_pct'] ?? 0.0).toStringAsFixed(2)}%'),
                      _buildResultRow('Sharpe Ratio', '${(_backtestResult!['sharpe_ratio'] ?? 0.0).toStringAsFixed(3)}'),
                      _buildResultRow('Max Drawdown', '${(_backtestResult!['max_drawdown'] ?? 0.0).toStringAsFixed(2)}%'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _runBacktest() async {
    setState(() {
      _isBacktesting = true;
      _backtestResult = null;
    });

    try {
      final result = await ApiService.runBacktest(widget.portfolio);
      setState(() {
        _backtestResult = result;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backtest completed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backtest failed: $e')),
      );
    } finally {
      setState(() {
        _isBacktesting = false;
      });
    }
  }
}