import 'package:flutter/material.dart';

class BacktestResultsCard extends StatelessWidget {
  final Map<String, dynamic> results;

  const BacktestResultsCard({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    // Safely get values with proper null checks and type casting
    final totalReturn = (results['total_return'] ?? 0.0) as num;
    final totalReturnPct = (results['total_return_pct'] ?? 0.0) as num;
    final isProfit = totalReturn > 0;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Backtest Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Performance Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProfit 
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : [Colors.red.shade50, Colors.red.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isProfit 
                      ? Colors.green.shade300 
                      : Colors.red.shade300,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Return',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalReturnPct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    '\$${totalReturn.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isProfit ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Portfolio Values
            Row(
              children: [
                Expanded(
                  child: _buildValueTile(
                    'Initial Value',
                    '\$${((results['initial_value'] ?? 0.0) as num).toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildValueTile(
                    'Final Value',
                    '\$${((results['final_value'] ?? 0.0) as num).toStringAsFixed(2)}',
                    Icons.account_balance,
                    isProfit ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Trading Statistics
            const Text(
              'Trading Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _buildResultRow('Total Trades', '${(results['total_trades'] ?? 0) as int}'),
                  _buildResultRow('Winning Trades', '${(results['winning_trades'] ?? 0) as int}', 
                      valueColor: const Color(0xFF2E7D32)), // Colors.green.shade700
                  _buildResultRow('Losing Trades', '${(results['losing_trades'] ?? 0) as int}', 
                      valueColor: const Color(0xFFC62828)), // Colors.red.shade700
                  const Divider(height: 20),
                  _buildResultRow('Win Rate', '${((results['win_rate'] ?? 0.0) as num).toStringAsFixed(1)}%',
                      valueColor: _getWinRateColor((results['win_rate'] ?? 0.0) as num)),
                  _buildResultRow('Max Drawdown', '${((results['max_drawdown'] ?? 0.0) as num).toStringAsFixed(1)}%',
                      valueColor: const Color(0xFFC62828)), // Colors.red.shade700
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Performance Insights
            _buildPerformanceInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // Equivalent to withOpacity(0.1)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)), // Equivalent to withOpacity(0.3)
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color.lerp(color, Colors.black, 0.3)!,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.lerp(color, Colors.black, 0.2)!,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceInsights() {
    final insights = _generateInsights();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Performance Insights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.blue.shade700)),
                Expanded(
                  child: Text(
                    insight,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getWinRateColor(num winRate) {
    final rate = winRate.toDouble();
    if (rate >= 60) return const Color(0xFF2E7D32); // Colors.green.shade700
    if (rate >= 40) return const Color(0xFFE65100); // Colors.orange.shade700
    return const Color(0xFFC62828); // Colors.red.shade700
  }

  List<String> _generateInsights() {
    final insights = <String>[];
    
    // Safely extract values with proper type casting
    final winRate = (results['win_rate'] ?? 0.0) as num;
    final totalReturn = (results['total_return_pct'] ?? 0.0) as num;
    final maxDrawdown = (results['max_drawdown'] ?? 0.0) as num;
    final totalTrades = (results['total_trades'] ?? 0) as int;

    // Win rate insights
    if (winRate >= 70) {
      insights.add('Excellent win rate of ${winRate.toStringAsFixed(1)}% indicates strong strategy performance');
    } else if (winRate >= 50) {
      insights.add('Good win rate of ${winRate.toStringAsFixed(1)}% shows consistent strategy execution');
    } else if (winRate < 40) {
      insights.add('Low win rate of ${winRate.toStringAsFixed(1)}% suggests strategy needs optimization');
    }

    // Return insights
    if (totalReturn > 20) {
      insights.add('Strong returns of ${totalReturn.toStringAsFixed(1)}% outperformed typical market returns');
    } else if (totalReturn > 0) {
      insights.add('Positive returns of ${totalReturn.toStringAsFixed(1)}% show profitable strategy');
    } else {
      insights.add('Negative returns of ${totalReturn.toStringAsFixed(1)}% indicate strategy underperformance');
    }

    // Drawdown insights
    if (maxDrawdown < 10) {
      insights.add('Low maximum drawdown of ${maxDrawdown.toStringAsFixed(1)}% shows good risk management');
    } else if (maxDrawdown > 25) {
      insights.add('High maximum drawdown of ${maxDrawdown.toStringAsFixed(1)}% indicates significant risk exposure');
    }

    // Trading frequency insights
    if (totalTrades < 5) {
      insights.add('Low trading frequency may indicate limited market opportunities or conservative settings');
    } else if (totalTrades > 50) {
      insights.add('High trading frequency suggests active strategy - monitor transaction costs');
    }

    // Risk-reward insights
    if (totalReturn > 0 && maxDrawdown > 0) {
      final riskRewardRatio = totalReturn.toDouble() / maxDrawdown.toDouble();
      if (riskRewardRatio > 2) {
        insights.add('Favorable risk-reward ratio indicates efficient capital utilization');
      } else if (riskRewardRatio < 0.5) {
        insights.add('Poor risk-reward ratio suggests high risk for modest returns');
      }
    }

    return insights.isEmpty 
        ? ['Strategy performance analysis completed. Consider adjusting parameters for optimization.']
        : insights;
  }
}