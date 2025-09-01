import 'package:flutter/material.dart';

class CompanyInfoCard extends StatelessWidget {
  final Map<String, dynamic> stockData;

  const CompanyInfoCard({super.key, required this.stockData});

  @override
  Widget build(BuildContext context) {
    final currentPrice = stockData['current_price'] ?? 0.0;
    final change = stockData['change'] ?? 0.0;
    final changePercent = stockData['change_percent'] ?? 0.0;
    final isPositive = change >= 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stockData['symbol'] ?? 'N/A',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stockData['company_name'] ?? 'Company Name',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stockData['sector'] ?? 'Technology',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${currentPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 16,
                              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${change.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)',
                              style: TextStyle(
                                color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Key Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Volume',
                    _formatVolume(stockData['volume'] ?? 0),
                    Icons.bar_chart,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Market Cap',
                    _formatMarketCap(stockData['market_cap'] ?? 0),
                    Icons.account_balance,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'P/E Ratio',
                    (stockData['pe_ratio'] ?? 0.0).toStringAsFixed(1),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }

  String _formatMarketCap(double marketCap) {
    if (marketCap >= 1000000000000) {
      return '\$${(marketCap / 1000000000000).toStringAsFixed(1)}T';
    } else if (marketCap >= 1000000000) {
      return '\$${(marketCap / 1000000000).toStringAsFixed(1)}B';
    } else if (marketCap >= 1000000) {
      return '\$${(marketCap / 1000000).toStringAsFixed(1)}M';
    }
    return '\$${marketCap.toStringAsFixed(0)}';
  }
}