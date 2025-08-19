import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final Portfolio portfolio;
  final Function(Portfolio) onPortfolioUpdated;

  const PortfolioDetailScreen({
    super.key,
    required this.portfolio,
    required this.onPortfolioUpdated,
  });

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  bool _isBacktesting = false;
  Map<String, dynamic>? _backtestResult;
  String? _error;

  // Default backtest criteria
  late BacktestCriteria _backtestCriteria;

  @override
  void initState() {
    super.initState();
    _backtestCriteria = BacktestCriteria(
      startDate: '2023-01-01',
      endDate: '2023-12-31',
      initialCash: widget.portfolio.initialCash,
      indicators: [
        TechnicalIndicator(
          name: 'RSI',
          params: {'period': 14},
          buyCondition: IndicatorCondition(operator: 'less_than', value: 30),
          sellCondition: IndicatorCondition(operator: 'greater_than', value: 70),
        ),
      ],
      strategyLogic: 'AND',
      rebalanceFrequency: 'monthly',
    );
  }

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
            icon: const Icon(Icons.settings),
            onPressed: _showBacktestCriteriaDialog,
            tooltip: 'Backtest Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isBacktesting ? null : _runBacktest,
            tooltip: 'Run Backtest',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPortfolioSummary(),
              const SizedBox(height: 20),
              _buildHoldingsSection(),
              const SizedBox(height: 20),
              _buildBacktestSection(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorCard(),
              ],
              if (_backtestResult != null) ...[
                const SizedBox(height: 20),
                _buildBacktestResults(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBacktestResults() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Backtest Results',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildResultRow(
              'Final Value',
              '\$${(_backtestResult!['final_value'] ?? 0.0).toStringAsFixed(2)}',
              Icons.account_balance,
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              'Total Return',
              '\$${(_backtestResult!['total_return'] ?? 0.0).toStringAsFixed(2)}',
              Icons.trending_up,
              valueColor: (_backtestResult!['total_return'] ?? 0.0) >= 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              'Return %',
              '${(_backtestResult!['total_return_pct'] ?? 0.0).toStringAsFixed(2)}%',
              Icons.percent,
              valueColor: (_backtestResult!['total_return_pct'] ?? 0.0) >= 0 ? Colors.green : Colors.red,
            ),
            if (_backtestResult!['sharpe_ratio'] != null) ...[
              const SizedBox(height: 12),
              _buildResultRow(
                'Sharpe Ratio',
                '${(_backtestResult!['sharpe_ratio'] ?? 0.0).toStringAsFixed(3)}',
                Icons.speed,
              ),
            ],
            if (_backtestResult!['max_drawdown'] != null) ...[
              const SizedBox(height: 12),
              _buildResultRow(
                'Max Drawdown',
                '${(_backtestResult!['max_drawdown'] ?? 0.0).toStringAsFixed(2)}%',
                Icons.trending_down,
                valueColor: Colors.red,
              ),
            ],
            if (_backtestResult!['win_rate'] != null) ...[
              const SizedBox(height: 12),
              _buildResultRow(
                'Win Rate',
                '${(_backtestResult!['win_rate'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.check_circle,
              ),
            ],
            if (_backtestResult!['total_trades'] != null) ...[
              const SizedBox(height: 12),
              _buildResultRow(
                'Total Trades',
                '${_backtestResult!['total_trades'] ?? 0}',
                Icons.swap_horiz,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBacktestSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Backtest Configuration',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildCriteriaPreview(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showBacktestCriteriaDialog,
                    icon: const Icon(Icons.tune),
                    label: const Text('Configure'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
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
                        : const Icon(Icons.play_arrow),
                    label: Text(_isBacktesting ? 'Running...' : 'Run Backtest'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Period: ${_backtestCriteria.startDate} to ${_backtestCriteria.endDate}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.show_chart, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Indicators: ${_backtestCriteria.indicators.map((i) => i.name).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.autorenew, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Rebalance: ${_backtestCriteria.rebalanceFrequency}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBacktestCriteriaDialog() {
    showDialog(
      context: context,
      builder: (context) => BacktestCriteriaDialog(
        initialCriteria: _backtestCriteria,
        portfolio: widget.portfolio,
        onCriteriaChanged: (criteria) {
          setState(() {
            _backtestCriteria = criteria;
          });
        },
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    final totalWeight = widget.portfolio.stocks.fold(0.0, (sum, stock) => sum + stock.weight);
    final isWeightValid = (totalWeight - 100.0).abs() < 0.01;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, 
                     color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Portfolio Summary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSummaryRow('Initial Cash', '\$${_formatCurrency(widget.portfolio.initialCash)}', Icons.attach_money),
            const SizedBox(height: 12),
            _buildSummaryRow('Number of Holdings', '${widget.portfolio.stocks.length}', Icons.list),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Total Weight', 
              '${totalWeight.toStringAsFixed(1)}%',
              Icons.pie_chart,
              valueColor: isWeightValid ? null : Theme.of(context).colorScheme.error,
            ),
            if (!isWeightValid) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, 
                         size: 16, 
                         color: Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
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
        const SizedBox(width: 12),
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
            const SizedBox(width: 8),
            Text(
              'Holdings (${widget.portfolio.stocks.length})',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.portfolio.stocks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
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
          }),
      ],
    );
  }

  Widget _buildStockCard(dynamic stock, int index) {
    final allocation = widget.portfolio.initialCash * stock.weight / 100;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildErrorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
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

  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
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
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _runBacktest() async {
    setState(() {
      _isBacktesting = true;
      _backtestResult = null;
      _error = null;
    });

    try {
      final result = await ApiService.runBacktestWithCriteria(
        widget.portfolio,
        _backtestCriteria,
      );
      
      if (mounted) {
        setState(() {
          _backtestResult = result;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Backtest failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
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

class BacktestCriteriaDialog extends StatefulWidget {
  final BacktestCriteria initialCriteria;
  final Portfolio portfolio;
  final Function(BacktestCriteria) onCriteriaChanged;

  const BacktestCriteriaDialog({
    super.key,
    required this.initialCriteria,
    required this.portfolio,
    required this.onCriteriaChanged,
  });

  @override
  State<BacktestCriteriaDialog> createState() => _BacktestCriteriaDialogState();
}

class _BacktestCriteriaDialogState extends State<BacktestCriteriaDialog> {
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _initialCashController;
  
  String _selectedRebalanceFrequency = 'monthly';
  String _selectedStrategyLogic = 'AND';
  List<TechnicalIndicator> _indicators = [];

  final List<String> _rebalanceOptions = ['daily', 'weekly', 'monthly', 'quarterly'];
  final List<String> _strategyOptions = ['AND', 'OR'];

  @override
  void initState() {
    super.initState();
    final criteria = widget.initialCriteria;
    _startDateController = TextEditingController(text: criteria.startDate);
    _endDateController = TextEditingController(text: criteria.endDate);
    _initialCashController = TextEditingController(text: criteria.initialCash.toString());
    _selectedRebalanceFrequency = criteria.rebalanceFrequency;
    _selectedStrategyLogic = criteria.strategyLogic;
    _indicators = List.from(criteria.indicators);
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _initialCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Backtest Configuration',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicSettings(),
                    const SizedBox(height: 24),
                    _buildStrategySettings(),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveCriteria,
                      child: const Text('Apply Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _selectDate(context, _startDateController),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _selectDate(context, _endDateController),
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _initialCashController,
              decoration: const InputDecoration(
                labelText: 'Initial Cash',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Strategy Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStrategyLogic,
              decoration: const InputDecoration(
                labelText: 'Strategy Logic',
                border: OutlineInputBorder(),
              ),
              items: _strategyOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStrategyLogic = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRebalanceFrequency,
              decoration: const InputDecoration(
                labelText: 'Rebalance Frequency',
                border: OutlineInputBorder(),
              ),
              items: _rebalanceOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRebalanceFrequency = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  void _saveCriteria() {
    final criteria = BacktestCriteria(
      startDate: _startDateController.text,
      endDate: _endDateController.text,
      initialCash: double.tryParse(_initialCashController.text) ?? 100000,
      indicators: _indicators,
      strategyLogic: _selectedStrategyLogic,
      rebalanceFrequency: _selectedRebalanceFrequency,
    );
    
    widget.onCriteriaChanged(criteria);
    Navigator.of(context).pop();
  }
}