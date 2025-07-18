// lib/ui/invoices/viewmodel/packaged_invoices_viewmodel.dart

import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

import '../../../data/repository/invoice_repository.dart';

/// ViewModel for listing and multi‐selecting ZIP packages related to a given report.
class PackagedInvoicesViewModel extends ChangeNotifier {
  final String reportPath;
  PackagedInvoicesViewModel(this.reportPath);

  bool isLoading = false;
  List<File> packages = [];

  /// Paths of the selected ZIPs.
  final Set<String> selectedPaths = {};

  Future<void> loadPackaged() async {
    dev.log('⏳ loadPackaged() starting for $reportPath');
    isLoading = true;
    notifyListeners();

    try {
      packages = await InvoiceRepository.instance.getInvoicePackages(reportPath);
    } catch (e, st) {
      dev.log('❌ loadPackaged() failed', error: e, stackTrace: st);
      packages = [];
    }

    dev.log('✅ loadPackaged() found ${packages.length} packages');
    isLoading = false;
    notifyListeners();
  }

  /// Toggle a ZIP in or out of the selection set.
  void togglePath(String path) {
    if (!selectedPaths.remove(path)) {
      selectedPaths.add(path);
    }
    dev.log('🔀 selectedPaths: $selectedPaths');
    notifyListeners();
  }

  /// Deletes a package by its file path and notifies listeners.
  void deletePackage(String path) {
    packages.removeWhere((file) => file.path == path);
    // Also remove from selectedPaths if currently selected
    selectedPaths.remove(path);
    dev.log('❌ deletePackage(): removed $path, remaining packages: $packages');
    notifyListeners();
  }
}