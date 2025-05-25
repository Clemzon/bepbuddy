import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bepbuddy/ui/report/viewmodel/monthly_report_view_model.dart';

class MonthlyReportView extends StatelessWidget {
  const MonthlyReportView({super.key});
  static const routeName = '/report/new';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MonthlyReportViewModel>(
      create: (_) => MonthlyReportViewModel(context.read()),
      child: const _MonthlyReportScreen(),
    );
  }
}

class _MonthlyReportScreen extends StatelessWidget {
  const _MonthlyReportScreen();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonthlyReportViewModel>();
    final hasResult = vm.lastReport != null;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New Monthly Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Manager’s Details ──
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manager’s Details', style: t.titleLarge),
                    const SizedBox(height: 12),
                    _formField(
                      context: context,
                      label: 'Stand Number',
                      initial: vm.standNumber,
                      keyboard: TextInputType.number,
                      onChanged: (v) => vm.standNumber = v,
                    ),
                    _formField(
                      context: context,
                      label: 'Manager’s Name',
                      initial: vm.managerName,
                      onChanged: (v) => vm.managerName = v,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // ── Month ──
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Month', style: t.titleLarge),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: vm.month.isEmpty ? null : vm.month,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        'January','February','March','April','May','June',
                        'July','August','September','October','November','December'
                      ].map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (m) => vm.month = m ?? '',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // ── Financial Details ──
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Financial Details', style: t.titleLarge),
                    const SizedBox(height: 12),
                    _numField(
                      context: context,
                      label: 'Invoices Paid',
                      onChanged: (v) => vm.invoicesPaid = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Helper’s Salary',
                      onChanged: (v) => vm.helpersSalary = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Gross Sales',
                      onChanged: (v) => vm.grossSales = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Vending Machine Sales',
                      onChanged: (v) => vm.vendingMachineSales = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Cost of Goods Purchased',
                      onChanged: (v) => vm.costOfGoodsPurchased = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Utilities',
                      onChanged: (v) => vm.utilities = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Liability Insurance',
                      onChanged: (v) => vm.liabilityInsurance = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Vending Machine Income',
                      onChanged: (v) => vm.vendingMachineIncome = double.tryParse(v) ?? 0,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // ── Sales Tax Rate ──
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sales Tax Rate (%)', style: t.titleLarge),
                    const SizedBox(height: 12),
                    _formField(
                      context: context,
                      label: 'e.g. 8.0 for 8%',
                      initial: vm.salesTaxRate == 0
                          ? ''
                          : (vm.salesTaxRate * 100).toString(),
                      keyboard: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => vm.salesTaxRate = (double.tryParse(v) ?? 8) / 100,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: vm.calculate,
                    child: const Text('Calculate'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: hasResult ? vm.save : null,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            // ── Results ──
            if (hasResult) ..._buildResults(vm),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults(MonthlyReportViewModel vm) {
    final r = vm.lastReport!;
    return [
      Text('Gross Cash: ${vm.asCurrency(r.grossCash)}'),
      Text('Total Gross Sales: ${vm.asCurrency(r.totalGrossSales)}'),
      Text('Net Taxable Sales: ${vm.asCurrency(r.netTaxableSales)}'),
      Text('Retail Sales Tax: ${vm.asCurrency(r.retailSalesTax)}'),
      Text('Sales Tax from Vending: ${vm.asCurrency(r.salesTaxFromVendingMachines)}'),
      Text('Total Sales Tax Due: ${vm.asCurrency(r.totalSalesTaxDue)}'),
      Text('Minus Tax Discount: ${vm.asCurrency(r.minusTaxDiscount)}'),
      Text('Net Amount of Sales Tax Due: ${vm.asCurrency(r.netAmountOfSalesTaxDue)}'),
      Text('Total of Lines: ${vm.asCurrency(r.totalOfLines)}'),
      Text('Net Earnings for the Month: ${vm.asCurrency(r.netEarningsForTheMonth)}'),
      Text('Total Net Earnings: ${vm.asCurrency(r.totalNetEarnings)}'),
      Text('Earnings %: ${r.percentageOfEarningsForTheMonth.toStringAsFixed(2)}%'),
    ];
  }

  Widget _formField({
    required BuildContext context,
    required String label,
    String initial = '',
    required ValueChanged<String> onChanged,
    TextInputType keyboard = TextInputType.text,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboard,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) {
          if (isLast) {
            FocusScope.of(context).unfocus();
          } else {
            FocusScope.of(context).nextFocus();
          }
        },
        onChanged: onChanged,
      ),
    );
  }

  Widget _numField({
    required BuildContext context,
    required String label,
    required ValueChanged<String> onChanged,
    bool isLast = false,
  }) {
    return _formField(
      context: context,
      label: label,
      keyboard: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      isLast: isLast,
    );
  }
}