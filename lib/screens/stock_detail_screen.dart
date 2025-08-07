import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/helpers.dart';

class StockDetailScreen extends StatelessWidget {
  final StockInfo stock;

  const StockDetailScreen({Key? key, required this.stock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stock.symbol),
        actions: [
          IconButton(
            icon: Icon(Icons.add_alert),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Add ${stock.symbol} to alerts')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      stock.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      NumberFormatter.formatCurrency(stock.price),
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          stock.changePercent >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: stock.changePercent >= 0 ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${stock.change >= 0 ? '+' : ''}${NumberFormatter.formatCurrency(stock.change)} (${NumberFormatter.formatPercentage(stock.changePercent)})',
                          style: TextStyle(
                            color: stock.changePercent >= 0 ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Key Metrics
            Text(
              'Key Metrics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMetricRow('Volume', NumberFormatter.formatNumber(stock.volume)),
                    if (stock.marketCap != null)
                      _buildMetricRow('Market Cap', '\$${NumberFormatter.formatNumber(stock.marketCap!.toInt())}'),
                    if (stock.peRatio != null)
                      _buildMetricRow('P/E Ratio', stock.peRatio!.toStringAsFixed(2)),
                    if (stock.dividendYield != null)
                      _buildMetricRow('Dividend Yield', NumberFormatter.formatPercentage(stock.dividendYield! * 100)),
                    if (stock.fiftyTwoWeekHigh != null)
                      _buildMetricRow('52W High', NumberFormatter.formatCurrency(stock.fiftyTwoWeekHigh!)),
                    if (stock.fiftyTwoWeekLow != null)
                      _buildMetricRow('52W Low', NumberFormatter.formatCurrency(stock.fiftyTwoWeekLow!)),
                  ],
                ),
              ),
            ),
            
            // Description
            if (stock.description != null && stock.description!.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'About',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    stock.description!,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}