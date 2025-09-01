import 'package:flutter/material.dart';

class SentimentCard extends StatelessWidget {
  final Map<String, dynamic> stockData;

  const SentimentCard({super.key, required this.stockData});

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
              'Market Sentiment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Overall Sentiment
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getOverallSentimentColor().withOpacity(0.1),
                    _getOverallSentimentColor().withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getOverallSentimentColor().withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getOverallSentimentIcon(),
                    size: 40,
                    color: _getOverallSentimentColor(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Overall Sentiment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    stockData['overall_sentiment'] ?? 'Neutral',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getOverallSentimentColor(),
                    ),
                  ),
                  Text(
                    'Score: ${(stockData['sentiment_score'] ?? 0.0).toStringAsFixed(1)}/10',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Short Term vs Long Term
            Row(
              children: [
                Expanded(
                  child: _buildSentimentTile(
                    'Short Term',
                    stockData['short_term_sentiment'] ?? 'Neutral',
                    stockData['short_term_score'] ?? 5.0,
                    Icons.flash_on,
                    '1-3 months',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSentimentTile(
                    'Long Term',
                    stockData['long_term_sentiment'] ?? 'Neutral',
                    stockData['long_term_score'] ?? 5.0,
                    Icons.trending_up,
                    '6-12 months',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sentiment Factors
            _buildSectionHeader('Key Factors', Icons.list),
            const SizedBox(height: 8),
            _buildFactorsList(),

            const SizedBox(height: 16),

            // Analyst Ratings
            _buildSectionHeader('Analyst Consensus', Icons.group),
            const SizedBox(height: 8),
            _buildAnalystRatings(),
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

  Widget _buildSentimentTile(String period, String sentiment, double score, IconData icon, String timeframe) {
    final color = _getSentimentColor(sentiment);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            period,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            sentiment,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeframe,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          _buildScoreBar(score, color),
        ],
      ),
    );
  }

  Widget _buildScoreBar(double score, Color color) {
    return Container(
      width: double.infinity,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        widthFactor: score / 10,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildFactorsList() {
    final factors = stockData['sentiment_factors'] as List<dynamic>? ?? [
      {'factor': 'Market Trends', 'impact': 'Positive'},
      {'factor': 'Company Earnings', 'impact': 'Neutral'},
      {'factor': 'Industry Growth', 'impact': 'Positive'},
      {'factor': 'Economic Indicators', 'impact': 'Negative'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: factors.map((factor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                factor['factor'] as String,
                style: const TextStyle(fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getImpactColor(factor['impact'] as String).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  factor['impact'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getImpactColor(factor['impact'] as String),
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAnalystRatings() {
    final buyCount = stockData['analyst_buy'] ?? 5;
    final holdCount = stockData['analyst_hold'] ?? 3;
    final sellCount = stockData['analyst_sell'] ?? 2;
    final totalCount = buyCount + holdCount + sellCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRatingItem('Buy', buyCount, Colors.green),
              _buildRatingItem('Hold', holdCount, Colors.orange),
              _buildRatingItem('Sell', sellCount, Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total Analysts: $totalCount',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target Price: \$${(stockData['target_price'] ?? 0.0).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(String rating, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rating,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
      case 'positive':
        return Colors.green;
      case 'bearish':
      case 'negative':
        return Colors.red;
      case 'neutral':
      default:
        return Colors.blue;
    }
  }

  Color _getOverallSentimentColor() {
    return _getSentimentColor(stockData['overall_sentiment'] ?? 'Neutral');
  }

  IconData _getOverallSentimentIcon() {
    final sentiment = stockData['overall_sentiment']?.toLowerCase() ?? 'neutral';
    switch (sentiment) {
      case 'bullish':
      case 'positive':
        return Icons.thumb_up;
      case 'bearish':
      case 'negative':
        return Icons.thumb_down;
      case 'neutral':
      default:
        return Icons.remove;
    }
  }

  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }
}