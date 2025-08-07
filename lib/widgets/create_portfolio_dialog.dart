import 'package:flutter/material.dart';
import '../models/models.dart';

class CreatePortfolioDialog extends StatefulWidget {
  final Function(Portfolio) onPortfolioCreated;

  const CreatePortfolioDialog({Key? key, required this.onPortfolioCreated}) : super(key: key);

  @override
  _CreatePortfolioDialogState createState() => _CreatePortfolioDialogState();
}

class _CreatePortfolioDialogState extends State<CreatePortfolioDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cashController = TextEditingController(text: '100000');
  List<PortfolioStock> stocks = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Portfolio'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Portfolio Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _cashController,
              decoration: InputDecoration(
                labelText: 'Initial Cash',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stocks', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _showAddStockDialog,
                  icon: Icon(Icons.add),
                  label: Text('Add Stock'),
                ),
              ],
            ),
            Container(
              height: 200,
              child: stocks.isEmpty
                  ? Center(child: Text('No stocks added'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: stocks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(stocks[index].symbol),
                          subtitle: Text('${stocks[index].weight.toStringAsFixed(1)}%'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                stocks.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createPortfolio,
          child: Text('Create'),
        ),
      ],
    );
  }

  void _showAddStockDialog() {
    final symbolController = TextEditingController();
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              decoration: InputDecoration(
                labelText: 'Stock Symbol',
                hintText: 'e.g., AAPL',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 16),
            TextField(
              controller: weightController,
              decoration: InputDecoration(
                labelText: 'Weight (%)',
                hintText: 'e.g., 25',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              if (symbolController.text.isNotEmpty && weightController.text.isNotEmpty) {
                setState(() {
                  stocks.add(PortfolioStock(
                    symbol: symbolController.text.toUpperCase(),
                    weight: double.tryParse(weightController.text) ?? 0,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _createPortfolio() {
    if (_nameController.text.isNotEmpty && stocks.isNotEmpty) {
      final portfolio = Portfolio(
        name: _nameController.text,
        stocks: stocks,
        initialCash: double.tryParse(_cashController.text) ?? 100000,
      );
      widget.onPortfolioCreated(portfolio);
      Navigator.pop(context);
    }
  }
}