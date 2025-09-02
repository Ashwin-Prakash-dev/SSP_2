import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class StockSearchWidget extends StatefulWidget {
  final Function(String symbol) onStockSelected;
  final String? initialValue;

  const StockSearchWidget({
    super.key,
    required this.onStockSelected,
    this.initialValue,
  });

  @override
  State<StockSearchWidget> createState() => _StockSearchWidgetState();
}

class _StockSearchWidgetState extends State<StockSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ApiService _apiService = ApiService();
  
  List<StockSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_controller.text);
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      setState(() {
        _showResults = true;
      });
    } else {
      // Delay hiding to allow for selection
      Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _showResults = false;
          });
        }
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _apiService.searchStocks(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showResults = results.isNotEmpty && _focusNode.hasFocus;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _showResults = false;
          _isSearching = false;
        });
      }
    }
  }

  void _selectStock(StockSearchResult stock) {
    _controller.text = '${stock.symbol} - ${stock.companyName}';
    setState(() {
      _showResults = false;
    });
    _focusNode.unfocus();
    widget.onStockSelected(stock.symbol);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Search by symbol or company name',
            hintText: 'e.g., AAPL or Apple Inc.',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _searchResults = [];
                            _showResults = false;
                          });
                        },
                      )
                    : null,
          ),
          onSubmitted: (value) {
            // If user presses enter and there's only one result, select it
            if (_searchResults.length == 1) {
              _selectStock(_searchResults.first);
            } else if (value.contains(RegExp(r'^[A-Z]{1,5}$'))) {
              // If it looks like a symbol, use it directly
              widget.onStockSelected(value.toUpperCase());
              _focusNode.unfocus();
            }
          },
        ),
        
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26), // withOpacity(0.1)
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final stock = _searchResults[index];
                return InkWell(
                  onTap: () => _selectStock(stock),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Symbol badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stock.symbol,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Company info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stock.companyName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (stock.sector != null)
                                Text(
                                  stock.sector!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Exchange badge
                        if (stock.exchange != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              stock.exchange!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}