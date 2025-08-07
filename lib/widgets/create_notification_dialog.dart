import 'package:flutter/material.dart';
import '../models/models.dart';

class CreateNotificationDialog extends StatefulWidget {
  final Function(NotificationSetup) onNotificationCreated;

  const CreateNotificationDialog({Key? key, required this.onNotificationCreated}) : super(key: key);

  @override
  _CreateNotificationDialogState createState() => _CreateNotificationDialogState();
}

class _CreateNotificationDialogState extends State<CreateNotificationDialog> {
  final TextEditingController _symbolController = TextEditingController();
  List<String> _selectedIndicators = ['RSI'];
  String _strategyLogic = 'AND';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Alert'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _symbolController,
            decoration: InputDecoration(
              labelText: 'Stock Symbol',
              hintText: 'e.g., AAPL',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedIndicators.first,
            decoration: InputDecoration(
              labelText: 'Indicator',
              border: OutlineInputBorder(),
            ),
            items: ['RSI', 'MACD', 'SMA', 'EMA'].map((indicator) {
              return DropdownMenuItem(value: indicator, child: Text(indicator));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedIndicators = [value];
                });
              }
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _strategyLogic,
            decoration: InputDecoration(
              labelText: 'Logic',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'AND', child: Text('AND')),
              DropdownMenuItem(value: 'OR', child: Text('OR')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _strategyLogic = value;
                });
              }
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
          onPressed: _createNotification,
          child: Text('Create'),
        ),
      ],
    );
  }

  void _createNotification() {
    if (_symbolController.text.isNotEmpty) {
      final notification = NotificationSetup(
        symbol: _symbolController.text.toUpperCase(),
        indicators: _selectedIndicators,
        strategyLogic: _strategyLogic,
      );
      widget.onNotificationCreated(notification);
      Navigator.pop(context);
    }
  }
}