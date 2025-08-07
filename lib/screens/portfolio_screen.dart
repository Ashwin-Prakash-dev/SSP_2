import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/create_portfolio_dialog.dart';
import 'portfolio_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  final List<Portfolio> portfolios;
  final Function(List<Portfolio>) onPortfolioChanged;

  const PortfolioScreen({
    Key? key,
    required this.portfolios,
    required this.onPortfolioChanged,
  }) : super(key: key);

  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Portfolios'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showCreatePortfolioDialog();
            },
          ),
        ],
      ),
      body: widget.portfolios.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No portfolios created yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showCreatePortfolioDialog,
                    child: Text('Create Portfolio'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: widget.portfolios.length,
              itemBuilder: (context, index) {
                return _buildPortfolioCard(widget.portfolios[index]);
              },
            ),
    );
  }

  Widget _buildPortfolioCard(Portfolio portfolio) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PortfolioDetailScreen(
                portfolio: portfolio,
                onPortfolioUpdated: (updatedPortfolio) {
                  int index = widget.portfolios.indexWhere((p) => p.name == portfolio.name);
                  if (index >= 0) {
                    widget.portfolios[index] = updatedPortfolio;
                    widget.onPortfolioChanged(widget.portfolios);
                  }
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    portfolio.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '${portfolio.stocks.length} stocks • \$${portfolio.initialCash.toStringAsFixed(0)} initial',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 8),
              // Stock list preview
              Wrap(
                spacing: 8,
                children: [
                  ...portfolio.stocks.take(3).map((stock) {
                    return Chip(
                      label: Text('${stock.symbol} (${stock.weight.toStringAsFixed(1)}%)'),
                      backgroundColor: Colors.blue.shade50,
                    );
                  }).toList(),
                  if (portfolio.stocks.length > 3)
                    Chip(
                      label: Text('+${portfolio.stocks.length - 3} more'),
                      backgroundColor: Colors.grey.shade200,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePortfolioDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePortfolioDialog(
        onPortfolioCreated: (portfolio) {
          setState(() {
            widget.portfolios.add(portfolio);
          });
          widget.onPortfolioChanged(widget.portfolios);
        },
      ),
    );
  }
}