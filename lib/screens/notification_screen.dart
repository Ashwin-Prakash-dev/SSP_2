import 'package:flutter/material.dart';
import 'dart:async';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import '../widgets/create_notification_dialog.dart';

class NotificationScreen extends StatefulWidget {
  final List<NotificationSetup> notifications;
  final Function(List<NotificationSetup>) onNotificationChanged;

  const NotificationScreen({
    Key? key,
    required this.notifications,
    required this.onNotificationChanged,
  }) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _alerts = [];
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    _startAlertMonitoring();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  void _startAlertMonitoring() {
    _alertTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkAlerts();
    });
  }

  Future<void> _checkAlerts() async {
    for (var notification in widget.notifications) {
      if (notification.isActive) {
        try {
          final alerts = await ApiService.checkAlerts(notification.symbol);
          setState(() {
            _alerts.addAll(alerts);
          });
        } catch (e) {
          print("Error checking alerts: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_alert),
            onPressed: _showCreateNotificationDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Alerts
          if (_alerts.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ..._alerts.take(3).map((alert) => Card(
                    color: alert['signal_type'] == 'BUY' ? Colors.green.shade50 : Colors.red.shade50,
                    child: ListTile(
                      leading: Icon(
                        alert['signal_type'] == 'BUY' ? Icons.trending_up : Icons.trending_down,
                        color: alert['signal_type'] == 'BUY' ? Colors.green : Colors.red,
                      ),
                      title: Text('${alert['symbol']} - ${alert['signal_type']}'),
                      subtitle: Text('Price: \$${(alert['price'] ?? 0.0).toStringAsFixed(2)}'),
                      trailing: Text(
                        DateFormatter.formatTime(DateTime.parse(alert['timestamp'])),
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
            Divider(),
          ],

          // Notification Setups
          Expanded(
            child: widget.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notifications set up',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showCreateNotificationDialog,
                          child: Text('Create Alert'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: widget.notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(widget.notifications[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationSetup notification, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  notification.symbol,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Switch(
                      value: notification.isActive,
                      onChanged: (value) {
                        setState(() {
                          notification.isActive = value;
                        });
                        widget.onNotificationChanged(widget.notifications);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          widget.notifications.removeAt(index);
                        });
                        widget.onNotificationChanged(widget.notifications);
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Indicators: ${notification.indicators.join(', ')}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              'Logic: ${notification.strategyLogic}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateNotificationDialog(
        onNotificationCreated: (notification) {
          setState(() {
            widget.notifications.add(notification);
          });
          widget.onNotificationChanged(widget.notifications);
        },
      ),
    );
  }
}