// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/dashboard_page.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sales_tracking_page.dart';
import 'new_customer_page.dart';
import 'whatsapp_receipt_util.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Mock daily stats — replace with Supabase stream
  static const _stats = [
    _Stat(label: 'Sales Today', value: 'UGX 342,500', icon: Icons.trending_up_rounded, color: Color(0xFF276749)),
    _Stat(label: 'Customers Visited', value: '11 / 18', icon: Icons.storefront_rounded, color: Color(0xFF2B6CB0)),
    _Stat(label: 'Items Sold', value: '147 units', icon: Icons.inventory_2_outlined, color: Color(0xFF744210)),
    _Stat(label: 'Outstanding Debt', value: 'UGX 85,000', icon: Icons.warning_amber_rounded, color: Color(0xFFE53E3E)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildRepCard(),
                  const SizedBox(height: 16),
                  _buildStatsGrid(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Quick Actions'),
                  const SizedBox(height: 10),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Recent Transactions'),
                  const SizedBox(height: 10),
                  _buildRecentTransactions(context),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      color: const Color(0xFF1A3C5E),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting 👋',
                  style: const TextStyle(color: Color(0xFF90CDF4), fontSize: 12, fontWeight: FontWeight.w500)),
              const Text('Q-Route Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A6496),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF68D391), size: 8),
                SizedBox(width: 5),
                Text('Online', style: TextStyle(color: Color(0xFF68D391), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rep Identity Card ────────────────────────────────────────

  Widget _buildRepCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3C5E), Color(0xFF2A6496)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF63B3ED),
            child: const Text('SD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ssemwezi David',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Field Sales Rep — Kikuubo Zone A',
                    style: TextStyle(color: Color(0xFF90CDF4), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF276749),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Day 3 of 5',
                style: TextStyle(color: Color(0xFF9AE6B4), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Stats Grid ───────────────────────────────────────────────

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: _stats.map((s) => _StatCard(stat: s)).toList(),
    );
  }

  // ── Quick Actions ────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.point_of_sale_rounded,
          label: 'New Sale',
          color: const Color(0xFF276749),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesTrackingPage())),
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.person_add_rounded,
          label: 'Add Customer',
          color: const Color(0xFF2B6CB0),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewCustomerPage())),
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.whatsapp_rounded,
          label: 'Send Receipt',
          color: const Color(0xFF276749),
          onTap: () => _sendSampleReceipt(context),
        ),
      ],
    );
  }

  void _sendSampleReceipt(BuildContext context) {
    final receipt = SaleReceipt(
      receiptNumber: 'QR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      transactionDate: DateTime.now(),
      shopName: 'Nalubega General Shop',
      contactPerson: 'Nalubega Sarah',
      customerPhone: '256701234567',
      route: 'Kikuubo Zone A',
      salesRepName: 'Ssemwezi David',
      amountPaid: 15000,
      items: [
        const ReceiptLineItem(productName: 'Mukwano Soap 800g', sku: 'MKW-800', quantity: 5, unitPrice: 3500),
        const ReceiptLineItem(productName: 'Rwenzori Water 500ml', sku: 'RWZ-500', quantity: 12, unitPrice: 900),
      ],
      notes: 'Deliver remaining stock next Tuesday.',
    );

    final link = WhatsAppReceiptUtil.buildDeepLink(receipt);

    // Show preview bottom sheet before launching
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiptPreviewSheet(receipt: receipt, deepLink: link),
    );
  }

  // ── Recent Transactions ──────────────────────────────────────

  Widget _buildRecentTransactions(BuildContext context) {
    final transactions = [
      _TxRow(shop: 'Kibuuka Traders', amount: 'UGX 42,000', time: '10:15 AM', paid: true),
      _TxRow(shop: 'Namatovu Shop', amount: 'UGX 18,500', time: '9:42 AM', paid: true),
      _TxRow(shop: 'Ssali Wholesale', amount: 'UGX 95,000', time: '8:55 AM', paid: false),
      _TxRow(shop: 'Kato General', amount: 'UGX 23,200', time: '8:10 AM', paid: true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: transactions.asMap().entries.map((entry) {
          final i = entry.key;
          final tx = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tx.paid ? const Color(0xFFEBF8F0) : const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        tx.paid ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
                        color: tx.paid ? const Color(0xFF276749) : const Color(0xFFE53E3E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.shop, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A202C))),
                          Text(tx.time, style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(tx.amount, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A202C))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tx.paid ? const Color(0xFFEBF8F0) : const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.paid ? 'Paid' : 'Credit',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tx.paid ? const Color(0xFF276749) : const Color(0xFFE53E3E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < transactions.length - 1)
                const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4A5568), letterSpacing: 0.4));
  }
}

// ── Supporting Widgets ─────────────────────────────────────────

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(stat.label, style: const TextStyle(fontSize: 10, color: Color(0xFF718096), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(stat.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A202C))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxRow {
  final String shop;
  final String amount;
  final String time;
  final bool paid;
  const _TxRow({required this.shop, required this.amount, required this.time, required this.paid});
}

// ── Receipt Preview Bottom Sheet ───────────────────────────────

class _ReceiptPreviewSheet extends StatelessWidget {
  final SaleReceipt receipt;
  final String deepLink;
  const _ReceiptPreviewSheet({required this.receipt, required this.deepLink});

  @override
  Widget build(BuildContext context) {
    final text = deepLink.split('&text=').last;
    final decoded = Uri.decodeFull(text);

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.whatsapp_rounded, color: Color(0xFF25D366), size: 22),
                SizedBox(width: 8),
                Text('WhatsApp Receipt Preview',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A202C))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: const Color(0xFFECF8EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: Text(decoded,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1A202C), height: 1.5, fontFamily: 'monospace')),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: const Text('Open in WhatsApp',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                onPressed: () async {
                  Navigator.pop(context);
                  // TODO: await launchUrl(Uri.parse(deepLink), mode: LaunchMode.externalApplication);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add url_launcher to pubspec.yaml to open WhatsApp'),
                      backgroundColor: Color(0xFF25D366),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
