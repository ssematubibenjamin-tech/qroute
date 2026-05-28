// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/admin/price_manager_page.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../supabase_config.dart';

class PriceManagerPage extends StatefulWidget {
  const PriceManagerPage({super.key});
  @override
  State<PriceManagerPage> createState() => _PriceManagerPageState();
}

class _PriceManagerPageState extends State<PriceManagerPage> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await supabase.from('products').select().order('category').order('name');
    setState(() { _products = List<Map<String, dynamic>>.from(data); _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered => _products.where((p) {
    final q = _search.toLowerCase();
    return (p['name'] as String).toLowerCase().contains(q) ||
        (p['sku'] as String).toLowerCase().contains(q) ||
        (p['category'] as String).toLowerCase().contains(q);
  }).toList();

  void _editPrice(Map<String, dynamic> product) {
    final ctrl = TextEditingController(text: '${product['unit_price']}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product['sku']}', style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Unit Price (UGX)',
                prefixText: 'UGX ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF276749)),
            onPressed: () async {
              final price = double.tryParse(ctrl.text);
              if (price == null || price <= 0) return;
              await supabase.from('products').update({
                'unit_price': price,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', product['id']);
              Navigator.pop(context);
              _load();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Price updated successfully'),
                backgroundColor: Color(0xFF276749),
              ));
            },
            child: const Text('Update Price', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _ugx(dynamic v) {
    final val = (v as num?)?.toDouble() ?? 0.0;
    return 'UGX ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1A3C5E),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.price_change_rounded, color: Color(0xFF63B3ED), size: 22),
                    SizedBox(width: 8),
                    Text('Price Manager', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Only admins can update prices', style: TextStyle(color: Color(0xFF90CDF4), fontSize: 11)),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search product or SKU…',
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF4A90D9)),
                      filled: true, fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3C5E)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            title: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('${p['sku']} · ${p['category']}', style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_ugx(p['unit_price']),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF276749))),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _editPrice(p),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF4FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF2B6CB0)),
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
        ),
      ),
    );
  }
}


