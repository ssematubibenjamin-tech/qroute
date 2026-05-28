// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/admin/stock_loading_page.dart
// DESCRIPTION: Admin loads stock onto vans per route.
//              Rep confirms receipt on their end.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../supabase_config.dart';

class StockLoadingPage extends StatefulWidget {
  const StockLoadingPage({super.key});

  @override
  State<StockLoadingPage> createState() => _StockLoadingPageState();
}

class _StockLoadingPageState extends State<StockLoadingPage> {
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedRouteId;
  String? _selectedRouteName;
  bool _loading = false;
  bool _saving = false;

  // Cart: productId → {product, qty}
  final Map<String, Map<String, dynamic>> _loadCart = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final routes = await supabase.from('routes').select().eq('is_active', true).order('name');
      final products = await supabase.from('products').select().eq('is_active', true).order('category');
      setState(() {
        _routes = List<Map<String, dynamic>>.from(routes);
        _products = List<Map<String, dynamic>>.from(products);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _updateQty(String productId, Map<String, dynamic> product, int delta) {
    setState(() {
      final current = (_loadCart[productId]?['qty'] as int?) ?? 0;
      final next = (current + delta).clamp(0, 9999);
      if (next == 0) {
        _loadCart.remove(productId);
      } else {
        _loadCart[productId] = {'product': product, 'qty': next};
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _submitLoad() async {
    if (_selectedRouteId == null) {
      _snack('Please select a route first.', false);
      return;
    }
    if (_loadCart.isEmpty) {
      _snack('Add at least one product to load.', false);
      return;
    }

    setState(() => _saving = true);
    try {
      final adminId = supabase.auth.currentUser!.id;
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final rows = _loadCart.entries.map((e) => {
        'route_id': _selectedRouteId,
        'product_id': e.key,
        'quantity_loaded': e.value['qty'],
        'loaded_by': adminId,
        'load_date': today,
      }).toList();

      await supabase.from('stock_loads').insert(rows);

      _snack('✅ Stock loaded to $_selectedRouteName successfully!', true);
      setState(() {
        _loadCart.clear();
        _selectedRouteId = null;
        _selectedRouteName = null;
      });
    } catch (e) {
      _snack('Failed to save. Check connection.', false);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _snack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF276749) : const Color(0xFFE53E3E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  int get _totalItems => _loadCart.values.fold(0, (s, e) => s + (e['qty'] as int));

  String _ugx(dynamic amount) {
    final val = (amount as num?)?.toDouble() ?? 0.0;
    return 'UGX ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  // Group products by category
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final p in _products) {
      final cat = p['category'] as String;
      map.putIfAbsent(cat, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildRouteSelector(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3C5E)))
                  : _buildProductList(),
            ),
            if (_loadCart.isNotEmpty) _buildLoadBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      color: const Color(0xFF1A3C5E),
      child: const Row(
        children: [
          Icon(Icons.local_shipping_rounded, color: Color(0xFF63B3ED), size: 22),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Van Stock Loading', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Select route → add quantities → submit', style: TextStyle(color: Color(0xFF90CDF4), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSelector() {
    return Container(
      color: const Color(0xFF1A3C5E),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: DropdownButtonFormField<String>(
        value: _selectedRouteId,
        hint: const Text('Select route to load', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          prefixIcon: const Icon(Icons.route_rounded, color: Color(0xFF4A90D9), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        items: _routes.map((r) => DropdownMenuItem(
          value: r['id'] as String,
          child: Text(r['name'] as String, style: const TextStyle(fontSize: 14)),
        )).toList(),
        onChanged: (v) {
          setState(() {
            _selectedRouteId = v;
            _selectedRouteName = _routes.firstWhere((r) => r['id'] == v)['name'];
            _loadCart.clear();
          });
        },
      ),
    );
  }

  Widget _buildProductList() {
    if (_selectedRouteId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_rounded, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Select a route above to start loading',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          ],
        ),
      );
    }

    final grouped = _grouped;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(entry.key.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: Color(0xFF4A5568), letterSpacing: 1)),
            ),
            ...entry.value.map((p) {
              final pid = p['id'] as String;
              final qty = (_loadCart[pid]?['qty'] as int?) ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: qty > 0 ? const Color(0xFFEBF8F0) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: qty > 0 ? const Color(0xFF68D391) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${p['sku']} · ${_ugx(p['unit_price'])} per ${p['unit']}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                        ],
                      ),
                    ),
                    // Qty input
                    Row(
                      children: [
                        _StepBtn(
                          icon: Icons.remove,
                          active: qty > 0,
                          onTap: qty > 0 ? () => _updateQty(pid, p, -1) : null,
                        ),
                        GestureDetector(
                          onTap: () => _showQtyDialog(pid, p, qty),
                          child: SizedBox(
                            width: 44,
                            child: Text(
                              '$qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: qty > 0 ? const Color(0xFF276749) : const Color(0xFFA0AEC0),
                              ),
                            ),
                          ),
                        ),
                        _StepBtn(
                          icon: Icons.add,
                          active: true,
                          onTap: () => _updateQty(pid, p, 1),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  // Tap quantity number to type exact amount
  void _showQtyDialog(String pid, Map<String, dynamic> product, int current) {
    final ctrl = TextEditingController(text: current > 0 ? '$current' : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product['name'] as String, style: const TextStyle(fontSize: 15)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Quantity to load', suffixText: 'units'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF276749)),
            onPressed: () {
              final qty = int.tryParse(ctrl.text) ?? 0;
              setState(() {
                if (qty == 0) {
                  _loadCart.remove(pid);
                } else {
                  _loadCart[pid] = {'product': product, 'qty': qty};
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Set', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadBar() {
    return GestureDetector(
      onTap: _saving ? null : _submitLoad,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: const Color(0xFF276749),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF38A169), borderRadius: BorderRadius.circular(12)),
              child: Text('$_totalItems units', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Load to ${_selectedRouteName ?? '...'}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit →', style: TextStyle(color: Color(0xFF9AE6B4), fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF276749) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 16, color: active ? Colors.white : const Color(0xFFC0C0C0)),
      ),
    );
  }
}
