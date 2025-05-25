import 'package:flutter/material.dart';
import '../../../data/repository/invoice_repository.dart';

class MonthlySummaryView extends StatefulWidget {
  const MonthlySummaryView({super.key});

  @override
  State<MonthlySummaryView> createState() => _MonthlySummaryViewState();
}

class _MonthlySummaryViewState extends State<MonthlySummaryView> {
  bool _isLoading = true;
  int _count = 0;
  double _fees = 0, _taxes = 0, _total = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end   = DateTime(now.year, now.month + 1, 0);

    final invoices =
    await InvoiceRepository.instance.getInvoicesBetween(start, end);

    setState(() {
      _count   = invoices.length;
      _fees    = invoices.fold(0, (sum, inv) => sum + inv.fees);
      _taxes   = invoices.fold(0, (sum, inv) => sum + inv.taxes);
      _total   = invoices.fold(0, (sum, inv) => sum + inv.total);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoices this month: $_count',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text('Total Fees:    \$${_fees.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text('Total Taxes:  \$${_taxes.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text('Grand Total: \$${_total.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}