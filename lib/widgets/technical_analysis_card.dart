import 'package:flutter/material.dart';

class TechnicalAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> stockData;

  const TechnicalAnalysisCard({super.key, required this.stockData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Technical Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Support & Resistance
            _buildSectionHeader('Support & Resistance Levels', Icons.support),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildLevelCard(
                    'Support',
                    '\$${(stockData['support_level'] ?? 0.0).toStringAsFixed(2)}',
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLevelCard(
                    'Resistance',
                    '\$${(stockData['resistance_level'] ?? 0.0).toStringAsFixed(2)}',
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stochastic Oscillator
            _buildSectionHeader('Stochastic Oscillator', Icons.show_chart),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('K%: ${(stockData['stochastic_k'] ?? 0.0).toStringAsFixed(1)}'),
                      Text('D%: ${(stockData['stochastic_d'] ?? 0.0).toStringAsFixed(1)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStochasticBar(context),
                  const SizedBox(height: 4),
                  Text(
                    _getStochasticSignal(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStochasticColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Fibonacci Retracement Levels
            _buildSectionHeader('Fibonacci Retracement Levels', Icons.timeline),
            const SizedBox(height: 8),
            _buildFibonacciLevels(),

            const SizedBox(height: 20),

            // RSI & Other Indicators
            _buildSectionHeader('Key Indicators', Icons.analytics),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildIndicatorTile(
                    'RSI',
                    '${(stockData['rsi'] ?? 0.0).toStringAsFixed(1)}',
                    _getRSIColor(stockData['rsi'] ?? 50.0),
                    _getRSISignal(stockData['rsi'] ?? 50.0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIndicatorTile(
                    'MACD',
                    '${(stockData['macd'] ?? 0.0).toStringAsFixed(3)}',
                    _getMACDColor(stockData['macd'] ?? 0.0),
                    _getMACDSignal(stockData['macd'] ?? 0.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // Equivalent to withOpacity(0.1)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)), // Equivalent to withOpacity(0.3)
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color.lerp(color, Colors.black, 0.3)!,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.lerp(color, Colors.black, 0.2)!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStochasticBar(BuildContext context) {
    final kValue = stockData['stochastic_k'] ?? 50.0;
    final dValue = stockData['stochastic_d'] ?? 50.0;
    
    // Use LayoutBuilder to get accurate width
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        return Container(
          height: 20,
          width: availableWidth,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              // Oversold zone (0-20)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: availableWidth * 0.2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(51), // withOpacity(0.2)
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              // Overbought zone (80-100)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: availableWidth * 0.2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(51), // withOpacity(0.2)
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              // K% line
              if (kValue >= 0 && kValue <= 100)
                Positioned(
                  left: (kValue / 100) * availableWidth - 2,
                  top: 2,
                  bottom: 2,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              // D% line
              if (dValue >= 0 && dValue <= 100)
                Positioned(
                  left: (dValue / 100) * availableWidth - 2,
                  top: 6,
                  bottom: 6,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFibonacciLevels() {
    final fibLevels = [
      {'level': '23.6%', 'price': (stockData['fib_236'] ?? 0.0) as num},
      {'level': '38.2%', 'price': (stockData['fib_382'] ?? 0.0) as num},
      {'level': '50.0%', 'price': (stockData['fib_500'] ?? 0.0) as num},
      {'level': '61.8%', 'price': (stockData['fib_618'] ?? 0.0) as num},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: fibLevels.map((level) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                level['level'] as String,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '\$${(level['price'] as num).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF8F00), // Colors.amber.shade800
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildIndicatorTile(String name, String value, Color color, String signal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // withOpacity(0.1)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)), // withOpacity(0.3)
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: Color.lerp(color, Colors.black, 0.3)!,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.lerp(color, Colors.black, 0.2)!,
            ),
          ),
          Text(
            signal,
            style: TextStyle(
              fontSize: 10,
              color: Color.lerp(color, Colors.black, 0.4)!,
            ),
          ),
        ],
      ),
    );
  }

  String _getStochasticSignal() {
    final kValue = (stockData['stochastic_k'] ?? 50.0) as num;
    final dValue = (stockData['stochastic_d'] ?? 50.0) as num;
    
    if (kValue > 80 && dValue > 80) return 'Overbought - Consider Selling';
    if (kValue < 20 && dValue < 20) return 'Oversold - Consider Buying';
    if (kValue > dValue) return 'Bullish Signal';
    return 'Bearish Signal';
  }

  Color _getStochasticColor() {
    final kValue = (stockData['stochastic_k'] ?? 50.0) as num;
    final dValue = (stockData['stochastic_d'] ?? 50.0) as num;
    
    if (kValue > 80 && dValue > 80) return Colors.red;
    if (kValue < 20 && dValue < 20) return Colors.green;
    if (kValue > dValue) return Colors.blue;
    return Colors.orange;
  }

  Color _getRSIColor(double rsi) {
    if (rsi > 70) return Colors.red;
    if (rsi < 30) return Colors.green;
    return Colors.blue;
  }

  String _getRSISignal(double rsi) {
    if (rsi > 70) return 'Overbought';
    if (rsi < 30) return 'Oversold';
    return 'Neutral';
  }

  Color _getMACDColor(double macd) {
    return macd >= 0 ? Colors.green : Colors.red;
  }

  String _getMACDSignal(double macd) {
    return macd >= 0 ? 'Bullish' : 'Bearish';
  }
}