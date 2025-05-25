// lib/ui/invoices/view/invoice_detail_view.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../../data/model/invoice.dart';
import '../../../data/repository/invoice_repository.dart';


class InvoiceDetailView extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailView({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Invoice?>(
      future: InvoiceRepository.instance.getInvoiceById(invoiceId),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: Text('Invoice not found')),
          );
        }
        final inv = snap.data!;
        return Scaffold(
          appBar: AppBar(title: Text(inv.vendorName)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${inv.date.toLocal().toIso8601String().split("T")[0]}'),
                const SizedBox(height: 8),
                Text('Fees: \$${inv.fees.toStringAsFixed(2)}'),
                Text('Taxes: \$${inv.taxes.toStringAsFixed(2)}'),
                Text('Total: \$${inv.total.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                if (inv.attachmentPath != null) ...[
                  const Divider(),
                  Text(
                    'Attachment:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attachment),
                    label: const Text('View Attachment'),
                    onPressed: () {
                      final file = File(inv.attachmentPath!);
                      if (file.existsSync()) {
                        OpenFile.open(file.path);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attachment not found on disk')),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}