import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const BacktestApp());
}

class BacktestApp extends StatelessWidget {
  const BacktestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Backtest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BacktestScreen(),
    );
  }
}

class BacktestScreen extends StatefulWidget {
  const BacktestScreen({super.key});

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
  
  bool _isLoading = false;
  Map<String, dynamic>? _results;
  String? _error;

  // API URL based on platform
  String get apiUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
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
      final response = await http.post(
        Uri.parse('$apiUrl/backtest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ticker': _tickerController.text.toUpperCase(),
          'start_date': _startDateController.text,
          'end_date': _endDateController.text,
          'strategy': 'RSI',
          'rsi_period': int.parse(_rsiPeriodController.text),
          'rsi_buy': int.parse(_rsiBuyController.text),
          'rsi_sell': int.parse(_rsiSellController.text),
          'initial_cash': double.parse(_initialCashController.text),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _results = jsonDecode(response.body);
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _error = errorData['detail'] ?? 'Unknown error occurred';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect to server: $e';
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
        title: const Text('Stock Backtest'),
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
                      Text('Stock Selection', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tickerController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Symbol (e.g., AAPL)',
                          border: OutlineInputBorder(),
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
                      Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
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
                      Text('RSI Strategy Settings', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _rsiPeriodController,
                              decoration: const InputDecoration(
                                labelText: 'RSI Period',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final num = int.tryParse(value);
                                if (num == null || num < 5 || num > 50) {
                                  return 'Must be 5-50';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _rsiBuyController,
                              decoration: const InputDecoration(
                                labelText: 'Buy Threshold',
                                border: OutlineInputBorder(),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _rsiSellController,
                              decoration: const InputDecoration(
                                labelText: 'Sell Threshold',
                                border: OutlineInputBorder(),
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
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _runBacktest,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Run Backtest', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 24),

              // Results
              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: $_error',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ),

              if (_results != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Backtest Results', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _buildResultRow('Initial Value', '\$${_results!['initial_value']}'),
                        _buildResultRow('Final Value', '\$${_results!['final_value']}'),
                        _buildResultRow('Total Return', '\$${_results!['total_return']}'),
                        _buildResultRow('Return %', '${_results!['total_return_pct']}%',
                            color: _results!['total_return_pct'] > 0 ? Colors.green : Colors.red),
                        const Divider(),
                        _buildResultRow('Total Trades', '${_results!['total_trades']}'),
                        _buildResultRow('Winning Trades', '${_results!['winning_trades']}'),
                        _buildResultRow('Losing Trades', '${_results!['losing_trades']}'),
                        _buildResultRow('Win Rate', '${_results!['win_rate']}%'),
                        _buildResultRow('Max Drawdown', '${_results!['max_drawdown']}%'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}