// lib/ui/invoices/view/monthly_invoices_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/monthly_invoices_viewmodel.dart';

class MonthlyInvoicesView extends StatelessWidget {
  const MonthlyInvoicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MonthlyInvoicesViewModel>(
      create: (_) => MonthlyInvoicesViewModel()..loadInvoices(),
      child: Scaffold(
        appBar: AppBar(title: const Text("This Month’s Invoices")),
        body: Consumer<MonthlyInvoicesViewModel>(
          builder: (_, vm, __) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.invoices.isEmpty) {
              return const Center(child: Text("No invoices this month."));
            }
            return ListView.builder(
              itemCount: vm.invoices.length,
              itemBuilder: (_, i) {
                final inv = vm.invoices[i];
                final selected = vm.selectedIds.contains(inv.id);
                return ListTile(
                  leading: vm.isSelectionMode
                      ? Checkbox(
                    value: selected,
                    onChanged: (_) => vm.toggleSelection(inv.id),
                  )
                      : null,
                  title: Text(inv.vendorName),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Fees: \$${inv.fees.toStringAsFixed(2)}   "
                              "Taxes: \$${inv.taxes.toStringAsFixed(2)}   "
                              "Total: \$${inv.total.toStringAsFixed(2)}",
                        ),
                      ),
                      if (inv.attachmentPath != null)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.attachment, size: 16),
                        ),
                    ],
                  ),
                  trailing: vm.isSelectionMode && selected
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () {
                    if (vm.isSelectionMode) {
                      vm.toggleSelection(inv.id);
                    } else {
                      Navigator.pushNamed(
                        context,
                        '/invoiceDetail',
                        arguments: inv.id,
                      ).then((_) => vm.loadInvoices());
                    }
                  },
                  onLongPress: () => vm.enterSelection(inv.id),
                );
              },
            );
          },
        ),
        floatingActionButton: Consumer<MonthlyInvoicesViewModel>(
          builder: (_, vm, __) => FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/invoiceCreation')
                .then((_) => vm.loadInvoices()),
            child: const Icon(Icons.add),
          ),
        ),
        bottomNavigationBar: Consumer<MonthlyInvoicesViewModel>(
          builder: (_, vm, __) {
            if (!vm.isSelectionMode) {
              return const SizedBox.shrink();
            }
            return BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("${vm.selectedIds.length} selected"),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: vm.deleteSelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: vm.shareSelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive),
                    onPressed: vm.archiveSelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: vm.clearSelection,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}