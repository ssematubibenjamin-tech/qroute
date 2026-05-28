// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/core/utils/whatsapp_receipt_util.dart
// DESCRIPTION: Utility that builds a WhatsApp deep-link pre-filled
//              with a formatted UGX invoice receipt. Designed for
//              no-printer field environments (Kikuubo, Nakasero, etc.)
// ============================================================

import 'dart:convert';

// ── Data Models ───────────────────────────────────────────────

class ReceiptLineItem {
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;

  const ReceiptLineItem({
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;
}

class SaleReceipt {
  final String receiptNumber;
  final DateTime transactionDate;
  final String shopName;
  final String contactPerson;
  final String customerPhone; // Uganda format: 256XXXXXXXXX
  final String route;
  final String salesRepName;
  final List<ReceiptLineItem> items;
  final double amountPaid;
  final String? notes;

  const SaleReceipt({
    required this.receiptNumber,
    required this.transactionDate,
    required this.shopName,
    required this.contactPerson,
    required this.customerPhone,
    required this.route,
    required this.salesRepName,
    required this.items,
    required this.amountPaid,
    this.notes,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  double get balance => subtotal - amountPaid;
  bool get isFullyPaid => balance <= 0;
}

// ── WhatsApp Receipt Utility ──────────────────────────────────

class WhatsAppReceiptUtil {
  WhatsAppReceiptUtil._(); // Non-instantiable

  // ── Public Entry Point ──────────────────────────────────────
  //
  // Returns a whatsapp://send deep-link with a pre-filled,
  // formatted invoice. Use url_launcher to open it:
  //
  //   final link = WhatsAppReceiptUtil.buildDeepLink(receipt);
  //   if (await canLaunchUrl(Uri.parse(link))) {
  //     await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  //   }

  static String buildDeepLink(SaleReceipt receipt) {
    final phone = _sanitizePhone(receipt.customerPhone);
    final text = _formatReceipt(receipt);
    final encoded = Uri.encodeComponent(text);
    return 'whatsapp://send?phone=$phone&text=$encoded';
  }

  // Fallback: opens WhatsApp Web (useful on desktop/emulators)
  static String buildWebLink(SaleReceipt receipt) {
    final phone = _sanitizePhone(receipt.customerPhone);
    final text = _formatReceipt(receipt);
    final encoded = Uri.encodeComponent(text);
    return 'https://wa.me/$phone?text=$encoded';
  }

  // ── Phone Sanitizer ─────────────────────────────────────────
  // WhatsApp requires: country code + number, digits only, no +
  // Uganda example: 256701234567 (not +256 or 0701234567)

  static String _sanitizePhone(String raw) {
    // Strip all non-digit characters
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    // Normalise Ugandan local numbers starting with 0
    if (digits.startsWith('0') && digits.length == 10) {
      digits = '256${digits.substring(1)}'; // 0701234567 → 256701234567
    }
    // If user typed without country code (9 digits)
    if (digits.length == 9) {
      digits = '256$digits';
    }
    return digits;
  }

  // ── Receipt Formatter ───────────────────────────────────────
  // WhatsApp bold = *text*, italic = _text_
  // Designed for readability on small screens

  static String _formatReceipt(SaleReceipt receipt) {
    final buf = StringBuffer();
    final date = _formatDate(receipt.transactionDate);
    final time = _formatTime(receipt.transactionDate);

    // ── Header ────────────────────────────────────────────────
    buf.writeln('🧾 *Q-ROUTE SALES RECEIPT*');
    buf.writeln(_divider());
    buf.writeln('*Receipt No:* #${receipt.receiptNumber}');
    buf.writeln('*Date:* $date  _($time)_');
    buf.writeln('*Route:* ${receipt.route}');
    buf.writeln('*Rep:* ${receipt.salesRepName}');

    // ── Customer ──────────────────────────────────────────────
    buf.writeln(_divider());
    buf.writeln('🏪 *CUSTOMER*');
    buf.writeln('*Shop:* ${receipt.shopName}');
    buf.writeln('*Contact:* ${receipt.contactPerson}');

    // ── Line Items ────────────────────────────────────────────
    buf.writeln(_divider());
    buf.writeln('📦 *ITEMS PURCHASED*');
    buf.writeln('');

    for (final item in receipt.items) {
      // Product name in bold
      buf.writeln('*${item.productName}*');
      // Details line: qty × price = total
      buf.writeln(
        '  ${item.quantity} × ${_ugx(item.unitPrice)}  =  *${_ugx(item.lineTotal)}*',
      );
      buf.writeln('  _SKU: ${item.sku}_');
      buf.writeln('');
    }

    // ── Totals ────────────────────────────────────────────────
    buf.writeln(_divider());
    buf.writeln('💰 *PAYMENT SUMMARY*');
    buf.writeln('');
    buf.writeln('Total Items : ${receipt.items.length}');
    buf.writeln('*SUBTOTAL   : ${_ugx(receipt.subtotal)}*');
    buf.writeln('Amount Paid : ${_ugx(receipt.amountPaid)}');

    if (receipt.isFullyPaid) {
      buf.writeln('');
      buf.writeln('✅ *FULLY PAID — Thank You!*');
    } else {
      buf.writeln('');
      buf.writeln('⚠️ *BALANCE DUE : ${_ugx(receipt.balance)}*');
      buf.writeln('_Please settle at next delivery._');
    }

    // ── Notes (optional) ─────────────────────────────────────
    if (receipt.notes != null && receipt.notes!.trim().isNotEmpty) {
      buf.writeln(_divider());
      buf.writeln('📝 *NOTE*');
      buf.writeln('_${receipt.notes}_');
    }

    // ── Footer ────────────────────────────────────────────────
    buf.writeln(_divider());
    buf.writeln('_Powered by Q-Route StockCRM Uganda_');
    buf.writeln('_For queries, contact your sales rep._');

    return buf.toString().trimRight();
  }

  // ── Helpers ───────────────────────────────────────────────────

  static String _divider() => '─────────────────────────';

  /// Format amount in Ugandan Shillings with thousand-separators.
  static String _ugx(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'UGX $formatted';
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ── Usage Example (call this from CheckoutPage) ───────────────
//
// void _sendWhatsAppReceipt(BuildContext context) async {
//   final receipt = SaleReceipt(
//     receiptNumber: 'QR-20240315-0042',
//     transactionDate: DateTime.now(),
//     shopName: 'Nalubega General Shop',
//     contactPerson: 'Nalubega Sarah',
//     customerPhone: '256701234567',
//     route: 'Kikuubo Zone A',
//     salesRepName: 'Ssemwezi David',
//     amountPaid: 15000,
//     items: [
//       ReceiptLineItem(
//         productName: 'Mukwano Soap 800g',
//         sku: 'MKW-800',
//         quantity: 5,
//         unitPrice: 3500,
//       ),
//       ReceiptLineItem(
//         productName: 'Rwenzori Water 500ml',
//         sku: 'RWZ-500',
//         quantity: 12,
//         unitPrice: 900,
//       ),
//     ],
//     notes: 'Deliver remaining stock next Tuesday.',
//   );
//
//   final link = WhatsAppReceiptUtil.buildDeepLink(receipt);
//   final uri = Uri.parse(link);
//
//   if (await canLaunchUrl(uri)) {
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   } else {
//     // Fallback to web link on devices without WhatsApp
//     final webLink = WhatsAppReceiptUtil.buildWebLink(receipt);
//     await launchUrl(Uri.parse(webLink));
//   }
// }

// ── Sample Output Preview ─────────────────────────────────────
//
// 🧾 *Q-ROUTE SALES RECEIPT*
// ─────────────────────────
// *Receipt No:* #QR-20240315-0042
// *Date:* 15 Mar 2024  _(9:30 AM)_
// *Route:* Kikuubo Zone A
// *Rep:* Ssemwezi David
// ─────────────────────────
// 🏪 *CUSTOMER*
// *Shop:* Nalubega General Shop
// *Contact:* Nalubega Sarah
// ─────────────────────────
// 📦 *ITEMS PURCHASED*
//
// *Mukwano Soap 800g*
//   5 × UGX 3,500  =  *UGX 17,500*
//   _SKU: MKW-800_
//
// *Rwenzori Water 500ml*
//   12 × UGX 900  =  *UGX 10,800*
//   _SKU: RWZ-500_
//
// ─────────────────────────
// 💰 *PAYMENT SUMMARY*
//
// Total Items : 2
// *SUBTOTAL   : UGX 28,300*
// Amount Paid : UGX 15,000
//
// ⚠️ *BALANCE DUE : UGX 13,300*
// _Please settle at next delivery._
// ─────────────────────────
// 📝 *NOTE*
// _Deliver remaining stock next Tuesday._
// ─────────────────────────
// _Powered by Q-Route StockCRM Uganda_
// _For queries, contact your sales rep._
