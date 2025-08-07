import 'package:flutter/material.dart';
import '../models/models.dart';
import 'stock_search_screen.dart';
import 'portfolio_screen.dart';
import 'notification_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<Portfolio> portfolios = [];
  List<NotificationSetup> notifications = [];

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      StockSearchScreen(),
      PortfolioScreen(
        portfolios: portfolios,
        onPortfolioChanged: (updatedPortfolios) {
          setState(() {
            portfolios = updatedPortfolios;
          });
        },
      ),
      NotificationScreen(
        notifications: notifications,
        onNotificationChanged: (updatedNotifications) {
          setState(() {
            notifications = updatedNotifications;
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}