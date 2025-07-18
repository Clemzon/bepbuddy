import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/model/invoice.dart';
import '../../../data/repository/invoice_repository.dart';

/// Groups every invoice by “MMMM yyyy” (e.g. “April 2025”).
class ReceiptDrawerViewModel extends ChangeNotifier {
  bool isLoading = false;

  /// Key = “Month Year”, Value = list of invoices in that month
  Map<String, List<Invoice>> invoicesByMonth = {};

  /// Load ALL invoices (from 2000–01–01 until today) and group them by month.
  Future<void> loadReceipts() async {
    isLoading = true;
    notifyListeners();

    // fetch everything from 2000-01-01 up to now
    final start = DateTime(2000, 1, 1);
    final end = DateTime.now();
    final all = await InvoiceRepository.instance.getInvoicesBetween(start, end);

    final Map<String, List<Invoice>> map = {};
    for (var inv in all) {
      // e.g. “April 2025”
      final monthKey = DateFormat.yMMMM().format(inv.date);
      map.putIfAbsent(monthKey, () => []).add(inv);
    }

    invoicesByMonth = map;
    isLoading = false;
    notifyListeners();
  }
}