// ============================================================
// FILE: lib/admin/all_transactions_page.dart
// ============================================================

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});
  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _routes = [];
  String? _filterRoute;
  String _filterDate = DateTime.now().toIso8601String().substring(0, 10);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _loadSales();
  }

  Future<void> _loadRoutes() async {
    final data = await supabase.from('routes').select('id, name').eq('is_active', true).order('name');
    setState(() => _routes = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _loadSales() async {
    setState(() => _loading = true);
    try {
      var query = supabase
          .from('sales')
          .select('*, customers(shop_name, phone), profiles(full_name), routes(name)')
          .eq('sale_date', _filterDate)
          .order('created_at', ascending: false);
      if (_filterRoute != null) {
        query = query.eq('route_id', _filterRoute!);
      }
      final data = await query;
      setState(() { _sales = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _ugx(dynamic v) {
    final val = (v as num?)?.toDouble() ?? 0.0;
    return 'UGX ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Color _methodColor(String method) {
    switch (method) {
      case 'cash': return const Color(0xFF276749);
      case 'mobile_money': return const Color(0xFF2B6CB0);
      case 'credit': return const Color(0xFFE53E3E);
      case 'part_payment': return const Color(0xFFD69E2E);
      default: return const Color(0xFF718096);
    }
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'cash': return 'Cash';
      case 'mobile_money': return 'MoMo';
      case 'credit': return 'Credit';
      case 'part_payment': return 'Part Pay';
      default: return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _sales.fold(0.0, (s, e) => s + ((e['subtotal'] as num?)?.toDouble() ?? 0));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1A3C5E),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  const Row(children: [
                    Icon(Icons.receipt_long_rounded, color: Color(0xFF63B3ED), size: 22),
                    SizedBox(width: 8),
                    Text('All Transactions', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _filterDate = picked.toIso8601String().substring(0, 10));
                              _loadSales();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF4A90D9)),
                                const SizedBox(width: 6),
                                Text(_filterDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterRoute,
                          hint: const Text('All Routes', style: TextStyle(fontSize: 12)),
                          decoration: InputDecoration(
                            filled: true, fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Routes', style: TextStyle(fontSize: 12))),
                            ..._routes.map((r) => DropdownMenuItem(value: r['id'] as String, child: Text(r['name'] as String, style: const TextStyle(fontSize: 12)))),
                          ],
                          onChanged: (v) { setState(() => _filterRoute = v); _loadSales(); },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Summary bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF276749),
              child: Row(
                children: [
                  Text('${_sales.length} transactions', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  const Spacer(),
                  Text('Total: ${_ugx(total)}', style: const TextStyle(color: Color(0xFF9AE6B4), fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3C5E)))
                  : _sales.isEmpty
                      ? const Center(child: Text('No transactions found.', style: TextStyle(color: Color(0xFF9CA3AF))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _sales.length,
                          itemBuilder: (_, i) {
                            final s = _sales[i];
                            final customer = s['customers'] as Map?;
                            final rep = s['profiles'] as Map?;
                            final route = s['routes'] as Map?;
                            final method = s['payment_method'] as String;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(customer?['shop_name'] ?? 'Unknown',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _methodColor(method).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(_methodLabel(method),
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _methodColor(method))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${route?['name'] ?? ''} · Rep: ${rep?['full_name'] ?? ''}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                                  Text('Receipt: ${s['receipt_number']}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(_ugx(s['subtotal']),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1A202C))),
                                      const Spacer(),
                                      if ((s['subtotal'] as num) > (s['amount_paid'] as num))
                                        Text('Balance: ${_ugx((s['subtotal'] as num) - (s['amount_paid'] as num))}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFFE53E3E), fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// FILE: lib/admin/credit_ledger_page.dart
// ============================================================

class CreditLedgerPage extends StatefulWidget {
  const CreditLedgerPage({super.key});
  @override
  State<CreditLedgerPage> createState() => _CreditLedgerPageState();
}

class _CreditLedgerPageState extends State<CreditLedgerPage> {
  List<Map<String, dynamic>> _credits = [];
  List<Map<String, dynamic>> _routes = [];
  String? _filterRoute;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _loadCredits();
  }

  Future<void> _loadRoutes() async {
    final data = await supabase.from('routes').select('id, name').eq('is_active', true);
    setState(() => _routes = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _loadCredits() async {
    setState(() => _loading = true);
    try {
      var query = supabase.from('v_customer_credit_balance').select();
      if (_filterRoute != null) {
        // Filter by route name via the view
        final routeName = _routes.firstWhere((r) => r['id'] == _filterRoute)['name'];
        query = query.eq('route_name', routeName);
      }
      final data = await query.order('outstanding_balance', ascending: false);
      setState(() { _credits = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _ugx(dynamic v) {
    final val = (v as num?)?.toDouble() ?? 0.0;
    return 'UGX ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  double get _totalOutstanding => _credits.fold(0, (s, e) => s + ((e['outstanding_balance'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1A3C5E),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF63B3ED), size: 22),
                    SizedBox(width: 8),
                    Text('Credit Ledger', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _filterRoute,
                    hint: const Text('All Routes', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                    decoration: InputDecoration(
                      filled: true, fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.route_rounded, size: 18, color: Color(0xFF4A90D9)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Routes')),
                      ..._routes.map((r) => DropdownMenuItem(value: r['id'] as String, child: Text(r['name'] as String))),
                    ],
                    onChanged: (v) { setState(() => _filterRoute = v); _loadCredits(); },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFE53E3E),
              child: Row(
                children: [
                  Text('${_credits.length} customers with debt', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const Spacer(),
                  Text('Total: ${_ugx(_totalOutstanding)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3C5E)))
                  : _credits.isEmpty
                      ? const Center(child: Text('No outstanding credits. 🎉', style: TextStyle(color: Color(0xFF9CA3AF))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _credits.length,
                          itemBuilder: (_, i) {
                            final c = _credits[i];
                            final balance = (c['outstanding_balance'] as num?)?.toDouble() ?? 0;
                            final isHigh = balance > 50000;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isHigh ? const Color(0xFFFC8181) : const Color(0xFFE2E8F0),
                                  width: isHigh ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: isHigh ? const Color(0xFFFFF5F5) : const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isHigh ? Icons.warning_rounded : Icons.pending_rounded,
                                      color: isHigh ? const Color(0xFFE53E3E) : const Color(0xFFD69E2E),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c['shop_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        Text(c['route_name'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                                        Text('${c['open_invoices']} unpaid invoices', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(_ugx(balance),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800, fontSize: 13,
                                            color: isHigh ? const Color(0xFFE53E3E) : const Color(0xFFD69E2E),
                                          )),
                                      Text('Paid: ${_ugx(c['total_paid'])}',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
