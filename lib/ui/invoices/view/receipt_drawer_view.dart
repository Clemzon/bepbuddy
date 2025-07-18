import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';  // ← added

import '../viewmodel/receipt_drawer_viewmodel.dart';

class ReceiptDrawerView extends StatelessWidget {
  const ReceiptDrawerView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReceiptDrawerViewModel>(
      create: (_) => ReceiptDrawerViewModel()..loadReceipts(),
      child: Scaffold(
        appBar: AppBar(title: const Text('All Receipts')),
        body: Consumer<ReceiptDrawerViewModel>(
          builder: (_, vm, __) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.invoicesByMonth.isEmpty) {
              return const Center(child: Text('No receipts found.'));
            }
            return ListView(
              children: vm.invoicesByMonth.entries.map((entry) {
                final month = entry.key;
                final invoices = entry.value;
                return ExpansionTile(
                  title: Text(month, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  children: invoices.map((inv) {
                    return ListTile(
                      title: Text(inv.vendorName),
                      subtitle: Text(
                        DateFormat.yMd().format(inv.date),  // ← replaced `inv.dateFormatted`
                      ),
                      trailing: Text('\$${inv.total.toStringAsFixed(2)}'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/invoiceDetail',
                        arguments: inv.id,
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}