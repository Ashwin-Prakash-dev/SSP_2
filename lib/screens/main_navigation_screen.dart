// Replace your lib/screens/main_navigation_screen.dart with this:

import 'package:flutter/material.dart';
import '../models/models.dart';
import 'stock_search_screen.dart';
import 'portfolio_screen.dart';
import 'notification_screen.dart';
import 'market_overview_screen.dart'; // Add this import

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
      MarketOverviewScreen(), // Add this as first screen
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
        type: BottomNavigationBarType.fixed, // Add this for 4 tabs
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey.shade600,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Market',
          ),
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