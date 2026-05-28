// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/features/sales/presentation/pages/sales_tracking_page.dart
// DESCRIPTION: Sales Tracking UI — search-bar locked at top,
//              read-only pricing, high-speed product ListView.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Domain Model ────────────────────────────────────────────

class ProductSKU {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double unitPrice; // Admin-set, read-only for reps
  final String unit;
  int quantity;

  ProductSKU({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.unitPrice,
    required this.unit,
    this.quantity = 0,
  });
}

// ── Mock Data (replace with Supabase/Riverpod provider) ──────

final List<ProductSKU> _mockProducts = [
  ProductSKU(id: '1', name: 'Mukwano Soap 800g', sku: 'MKW-800', category: 'Soap', unitPrice: 3500, unit: 'bar'),
  ProductSKU(id: '2', name: 'Roofings Steel Bar 12mm', sku: 'RFG-12', category: 'Hardware', unitPrice: 85000, unit: 'piece'),
  ProductSKU(id: '3', name: 'Nice Biscuits Assorted', sku: 'NCB-AST', category: 'Snacks', unitPrice: 1200, unit: 'pack'),
  ProductSKU(id: '4', name: 'Rwenzori Water 500ml', sku: 'RWZ-500', category: 'Beverages', unitPrice: 900, unit: 'bottle'),
  ProductSKU(id: '5', name: 'Cowboy Cooking Oil 2L', sku: 'CBY-2L', category: 'Cooking Oil', unitPrice: 12500, unit: 'bottle'),
  ProductSKU(id: '6', name: 'Nomi Washing Powder 1kg', sku: 'NMI-1KG', category: 'Detergent', unitPrice: 4800, unit: 'packet'),
  ProductSKU(id: '7', name: 'Pilau Rice 5kg', sku: 'PLR-5K', category: 'Grains', unitPrice: 22000, unit: 'bag'),
  ProductSKU(id: '8', name: 'Mukwano Soap 450g', sku: 'MKW-450', category: 'Soap', unitPrice: 2000, unit: 'bar'),
  ProductSKU(id: '9', name: 'Bell Lager 500ml', sku: 'BLL-500', category: 'Beverages', unitPrice: 3200, unit: 'bottle'),
  ProductSKU(id: '10', name: 'Kabo Sugar 2kg', sku: 'KBO-2KG', category: 'Sugar', unitPrice: 8500, unit: 'packet'),
];

// ── Main Page ────────────────────────────────────────────────

class SalesTrackingPage extends StatefulWidget {
  const SalesTrackingPage({super.key});

  @override
  State<SalesTrackingPage> createState() => _SalesTrackingPageState();
}

