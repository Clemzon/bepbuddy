import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/model/invoice.dart';
import '../../../data/repository/invoice_repository.dart';
import '../../../main.dart';


class MonthlyInvoicesViewModel extends ChangeNotifier {
  final _repo = InvoiceRepository.instance;

  bool isLoading = false;
  List<Invoice> invoices = [];
  final selectedIds = <String>{};

  bool get isSelectionMode => selectedIds.isNotEmpty;

  Future<void> loadInvoices() async {
    isLoading = true;
    notifyListeners();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    invoices = await _repo.getInvoicesBetween(start, end);
    isLoading = false;
    notifyListeners();
  }

  void enterSelection(String id) {
    selectedIds.add(id);
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (!selectedIds.remove(id)) selectedIds.add(id);
    notifyListeners();
  }

  void clearSelection() {
    selectedIds.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    for (var id in selectedIds) {
      await _repo.deleteInvoice(id);
    }
    clearSelection();
    await loadInvoices();
  }

  Future<void> shareSelected() async {
    final txt = invoices
        .where((inv) => selectedIds.contains(inv.id))
        .map((inv) =>
    '${inv.vendorName} — ${inv.date.toLocal().toIso8601String().split("T")[0]}\n'
        'Fees: \$${inv.fees.toStringAsFixed(2)}\n'
        'Taxes: \$${inv.taxes.toStringAsFixed(2)}\n'
        'Total: \$${inv.total.toStringAsFixed(2)}')
        .join('\n\n');
    await SharePlus.instance.share(txt as ShareParams);
    clearSelection();
  }

  /// ONLY packages—does not delete or modify invoices themselves.
  Future<void> archiveSelected() async {
    final ids = selectedIds.toList();
    final zipPath = await _repo.packageInvoices(ids);
    clearSelection();

    final ctx = navigatorKey.currentContext!;
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('Packaged ${ids.length} invoice(s) into ${zipPath.split('/').last}'),
        action: SnackBarAction(
          label: 'View Packages',
          onPressed: () => Navigator.pushNamed(ctx, '/packagedInvoices'),
        ),
      ),
    );
  }
}