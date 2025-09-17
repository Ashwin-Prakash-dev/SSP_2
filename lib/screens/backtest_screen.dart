import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/backtest_results_card.dart';

class BacktestScreen extends StatefulWidget {
  final String initialTicker;
  
  const BacktestScreen({super.key, this.initialTicker = ''});

  @override
  State<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tickerController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _rsiPeriodController = TextEditingController(text: '14');
  final _rsiBuyController = TextEditingController(text: '30');
  final _rsiSellController = TextEditingController(text: '70');
  final _initialCashController = TextEditingController(text: '100000');
  
  final _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _results;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tickerController.text = widget.initialTicker;
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _rsiPeriodController.dispose();
    _rsiBuyController.dispose();
    _rsiSellController.dispose();
    _initialCashController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = picked.toString().split(' ')[0];
    }
  }

  Future<void> _runBacktest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _results = null;
    });

    try {
      final results = await _apiService.runBacktest(
        ticker: _tickerController.text.toUpperCase(),
        startDate: _startDateController.text,
        endDate: _endDateController.text,
        rsiPeriod: int.parse(_rsiPeriodController.text),
        rsiBuy: int.parse(_rsiBuyController.text),
        rsiSell: int.parse(_rsiSellController.text),
        initialCash: double.parse(_initialCashController.text),
      );
      
      setState(() {
        _results = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategy Backtest'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Stock Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stock Selection', 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tickerController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Symbol (e.g., AAPL)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.trending_up),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a stock symbol';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _initialCashController,
                        decoration: const InputDecoration(
                          labelText: 'Initial Cash (\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter initial cash';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Date Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date Range', 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDateController,
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(_startDateController),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select start date';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endDateController,
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(_endDateController),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select end date';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // RSI Strategy Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RSI Strategy Settings', 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _rsiPeriodController,
                        decoration: const InputDecoration(
                          labelText: 'RSI Period (5-50)',
                          border: OutlineInputBorder(),
                          helperText: 'Number of periods for RSI calculation',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final num = int.tryParse(value);
                          if (num == null || num < 5 || num > 50) {
                            return 'Must be between 5-50';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _rsiBuyController,
                              decoration: const InputDecoration(
                                labelText: 'Buy Threshold',
                                border: OutlineInputBorder(),
                                helperText: 'RSI below this = BUY',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final num = int.tryParse(value);
                                if (num == null || num < 0 || num > 100) {
                                  return 'Must be 0-100';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _rsiSellController,
                              decoration: const InputDecoration(
                                labelText: 'Sell Threshold',
                                border: OutlineInputBorder(),
                                helperText: 'RSI above this = SELL',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final num = int.tryParse(value);
                                if (num == null || num < 0 || num > 100) {
                                  return 'Must be 0-100';
                                }
                                final buyThreshold = int.tryParse(_rsiBuyController.text);
                                if (buyThreshold != null && num <= buyThreshold) {
                                  return 'Must be > buy threshold';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Run Backtest Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runBacktest,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    _isLoading ? 'Running Backtest...' : 'Run Backtest',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Error Display
              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Results Display
              if (_results != null)
                BacktestResultsCard(results: _results!),
            ],
          ),
        ),
      ),
    );
  }
}