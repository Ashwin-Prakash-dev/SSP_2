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
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.portfolio.name),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isBacktesting ? null : _runBacktest,
            tooltip: 'Run Backtest',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPortfolioSummary(),
              SizedBox(height: 20),
              _buildHoldingsSection(),
              SizedBox(height: 20),
              _buildBacktestButton(),
              if (_error != null) ...[
                SizedBox(height: 16),
                _buildErrorCard(),
              ],
              if (_backtestResult != null) ...[
                SizedBox(height: 20),
                _buildBacktestResults(),
              ],
              SizedBox(height: 32), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    final totalWeight = widget.portfolio.stocks.fold(0.0, (sum, stock) => sum + stock.weight);
    final isWeightValid = (totalWeight - 100.0).abs() < 0.01; // Allow for small floating point errors
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, 
                     color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Portfolio Summary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildSummaryRow('Initial Cash', '\$${_formatCurrency(widget.portfolio.initialCash)}', Icons.attach_money),
            SizedBox(height: 12),
            _buildSummaryRow('Number of Holdings', '${widget.portfolio.stocks.length}', Icons.list),
            SizedBox(height: 12),
            _buildSummaryRow(
              'Total Weight', 
              '${totalWeight.toStringAsFixed(1)}%',
              Icons.pie_chart,
              valueColor: isWeightValid ? null : Theme.of(context).colorScheme.error,
            ),
            if (!isWeightValid) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, 
                         size: 16, 
                         color: Theme.of(context).colorScheme.onErrorContainer),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Portfolio weights should total 100%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(
              'Holdings (${widget.portfolio.stocks.length})',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (widget.portfolio.stocks.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    SizedBox(height: 16),
                    Text(
                      'No holdings in this portfolio',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...widget.portfolio.stocks.asMap().entries.map((entry) {
            final index = entry.key;
            final stock = entry.value;
            return _buildStockCard(stock, index);
          }).toList(),
      ],
    );
  }

  Widget _buildStockCard(dynamic stock, int index) {
    final allocation = widget.portfolio.initialCash * stock.weight / 100;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            stock.symbol.substring(0, 1),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          stock.symbol,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Weight: ${stock.weight.toStringAsFixed(1)}%'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${_formatCurrency(allocation)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              'Allocation',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBacktestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isBacktesting ? null : _runBacktest,
        icon: _isBacktesting 
            ? SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : Icon(Icons.analytics),
        label: Text(_isBacktesting ? 'Running Backtest...' : 'Run Backtest'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backtest Error',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              onPressed: () => setState(() => _error = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBacktestResults() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Backtest Results',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildResultRow(
              'Final Value', 
              '\$${_formatCurrency(_backtestResult!['final_value'] ?? 0.0)}',
              Icons.account_balance,
            ),
            SizedBox(height: 12),
            _buildResultRow(
              'Total Return', 
              '\$${_formatCurrency(_backtestResult!['total_return'] ?? 0.0)}',
              Icons.trending_up,
              valueColor: (_backtestResult!['total_return'] ?? 0.0) >= 0 
                  ? Colors.green 
                  : Colors.red,
            ),
            SizedBox(height: 12),
            _buildResultRow(
              'Return %', 
              '${(_backtestResult!['total_return_pct'] ?? 0.0).toStringAsFixed(2)}%',
              Icons.percent,
              valueColor: (_backtestResult!['total_return_pct'] ?? 0.0) >= 0 
                  ? Colors.green 
                  : Colors.red,
            ),
            SizedBox(height: 12),
            _buildResultRow(
              'Sharpe Ratio', 
              '${(_backtestResult!['sharpe_ratio'] ?? 0.0).toStringAsFixed(3)}',
              Icons.speed,
            ),
            SizedBox(height: 12),
            _buildResultRow(
              'Max Drawdown', 
              '${(_backtestResult!['max_drawdown'] ?? 0.0).toStringAsFixed(2)}%',
              Icons.trending_down,
              valueColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Future<void> _refreshData() async {
    // Implement refresh logic here if needed
    // This could refetch portfolio data or update holdings
    await Future.delayed(Duration(seconds: 1)); // Placeholder
  }

  Future<void> _runBacktest() async {
    setState(() {
      _isBacktesting = true;
      _backtestResult = null;
      _error = null;
    });

    try {
      final result = await ApiService.runBacktest(widget.portfolio);
      
      if (mounted) {
        setState(() {
          _backtestResult = result;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Backtest completed successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Backtest failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBacktesting = false;
        });
      }
    }
  }
}