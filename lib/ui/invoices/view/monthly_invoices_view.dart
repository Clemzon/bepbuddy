// lib/ui/invoices/view/monthly_invoices_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../viewmodel/monthly_invoices_viewmodel.dart';

class MonthlyInvoicesView extends StatelessWidget {
  const MonthlyInvoicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MonthlyInvoicesViewModel>(
      create: (_) => MonthlyInvoicesViewModel()..loadInvoices(),
      builder: (context, child) {
        final vm = Provider.of<MonthlyInvoicesViewModel>(context, listen: true);
        return Scaffold(
          appBar: AppBar(title: Text('${DateFormat.MMMM().format(DateTime.now())} Invoices')),
          body: () {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.invoices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("No invoices this month.", style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: vm.loadInvoices,
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: vm.invoices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final inv = vm.invoices[i];
                  final selected = vm.selectedIds.contains(inv.id);
                  return Dismissible(
                    key: ValueKey(inv.id),
                    direction: vm.isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete invoice?'),
                          content: Text('Delete invoice from ${inv.vendorName}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (_) async {
                      vm.enterSelection(inv.id);
                      vm.deleteSelected();
                    },
                    background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                    child: ListTile(
                      leading: vm.isSelectionMode
                          ? Checkbox(value: selected, onChanged: (_) => vm.toggleSelection(inv.id))
                          : null,
                      title: Text(inv.vendorName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat.yMMMd().format(inv.date)),
                          Text(
                            'Fees: ${NumberFormat.simpleCurrency().format(inv.fees)}   '
                            'Taxes: ${NumberFormat.simpleCurrency().format(inv.taxes)}   '
                            'Total: ${NumberFormat.simpleCurrency().format(inv.total)}',
                          ),
                        ],
                      ),
                      trailing: vm.isSelectionMode && selected ? const Icon(Icons.check_circle) : null,
                      onTap: () {
                        if (vm.isSelectionMode) {
                          vm.toggleSelection(inv.id);
                        } else {
                          Navigator.pushNamed(context, '/invoiceDetail', arguments: inv.id)
                              .then((_) => vm.loadInvoices());
                        }
                      },
                      onLongPress: () => vm.enterSelection(inv.id),
                    ),
                  );
                },
              ),
            );
          }(),
          floatingActionButton: Tooltip(
            message: 'Add invoice',
            child: FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/invoiceCreation').then((_) => vm.loadInvoices()),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              elevation: 6,
              child: const Icon(Icons.add),
            ),
          ),
          bottomNavigationBar: vm.isSelectionMode
              ? BottomAppBar(
                  shape: const CircularNotchedRectangle(),
                  notchMargin: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("${vm.selectedIds.length} selected"),
                      Tooltip(
                        message: 'Delete selected',
                        child: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Delete ${vm.selectedIds.length} selected invoice(s)?'),
                                content: const Text('Are you sure you want to delete the selected invoices?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.showSnackBar(const SnackBar(content: Text('Deleting invoices...')));
                              await vm.deleteSelected();
                              messenger.showSnackBar(const SnackBar(content: Text('Invoices deleted')));
                            }
                          },
                        ),
                      ),
                      Tooltip(
                        message: 'Share selected',
                        child: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(const SnackBar(content: Text('Preparing share...')));
                            await vm.shareSelected();
                            messenger.showSnackBar(const SnackBar(content: Text('Share complete')));
                          },
                        ),
                      ),
                      Tooltip(
                        message: 'Archive selected',
                        child: IconButton(
                          icon: const Icon(Icons.archive),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(const SnackBar(content: Text('Archiving invoices...')));
                            await vm.archiveSelected();
                            messenger.showSnackBar(const SnackBar(content: Text('Invoices archived')));
                          },
                        ),
                      ),
                      Tooltip(
                        message: 'Clear selection',
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: vm.clearSelection,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}