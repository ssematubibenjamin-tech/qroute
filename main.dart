import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qwkumohlstnpckukfale.supabase.co',
    anonKey: 'sb_publishable_7gOBduhsmjjoiwpnpQ5wag_EHFiiLNX',
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const QRouteApp());
}

final supabase = Supabase.instance.client;

class QRouteApp extends StatelessWidget {
  const QRouteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q-Route | StockCRM Uganda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A3C5E)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const SplashPage(),
    );
  }
}

// ── Splash ──────────────────────────────────────────────────
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final session = supabase.auth.currentSession;
    if (!mounted) return;
    if (session == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } else {
      _navigateByRole(session.user.id);
    }
  }

  Future<void> _navigateByRole(String uid) async {
    try {
      final profile = await supabase.from('profiles').select('role, full_name, route_id').eq('id', uid).single();
      if (!mounted) return;
      final role = profile['role'] as String;
      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RepHomePage(profile: profile)));
      }
    } catch (e) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A3C5E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_rounded, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text('Q-Route', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('StockCRM Uganda', style: TextStyle(color: Color(0xFF90CDF4), fontSize: 14)),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Color(0xFF68D391), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

// ── Login ────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (!mounted) return;
      if (res.user == null) { setState(() => _error = 'Invalid credentials'); return; }

      final profile = await supabase.from('profiles').select('role, full_name, route_id').eq('id', res.user!.id).single();
      if (!mounted) return;
      final role = profile['role'] as String;
      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RepHomePage(profile: profile)));
      }
    } catch (e) {
      setState(() => _error = e.toString().contains('Invalid') ? 'Wrong email or password' : 'Check internet connection');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3C5E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: const Color(0xFF276749), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.route_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 16),
                const Text('Q-Route', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('StockCRM Uganda', style: TextStyle(color: Color(0xFF90CDF4), fontSize: 14)),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sign In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFFFF5F5), borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3C5E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Admin Home ───────────────────────────────────────────────
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  String _ugx(double v) => 'UGX ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              color: const Color(0xFF1A3C5E),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('Q-Route StockCRM Uganda', style: TextStyle(color: Color(0xFF90CDF4), fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: Future.wait([
                  supabase.from('sales').select('subtotal, amount_paid, payment_method').eq('sale_date', DateTime.now().toIso8601String().substring(0, 10)),
                  supabase.from('customers').select('id'),
                  supabase.from('credits').select('balance').neq('status', 'cleared'),
                ]),
                builder: (context, snapshot) {
                  double gross = 0, cash = 0, momo = 0, credit = 0;
                  int customers = 0;
                  double totalCredit = 0;

                  if (snapshot.hasData) {
                    final sales = snapshot.data![0] as List;
                    customers = (snapshot.data![1] as List).length;
                    final credits = snapshot.data![2] as List;
                    for (final s in sales) {
                      gross += (s['subtotal'] as num).toDouble();
                      if (s['payment_method'] == 'cash') cash += (s['amount_paid'] as num).toDouble();
                      if (s['payment_method'] == 'mobile_money') momo += (s['amount_paid'] as num).toDouble();
                    }
                    for (final c in credits) {
                      totalCredit += ((c['balance'] as num?)?.toDouble() ?? 0);
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Universe card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1A3C5E), Color(0xFF2A6496)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Today\'s Universe', style: TextStyle(color: Color(0xFF90CDF4), fontSize: 12)),
                            const SizedBox(height: 6),
                            Text(_ugx(gross), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                            const Text('Gross Sales', style: TextStyle(color: Color(0xFF90CDF4), fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatBox(label: 'Cash', value: _ugx(cash)),
                                const SizedBox(width: 8),
                                _StatBox(label: 'MoMo', value: _ugx(momo)),
                                const SizedBox(width: 8),
                                _StatBox(label: 'Credit', value: _ugx(credit), danger: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quick stats
                      Row(
                        children: [
                          Expanded(child: _QuickStat(label: 'Total Customers', value: '$customers', icon: Icons.storefront_rounded, color: const Color(0xFF2B6CB0))),
                          const SizedBox(width: 10),
                          Expanded(child: _QuickStat(label: 'Outstanding Credit', value: _ugx(totalCredit), icon: Icons.warning_rounded, color: const Color(0xFFE53E3E))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Menu grid
                      const Text('Modules', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF4A5568))),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: [
                          _MenuCard(icon: Icons.local_shipping_rounded, label: 'Load Stock', color: const Color(0xFF276749), onTap: () => _showComingSoon(context)),
                          _MenuCard(icon: Icons.price_change_rounded, label: 'Manage Prices', color: const Color(0xFF2B6CB0), onTap: () => _showComingSoon(context)),
                          _MenuCard(icon: Icons.receipt_long_rounded, label: 'All Transactions', color: const Color(0xFF744210), onTap: () => _showComingSoon(context)),
                          _MenuCard(icon: Icons.account_balance_wallet_rounded, label: 'Credit Ledger', color: const Color(0xFFE53E3E), onTap: () => _showComingSoon(context)),
                          _MenuCard(icon: Icons.point_of_sale_rounded, label: 'Counter Sale', color: const Color(0xFF553C9A), onTap: () => _showComingSoon(context)),
                          _MenuCard(icon: Icons.picture_as_pdf_rounded, label: 'PDF Reports', color: const Color(0xFF2C7A7B), onTap: () => _showComingSoon(context)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Module coming in next update!'), backgroundColor: Color(0xFF276749)),
    );
  }
}

// ── Rep Home ─────────────────────────────────────────────────
class RepHomePage extends StatelessWidget {
  final Map<String, dynamic> profile;
  const RepHomePage({super.key, required this.profile});

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  String _ugx(double v) => 'UGX ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final name = profile['full_name']?.toString().split(' ').first ?? 'Rep';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              color: const Color(0xFF276749),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello $name! 👋', style: const TextStyle(color: Color(0xFF9AE6B4), fontSize: 12)),
                        const Text('My Route Dashboard', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: supabase.from('sales').select('subtotal, payment_method').eq('rep_id', supabase.auth.currentUser!.id).eq('sale_date', DateTime.now().toIso8601String().substring(0, 10)),
                builder: (context, snapshot) {
                  double gross = 0;
                  int count = 0;
                  if (snapshot.hasData) {
                    final sales = snapshot.data as List;
                    count = sales.length;
                    for (final s in sales) gross += (s['subtotal'] as num).toDouble();
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF276749), Color(0xFF38A169)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Today's Sales", style: TextStyle(color: Color(0xFF9AE6B4), fontSize: 12)),
                            const SizedBox(height: 6),
                            Text(_ugx(gross), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                            Text('$count transactions', style: const TextStyle(color: Color(0xFF9AE6B4), fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Modules', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF4A5568))),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: [
                          _MenuCard(icon: Icons.point_of_sale_rounded, label: 'Make a Sale', color: const Color(0xFF276749), onTap: () => _snack(context)),
                          _MenuCard(icon: Icons.person_add_rounded, label: 'New Customer', color: const Color(0xFF2B6CB0), onTap: () => _snack(context)),
                          _MenuCard(icon: Icons.account_balance_wallet_rounded, label: 'Add Credit', color: const Color(0xFFE53E3E), onTap: () => _snack(context)),
                          _MenuCard(icon: Icons.whatsapp_rounded, label: 'WhatsApp Receipt', color: const Color(0xFF25D366), onTap: () => _snack(context)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Module coming in next update!'), backgroundColor: Color(0xFF276749)),
    );
  }
}

// ── Shared Widgets ───────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;
  const _StatBox({required this.label, required this.value, this.danger = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: danger ? const Color(0xFFFC8181) : const Color(0xFF9AE6B4), fontSize: 10, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _QuickStat({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
                Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1A202C)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
