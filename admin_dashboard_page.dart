// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/admin/admin_dashboard_page.dart
// DESCRIPTION: Admin home — universe overview, route summaries,
//              top products, credit totals. All live from Supabase.
// ============================================================

import 'package:flutter/material.dart';
import '../supabase_config.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _loading = true;
  Map<String, dynamic> _universe = {};
  List<Map<String, dynamic>> _routeSummaries = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _creditAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Universe totals — today
      final sales = await supabase
          .from('sales')
          .select('subtotal, amount_paid, payment_method')
          .eq('sale_date', _today());

      double totalGross = 0, totalCash = 0, totalMomo = 0, totalCredit = 0;
      for (final s in sales) {
        final subtotal = (s['subtotal'] as num).toDouble();
        final paid = (s['amount_paid'] as num).toDouble();
        totalGross += subtotal;
        if (s['payment_method'] == 'cash') totalCash += paid;
        if (s['payment_method'] == 'mobile_money') totalMomo += paid;
        if (s['payment_method'] == 'credit') totalCredit += subtotal;
        if (s['payment_method'] == 'part_payment') totalCredit += (subtotal - paid);
      }

      // Route summaries from view
      final routeData = await supabase
          .from('v_daily_sales_by_route')
          .select()
          .eq('sale_date', _today());

      // Top products from view
      final topProds = await supabase
          .from('v_top_products')
          .select()
          .limit(5);

      // Credit alerts — top 5 outstanding
      final credits = await supabase
          .from('v_customer_credit_balance')
          .select()
          .order('outstanding_balance', ascending: false)
          .limit(5);

      setState(() {
        _universe = {
          'gross': totalGross,
          'cash': totalCash,
          'momo': totalMomo,
          'credit': totalCredit,
          'transactions': sales.length,
        };
        _routeSummaries = List<Map<String, dynamic>>.from(routeData);
        _topProducts = List<Map<String, dynamic>>.from(topProds);
        _creditAlerts = List<Map<String, dynamic>>.from(credits);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  String _ugx(dynamic amount) {
    final val = (amount as num?)?.toDouble() ?? 0.0;
    return 'UGX ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3C5E)))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFF1A3C5E),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildUniverseCard(),
                          const SizedBox(height: 16),
                          _buildSectionLabel('📍 Route Performance — Today'),
                          const SizedBox(height: 10),
                          _buildRouteSummaries(),
                          const SizedBox(height: 16),
                          _buildSectionLabel('🏆 Top Products (Last 30 Days)'),
                          const SizedBox(height: 10),
                          _buildTopProducts(),
                          const SizedBox(height: 16),
                          _buildSectionLabel('⚠️ Credit Alerts'),
                          const SizedBox(height: 10),
                          _buildCreditAlerts(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      color: const Color(0xFF1A3C5E),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, Admin 👋',
                    style: const TextStyle(color: Color(0xFF90CDF4), fontSize: 12)),
                const Text('Q-Route Admin Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Today', style: TextStyle(color: Color(0xFF90CDF4), fontSize: 10)),
              Text(dateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Universe Card ─────────────────────────────────────────────

  Widget _buildUniverseCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3C5E), Color(0xFF2A6496)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Universe Overview',
                  style: TextStyle(color: Color(0xFF90CDF4), fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF276749),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_universe['transactions'] ?? 0} txns',
                    style: const TextStyle(color: Color(0xFF9AE6B4), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_ugx(_universe['gross'] ?? 0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              )),
          const Text('Total Gross Sales Today',
              style: TextStyle(color: Color(0xFF90CDF4), fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              _UniverseStat(label: 'Cash', value: _ugx(_universe['cash'] ?? 0), color: const Color(0xFF68D391)),
              const SizedBox(width: 8),
              _UniverseStat(label: 'MoMo', value: _ugx(_universe['momo'] ?? 0), color: const Color(0xFFFBD38D)),
              const SizedBox(width: 8),
              _UniverseStat(label: 'Credit', value: _ugx(_universe['credit'] ?? 0), color: const Color(0xFFFC8181)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Route Summaries ───────────────────────────────────────────

  Widget _buildRouteSummaries() {
    if (_routeSummaries.isEmpty) {
      return _emptyCard('No route sales recorded today yet.');
    }
    return Column(
      children: _routeSummaries.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.route_rounded, color: Color(0xFF2B6CB0), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['route_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A202C))),
                    Text('${r['total_transactions'] ?? 0} sales',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_ugx(r['gross_sales']),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1A202C))),
                  if ((r['credit_issued'] as num? ?? 0) > 0)
                    Text('Credit: ${_ugx(r['credit_issued'])}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFFE53E3E))),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Top Products ──────────────────────────────────────────────

  Widget _buildTopProducts() {
    if (_topProducts.isEmpty) {
      return _emptyCard('No product sales data yet.');
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: _topProducts.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i == 0 ? const Color(0xFFFEF3C7) : const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('#${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: i == 0 ? const Color(0xFFD69E2E) : const Color(0xFF718096),
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['product_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${p['total_units_sold']} units sold',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                        ],
                      ),
                    ),
                    Text(_ugx(p['total_revenue']),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF276749))),
                  ],
                ),
              ),
              if (i < _topProducts.length - 1)
                const Divider(height: 1, color: Color(0xFFEDF2F7)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Credit Alerts ─────────────────────────────────────────────

  Widget _buildCreditAlerts() {
    if (_creditAlerts.isEmpty) {
      return _emptyCard('No outstanding credit balances. 🎉');
    }
    return Column(
      children: _creditAlerts.map((c) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD69E2E), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['shop_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(c['route_name'] ?? '',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_ugx(c['outstanding_balance']),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFE53E3E))),
                  Text('${c['open_invoices']} invoices',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4A5568)));
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
      ),
    );
  }
}

class _UniverseStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _UniverseStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