class _SalesTrackingPageState extends State<SalesTrackingPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ProductSKU> _filteredProducts = [];
  final Map<String, int> _cart = {}; // productId → quantity
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_mockProducts);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(_mockProducts);
      } else {
        _filteredProducts = _mockProducts.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.sku.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _updateCart(String productId, int delta) {
    setState(() {
      final current = _cart[productId] ?? 0;
      final next = (current + delta).clamp(0, 999);
      if (next == 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = next;
      }
    });
    // Haptic feedback for snappy field UX
    HapticFeedback.selectionClick();
  }

  int get _totalCartItems =>
      _cart.values.fold(0, (sum, qty) => sum + qty);

  double get _totalCartValue {
    double total = 0;
    for (final entry in _cart.entries) {
      final product = _mockProducts.firstWhere((p) => p.id == entry.key,
          orElse: () => ProductSKU(
              id: '', name: '', sku: '', category: '',
              unitPrice: 0, unit: ''));
      total += product.unitPrice * entry.value;
    }
    return total;
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _proceedToCheckout() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one product to proceed.'),
          backgroundColor: Color(0xFFE53E3E),
        ),
      );
      return;
    }
    // TODO: Navigate to CheckoutPage(cart: _cart)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${_totalCartItems} items | UGX ${_formatCurrency(_totalCartValue)} — proceeding to checkout'),
        backgroundColor: const Color(0xFF276749),
      ),
    );
  }

  String _formatCurrency(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Use Column so the search bar is ALWAYS pinned above the list,
      // even when the keyboard is open. No slivers needed.
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            if (_searchQuery.isNotEmpty)
              _buildSearchResultsChip(),
            Expanded(child: _buildProductList()),
            if (_cart.isNotEmpty) _buildCartSummaryBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      color: const Color(0xFF1A3C5E),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: Color(0xFF63B3ED), size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Q-Route · Sales Tracking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          _buildRouteChip('Kikuubo Zone A'),
        ],
      ),
    );
  }

  Widget _buildRouteChip(String route) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A6496),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_pin, color: Color(0xFFFBD38D), size: 13),
          const SizedBox(width: 4),
          Text(
            route,
            style: const TextStyle(
              color: Color(0xFFFBD38D),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar (LOCKED AT TOP) ─────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF1A3C5E),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A202C)),
        decoration: InputDecoration(
          hintText: 'Search product name, SKU or category…',
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4A90D9), size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: _clearSearch,
                  child: const Icon(Icons.cancel, color: Color(0xFF9CA3AF), size: 20),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF63B3ED), width: 2),
          ),
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  // ── Search Results Chip ────────────────────────────────────

  Widget _buildSearchResultsChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFEBF4FF),
      child: Row(
        children: [
          Text(
            '${_filteredProducts.length} result${_filteredProducts.length == 1 ? '' : 's'} for "$_searchQuery"',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2B6CB0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _clearSearch,
            child: const Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4A90D9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Product ListView ───────────────────────────────────────

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: _filteredProducts.length,
      itemExtent: 88, // Fixed height for maximum scroll performance
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _ProductCard(
          product: product,
          quantity: _cart[product.id] ?? 0,
          onIncrement: () => _updateCart(product.id, 1),
          onDecrement: () => _updateCart(product.id, -1),
          formatCurrency: _formatCurrency,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different name, SKU, or category',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Cart Summary Bar ───────────────────────────────────────

  Widget _buildCartSummaryBar() {
    return GestureDetector(
      onTap: _proceedToCheckout,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFF276749),
          boxShadow: [
            BoxShadow(
              color: Color(0x33276749),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF38A169),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_totalCartItems items',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'UGX ${_formatCurrency(_totalCartValue)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            const Text(
              'Checkout →',
              style: TextStyle(
                color: Color(0xFF9AE6B4),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Card Widget ────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductSKU product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String Function(double) formatCurrency;

  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final isInCart = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isInCart ? const Color(0xFFEBF8F0) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isInCart
              ? const Color(0xFF68D391)
              : const Color(0xFFE2E8F0),
          width: isInCart ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Category color bar
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: _categoryColor(product.category),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: Color(0xFF1A202C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _Chip(label: product.sku, color: const Color(0xFFE2E8F0), textColor: const Color(0xFF4A5568)),
                      const SizedBox(width: 6),
                      _Chip(label: product.category, color: const Color(0xFFBEE3F8), textColor: const Color(0xFF2B6CB0)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // PRICE — READ-ONLY, clearly labelled for reps
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 10, color: Color(0xFFA0AEC0)),
                    const SizedBox(width: 2),
                    Text(
                      'UGX ${formatCurrency(product.unitPrice)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF276749),
                      ),
                    ),
                  ],
                ),
                Text(
                  'per ${product.unit}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
                ),
              ],
            ),

            const SizedBox(width: 10),

            // Quantity stepper
            _QuantityStepper(
              quantity: quantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    const map = {
      'Soap': Color(0xFF9F7AEA),
      'Beverages': Color(0xFF4299E1),
      'Cooking Oil': Color(0xFFED8936),
      'Snacks': Color(0xFFF6AD55),
      'Detergent': Color(0xFF38B2AC),
      'Grains': Color(0xFFD69E2E),
      'Sugar': Color(0xFFE53E3E),
      'Hardware': Color(0xFF718096),
    };
    return map[category] ?? const Color(0xFF4A5568);
  }
}

// ── Quantity Stepper ───────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          onTap: quantity > 0 ? onDecrement : null,
          active: quantity > 0,
        ),
        SizedBox(
          width: 30,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: quantity > 0 ? const Color(0xFF276749) : const Color(0xFFA0AEC0),
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          onTap: onIncrement,
          active: true,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF276749) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? Colors.white : const Color(0xFFC0C0C0),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Chip({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
