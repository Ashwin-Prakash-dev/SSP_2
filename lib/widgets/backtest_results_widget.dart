import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/helpers.dart';

class BacktestResultsWidget extends StatelessWidget {
  final BacktestResult result;
  final bool isLoading;
  final String? error;

  const BacktestResultsWidget({
    Key? key,
    required this.result,
    this.isLoading = false,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingWidget(context);
    }

    if (error != null) {
      return _buildErrorWidget(context);
    }

    return _buildResultsContent(context);
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Running backtest...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 8),
              Text(
                'This may take a few moments',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16),
            Text(
              'Backtest Failed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with overall performance
        _buildPerformanceHeader(context),
        SizedBox(height: 16),
        
        // Key metrics grid
        _buildMetricsGrid(context),
        SizedBox(height: 16),
        
        // Trading statistics
        if (result.totalTrades > 0) ...[
          _buildTradingStats(context),
          SizedBox(height: 16),
        ],
        
        // Performance chart
        if (result.performanceHistory.isNotEmpty)
          _buildPerformanceChart(context),
      ],
    );
  }

  Widget _buildPerformanceHeader(BuildContext context) {
    final isPositive = result.totalReturnPercent >= 0;
    
    return Card(
      elevation: 4,
      color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 48,
              color: isPositive ? Colors.green : Colors.red,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Return',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    NumberFormatter.formatCurrency(result.totalReturn),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${NumberFormatter.formatPercentage(result.totalReturnPercent)}',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Final Value',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  NumberFormatter.formatCurrency(result.finalValue),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk & Performance Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Sharpe Ratio',
                    result.sharpeRatio.toStringAsFixed(3),
                    Icons.speed,
                    _getSharpeRatioColor(result.sharpeRatio),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Volatility',
                    '${result.volatility.toStringAsFixed(2)}%',
                    Icons.show_chart,
                    _getVolatilityColor(result.volatility),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Max Drawdown',
                    '${result.maxDrawdown.toStringAsFixed(2)}%',
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child:                   _buildMetricCard(
                    context,
                    'Win Rate',
                    '${result.winRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    _getWinRateColor(result.winRate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color? color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color ?? Theme.of(context).colorScheme.primary),
          SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTradingStats(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trading Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(context, 'Total Trades', result.totalTrades.toString()),
                _buildStatColumn(context, 'Winning Trades', result.winningTrades.toString()),
                _buildStatColumn(context, 'Losing Trades', result.losingTrades.toString()),
              ],
            ),
            if (result.avgWin != 0 || result.avgLoss != 0) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    context, 
                    'Avg Win', 
                    NumberFormatter.formatCurrency(result.avgWin),
                    Colors.green,
                  ),
                  _buildStatColumn(
                    context, 
                    'Avg Loss', 
                    NumberFormatter.formatCurrency(result.avgLoss.abs()),
                    Colors.red,
                  ),
                  _buildStatColumn(
                    context, 
                    'Profit Factor', 
                    _calculateProfitFactor().toStringAsFixed(2),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceChart(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Over Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: _buildSimpleChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(BuildContext context) {
    if (result.performanceHistory.isEmpty) {
      return Center(
        child: Text(
          'No chart data available',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return CustomPaint(
      painter: SimpleLinePainter(
        points: result.performanceHistory,
        color: result.totalReturnPercent >= 0 ? Colors.green : Colors.red,
      ),
      child: Container(),
    );
  }

  Color _getSharpeRatioColor(double sharpeRatio) {
    if (sharpeRatio >= 1.0) return Colors.green;
    if (sharpeRatio >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility <= 15.0) return Colors.green;
    if (volatility <= 25.0) return Colors.orange;
    return Colors.red;
  }

  Color _getWinRateColor(double winRate) {
    if (winRate >= 60.0) return Colors.green;
    if (winRate >= 45.0) return Colors.orange;
    return Colors.red;
  }

  double _calculateProfitFactor() {
    if (result.avgLoss == 0 || result.losingTrades == 0) return 0.0;
    final totalWins = result.avgWin * result.winningTrades;
    final totalLosses = result.avgLoss.abs() * result.losingTrades;
    return totalLosses != 0 ? totalWins / totalLosses : 0.0;
  }
}

// Simple line chart painter for performance visualization
class SimpleLinePainter extends CustomPainter {
  final List<PerformancePoint> points;
  final Color color;

  SimpleLinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Find min and max values for scaling
    final minReturn = points.map((p) => p.returnPercent).reduce((a, b) => a < b ? a : b);
    final maxReturn = points.map((p) => p.returnPercent).reduce((a, b) => a > b ? a : b);
    
    final returnRange = maxReturn - minReturn;
    if (returnRange == 0) return;

    // Create path for line
    final path = Path();
    final fillPath = Path();
    
    // Start from bottom for fill
    fillPath.moveTo(0, size.height);
    
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final normalizedReturn = (points[i].returnPercent - minReturn) / returnRange;
      final y = size.height - (normalizedReturn * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill first, then line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw zero line if applicable
    if (minReturn < 0 && maxReturn > 0) {
      final zeroY = size.height - ((-minReturn) / returnRange * size.height);
      final zeroPaint = Paint()
        ..color = Colors.grey
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Alternative widget for simple map-based results (for portfolio detail screen)
class SimpleBacktestResultsWidget extends StatelessWidget {
  final Map<String, dynamic>? results;
  final bool isLoading;
  final String? error;

  const SimpleBacktestResultsWidget({
    Key? key,
    this.results,
    this.isLoading = false,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        elevation: 4,
        child: Container(
          height: 150,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Running backtest...'),
              ],
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error, color: Theme.of(context).colorScheme.onErrorContainer),
              SizedBox(height: 8),
              Text(
                'Backtest Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ],
          ),
        ),
      );
    }

    if (results == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No backtest results yet',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Run a backtest to see results here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              context,
              'Final Value',
              NumberFormatter.formatCurrency(results!['final_value'] ?? 0.0),
              Icons.account_balance,
            ),
            SizedBox(height: 12),
            _buildResultRow(
              context,
              'Total Return',
              NumberFormatter.formatCurrency(results!['total_return'] ?? 0.0),
              Icons.trending_up,
              valueColor: (results!['total_return'] ?? 0.0) >= 0 ? Colors.green : Colors.red,
            ),
            SizedBox(height: 12),
            _buildResultRow(
              context,
              'Return %',
              '${(results!['total_return_pct'] ?? 0.0).toStringAsFixed(2)}%',
              Icons.percent,
              valueColor: (results!['total_return_pct'] ?? 0.0) >= 0 ? Colors.green : Colors.red,
            ),
            if (results!['sharpe_ratio'] != null) ...[
              SizedBox(height: 12),
              _buildResultRow(
                context,
                'Sharpe Ratio',
                '${(results!['sharpe_ratio'] ?? 0.0).toStringAsFixed(3)}',
                Icons.speed,
              ),
            ],
            if (results!['max_drawdown'] != null) ...[
              SizedBox(height: 12),
              _buildResultRow(
                context,
                'Max Drawdown',
                '${(results!['max_drawdown'] ?? 0.0).toStringAsFixed(2)}%',
                Icons.trending_down,
                valueColor: Colors.red,
              ),
            ],
            if (results!['win_rate'] != null) ...[
              SizedBox(height: 12),
              _buildResultRow(
                context,
                'Win Rate',
                '${(results!['win_rate'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.check_circle,
              ),
            ],
            if (results!['total_trades'] != null) ...[
              SizedBox(height: 12),
              _buildResultRow(
                context,
                'Total Trades',
                '${results!['total_trades'] ?? 0}',
                Icons.swap_horiz,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, String label, String value, IconData icon, {Color? valueColor}) {
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
}