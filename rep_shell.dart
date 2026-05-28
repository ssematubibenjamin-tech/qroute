// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/rep/rep_shell.dart
// DESCRIPTION: Rep navigation shell — 4 modules for field reps
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../sales_tracking_page.dart';
import '../new_customer_page.dart';

class RepShell extends StatefulWidget {
  final Map<String, dynamic> profile;
  const RepShell({super.key, required this.profile});

  @override
  State<RepShell> createState() => _RepShellState();
}

class _RepShellState extends State<RepShell> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      RepDashboardPage(profile: widget.profile),
      const SalesTrackingPage(),
      const NewCustomerPage(),
      _PlaceholderPage(label: 'Credit Manager', icon: Icons.account_balance_wallet_outlined),
    ];
  }

  final _items = const [
    _NavItem(Icons.dashboard_outlined,      Icons.dashboard_rounded,       'Home'),
    _NavItem(Icons.point_of_sale_outlined,  Icons.point_of_sale_rounded,   'Sales'),
    _NavItem(Icons.person_add_outlined,     Icons.person_add_rounded,      'Customer'),
    _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Credits'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = _index == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () { setState(() => _index = i); HapticFeedback.selectionClick(); },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFEBF8F0) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(active ? item.activeIcon : item.icon,
                            color: active ? const Color(0xFF276749) : const Color(0xFF9CA3AF), size: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? const Color(0xFF276749) : const Color(0xFF9CA3AF),
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _PlaceholderPage extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderPage({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF276749),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
                    const SizedBox(height: 6),
                    const Text('Coming in next phase.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// FILE: lib/rep/rep_dashboard_page.dart
// ============================================================

class RepDashboardPage extends StatefulWidget {
  final Map<String, dynamic> profile;
  const RepDashboardPage({super.key, required this.profile});

  @override
  State<RepDashboardPage> createState() => _RepDashboardPageState();
}

class _RepDashboardPageState extends State<RepDashboardPage> {
  bool _loading = true;
  Map<String, dynamic> _todayStats = {};
  List<Map<String, dynamic>> _stockBalance = [];
  List<Map<String, dynamic>> _recentSales = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final routeId = widget.profile['route_id'] as String?;
      final repId = supabase.auth.currentUser!.id;
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Today's sales by this rep
      final sales = await supabase
          .from('sales')
          .select('subtotal, amount_paid, payment_method')
          .eq('rep_id', repId)
          .eq('sale_date', today);

      double gross = 0, cash = 0, momo = 0, credit = 0;
      for (final s in sales) {
        final sub = (s['subtotal'] as num).toDouble();
        final paid = (s['amount_paid'] as num).toDouble();
        gross += sub;
        if (s['payment_method'] == 'cash') cash += paid;
        if (s['payment_method'] == 'mobile_money') momo += paid;
        if (['credit', 'part_payment'].contains(s['payment_method'])) credit += (sub - paid);
      }

      // Stock balance from view
      List<Map<String, dynamic>> stock = [];
      if (routeId != null) {
        final stockData = await supabase
            .from('v_route_stock_position')
            .select()
            .eq('route_name', widget.profile['route_name'] ?? '');
        stock = List<Map<String, dynamic>>.from(stockData);
      }

      // Recent 5 sales
      final recent = await supabase
          .from('sales')
          .select('receipt_number, subtotal, payment_method, created_at, customers(shop_name)')
          .eq('rep_id', repId)
          .eq('sale_date', today)
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _todayStats = {'gross': gross, 'cash': cash, 'momo': momo, 'credit': credit, 'count': sales.length};
        _stockBalance = stock;
        _recentSales = List<Map<String, dynamic>>.from(recent);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
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
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF276749)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF276749),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildTodayCard(),
                          const SizedBox(height: 16),
                          _buildSectionLabel('📦 Van Stock Balance'),
                          const SizedBox(height: 10),
                          _buildStockBalance(),
                          const SizedBox(height: 16),
                          _buildSectionLabel('🧾 Recent Sales Today'),
                          const SizedBox(height: 10),
                          _buildRecentSales(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      color: const Color(0xFF276749),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${widget.profile['full_name']?.toString().split(' ').first ?? 'Rep'} 👋',
                    style: const TextStyle(color: Color(0xFF9AE6B4), fontSize: 12)),
                const Text('My Route Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF38A169), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.location_pin, color: Color(0xFFFBD38D), size: 13),
                const SizedBox(width: 4),
                Text(widget.profile['route_name'] ?? 'My Route',
                    style: const TextStyle(color: Color(0xFFFBD38D), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF276749), Color(0xFF38A169)],
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
              const Text("Today's Performance",
                  style: TextStyle(color: Color(0xFF9AE6B4), fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF276749), borderRadius: BorderRadius.circular(10)),
                child: Text('${_todayStats['count'] ?? 0} sales',
                    style: const TextStyle(color: Color(0xFF9AE6B4), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_ugx(_todayStats['gross'] ?? 0),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const Text('Gross Sales', style: TextStyle(color: Color(0xFF9AE6B4), fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              _RepStat(label: 'Cash', value: _ugx(_todayStats['cash'] ?? 0)),
              const SizedBox(width: 8),
              _RepStat(label: 'MoMo', value: _ugx(_todayStats['momo'] ?? 0)),
              const SizedBox(width: 8),
              _RepStat(label: 'Credit', value: _ugx(_todayStats['credit'] ?? 0), danger: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockBalance() {
    if (_stockBalance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: const Text('No stock loaded today yet.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
      );
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: _stockBalance.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final balance = (s['van_balance'] as num?)?.toInt() ?? 0;
          final isLow = balance < 5;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(s['sku'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$balance units',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                                color: isLow ? const Color(0xFFE53E3E) : const Color(0xFF276749))),
                        if (isLow) const Text('Low stock', style: TextStyle(fontSize: 10, color: Color(0xFFE53E3E))),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < _stockBalance.length - 1) const Divider(height: 1, color: Color(0xFFEDF2F7)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentSales() {
    if (_recentSales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: const Text('No sales recorded yet today.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
      );
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: _recentSales.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final customer = s['customers'] as Map?;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_rounded, color: Color(0xFF276749), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer?['shop_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(s['receipt_number'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    Text(_ugx(s['subtotal']),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A202C))),
                  ],
                ),
              ),
              if (i < _recentSales.length - 1) const Divider(height: 1, color: Color(0xFFEDF2F7)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionLabel(String label) =>
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4A5568)));
}

class _RepStat extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;
  const _RepStat({required this.label, required this.value, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: danger ? const Color(0xFFFC8181) : const Color(0xFF9AE6B4), fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// Missing import at top of rep_shell.dart — add this:
// import '../supabase_config.dart';
final supabase = SupabaseConfig.client;
class SupabaseConfig { static get client => null; } // placeholder — use real one from supabase_config.dart
