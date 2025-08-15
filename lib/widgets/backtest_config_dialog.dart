import 'package:flutter/material.dart';
import '../models/models.dart';

class BacktestConfigDialog extends StatefulWidget {
  final Portfolio portfolio;
  final Function(BacktestConfig) onConfigSelected;

  const BacktestConfigDialog({
    Key? key,
    required this.portfolio,
    required this.onConfigSelected,
  }) : super(key: key);

  @override
  _BacktestConfigDialogState createState() => _BacktestConfigDialogState();
}

class _BacktestConfigDialogState extends State<BacktestConfigDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Date selection
  DateTime _startDate = DateTime.now().subtract(Duration(days: 365));
  DateTime _endDate = DateTime.now();
  
  // Strategy settings
  String _rebalanceFrequency = 'monthly';
  String _strategyLogic = 'AND';
  
  // Indicators
  List<BacktestIndicator> _indicators = [];
  
  // Predefined date ranges
  final Map<String, Duration> _dateRanges = {
    '1 Month': Duration(days: 30),
    '3 Months': Duration(days: 90),
    '6 Months': Duration(days: 180),
    '1 Year': Duration(days: 365),
    '2 Years': Duration(days: 730),
    '5 Years': Duration(days: 1825),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _addDefaultIndicator();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addDefaultIndicator() {
    _indicators.add(BacktestIndicator(
      name: 'RSI',
      period: 14,
      buyCondition: IndicatorCondition(operator: 'less_than', value: 30),
      sellCondition: IndicatorCondition(operator: 'greater_than', value: 70),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, 
                       color: Theme.of(context).colorScheme.onPrimary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configure Backtest',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, 
                               color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(icon: Icon(Icons.date_range), text: 'Period'),
                  Tab(icon: Icon(Icons.trending_up), text: 'Indicators'),
                  Tab(icon: Icon(Icons.settings), text: 'Strategy'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDateTab(),
                  _buildIndicatorsTab(),
                  _buildStrategyTab(),
                ],
              ),
            ),
            
            // Bottom Actions
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _runBacktest,
                      child: Text('Run Backtest'),
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

  Widget _buildDateTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Backtest Period',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
          // Quick date ranges
          Text(
            'Quick Select',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dateRanges.entries.map((entry) {
              return FilterChip(
                label: Text(entry.key),
                selected: false,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _endDate = DateTime.now();
                      _startDate = _endDate.subtract(entry.value);
                    });
                  }
                },
              );
            }).toList(),
          ),
          
          SizedBox(height: 24),
          
          // Custom date selection
          Text(
            'Custom Range',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  'Start Date',
                  _startDate,
                  (date) => setState(() => _startDate = date),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDateSelector(
                  'End Date',
                  _endDate,
                  (date) => setState(() => _endDate = date),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Date range info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, 
                     color: Theme.of(context).colorScheme.onPrimaryContainer),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Period: ${_endDate.difference(_startDate).inDays} days',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2010),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Technical Indicators',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton.filled(
                onPressed: _addIndicator,
                icon: Icon(Icons.add),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          if (_indicators.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.trending_up, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No indicators added'),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _addIndicator,
                    child: Text('Add Indicator'),
                  ),
                ],
              ),
            )
          else
            ...(_indicators.asMap().entries.map((entry) {
              final index = entry.key;
              final indicator = entry.value;
              return _buildIndicatorCard(indicator, index);
            }).toList()),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(BacktestIndicator indicator, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  indicator.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _indicators.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Period setting
            Row(
              children: [
                Text('Period: '),
                SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: indicator.period.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onChanged: (value) {
                      setState(() {
                        indicator.period = int.tryParse(value) ?? indicator.period;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Buy/Sell conditions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Buy Condition', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      _buildConditionSelector(indicator.buyCondition),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sell Condition', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      _buildConditionSelector(indicator.sellCondition),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionSelector(IndicatorCondition condition) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: condition.operator,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          items: [
            DropdownMenuItem(value: 'less_than', child: Text('Less than')),
            DropdownMenuItem(value: 'greater_than', child: Text('Greater than')),
            DropdownMenuItem(value: 'crosses_above', child: Text('Crosses above')),
            DropdownMenuItem(value: 'crosses_below', child: Text('Crosses below')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                condition.operator = value;
              });
            }
          },
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: condition.value.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          onChanged: (value) {
            setState(() {
              condition.value = double.tryParse(value) ?? condition.value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStrategyTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Strategy Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
          // Logic selection
          Text(
            'Indicator Logic',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('AND'),
                  subtitle: Text('All conditions must be met'),
                  value: 'AND',
                  groupValue: _strategyLogic,
                  onChanged: (value) {
                    setState(() {
                      _strategyLogic = value!;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('OR'),
                  subtitle: Text('Any condition can be met'),
                  value: 'OR',
                  groupValue: _strategyLogic,
                  onChanged: (value) {
                    setState(() {
                      _strategyLogic = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Rebalance frequency
          Text(
            'Rebalance Frequency',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _rebalanceFrequency,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
              DropdownMenuItem(value: 'never', child: Text('Never (Buy & Hold)')),
            ],
            onChanged: (value) {
              setState(() {
                _rebalanceFrequency = value!;
              });
            },
          ),
          
          SizedBox(height: 24),
          
          // Portfolio summary
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text('Stocks: ${widget.portfolio.stocks.length}'),
                Text('Initial Cash: \$${widget.portfolio.initialCash.toStringAsFixed(0)}'),
                Text('Indicators: ${_indicators.length}'),
                Text('Period: ${_endDate.difference(_startDate).inDays} days'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addIndicator() {
    showDialog(
      context: context,
      builder: (context) => _IndicatorSelectionDialog(
        onIndicatorSelected: (indicator) {
          setState(() {
            _indicators.add(indicator);
          });
        },
      ),
    );
  }

  void _runBacktest() {
    final config = BacktestConfig(
      startDate: _startDate,
      endDate: _endDate,
      indicators: _indicators,
      strategyLogic: _strategyLogic,
      rebalanceFrequency: _rebalanceFrequency,
    );
    
    widget.onConfigSelected(config);
    Navigator.pop(context);
  }
}

class _IndicatorSelectionDialog extends StatefulWidget {
  final Function(BacktestIndicator) onIndicatorSelected;

  const _IndicatorSelectionDialog({required this.onIndicatorSelected});

  @override
  _IndicatorSelectionDialogState createState() => _IndicatorSelectionDialogState();
}

class _IndicatorSelectionDialogState extends State<_IndicatorSelectionDialog> {
  String _selectedIndicator = 'RSI';
  int _period = 14;

  final Map<String, Map<String, dynamic>> _indicatorDefaults = {
    'RSI': {'period': 14, 'buyBelow': 30.0, 'sellAbove': 70.0},
    'MACD': {'period': 26, 'buyAbove': 0.0, 'sellBelow': 0.0},
    'SMA': {'period': 20, 'buyAbove': 0.0, 'sellBelow': 0.0},
    'EMA': {'period': 12, 'buyAbove': 0.0, 'sellBelow': 0.0},
    'Bollinger Bands': {'period': 20, 'buyBelow': -2.0, 'sellAbove': 2.0},
    'Stochastic': {'period': 14, 'buyBelow': 20.0, 'sellAbove': 80.0},
  };

  @override
  Widget build(BuildContext context) {
    final defaults = _indicatorDefaults[_selectedIndicator]!;
    
    return AlertDialog(
      title: Text('Add Indicator'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedIndicator,
            decoration: InputDecoration(
              labelText: 'Indicator Type',
              border: OutlineInputBorder(),
            ),
            items: _indicatorDefaults.keys.map((indicator) {
              return DropdownMenuItem(value: indicator, child: Text(indicator));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedIndicator = value!;
                _period = _indicatorDefaults[value]!['period'];
              });
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            initialValue: _period.toString(),
            decoration: InputDecoration(
              labelText: 'Period',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _period = int.tryParse(value) ?? _period;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final buyOperator = defaults['buyBelow'] != null ? 'less_than' : 'greater_than';
            final sellOperator = defaults['sellAbove'] != null ? 'greater_than' : 'less_than';
            
            final indicator = BacktestIndicator(
              name: _selectedIndicator,
              period: _period,
              buyCondition: IndicatorCondition(
                operator: buyOperator,
                value: defaults['buyBelow'] ?? defaults['buyAbove'],
              ),
              sellCondition: IndicatorCondition(
                operator: sellOperator,
                value: defaults['sellAbove'] ?? defaults['sellBelow'],
              ),
            );
            widget.onIndicatorSelected(indicator);
            Navigator.pop(context);
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}