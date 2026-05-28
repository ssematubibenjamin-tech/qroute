// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/admin/admin_shell.dart
// DESCRIPTION: Admin bottom navigation shell — 5 main modules
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_dashboard_page.dart';
import 'stock_loading_page.dart';
import 'price_manager_page.dart';
import 'all_transactions_page.dart';
import 'credit_ledger_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _pages = const [
    AdminDashboardPage(),
    StockLoadingPage(),
    PriceManagerPage(),
    AllTransactionsPage(),
    CreditLedgerPage(),
  ];

  final _items = const [
    _NavItem(Icons.dashboard_outlined,       Icons.dashboard_rounded,          'Dashboard'),
    _NavItem(Icons.local_shipping_outlined,  Icons.local_shipping_rounded,     'Stock'),
    _NavItem(Icons.price_change_outlined,    Icons.price_change_rounded,       'Prices'),
    _NavItem(Icons.receipt_long_outlined,    Icons.receipt_long_rounded,       'Sales'),
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
                  onTap: () {
                    setState(() => _index = i);
                    HapticFeedback.selectionClick();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFEBF4FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          active ? item.activeIcon : item.icon,
                          color: active ? const Color(0xFF1A3C5E) : const Color(0xFF9CA3AF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? const Color(0xFF1A3C5E) : const Color(0xFF9CA3AF),
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
