// lib/ui/report/view/monthly_report_view.dart
//
// MonthlyReportView
// -----------------
// Guided form to create a Business Enterprise Program monthly stand report.
// Sections:
//   • Manager’s Details
//   • Month
//   • Financial Details
//   • Sales Tax Rate
// Actions:
//   • Calculate (computes derived monthly report values in the ViewModel)
//   • Save (enabled after successful calculation; persists via ReportRepository)
//
// NOTE: This file is UI-focused. It relies on MonthlyReportViewModel for all
// state, calculations, validation logic, persistence, currency formatting, etc.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bepbuddy/ui/report/viewmodel/monthly_report_view_model.dart';

class MonthlyReportView extends StatelessWidget {
  const MonthlyReportView({super.key});
  static const routeName = '/report/new';

  @override
  Widget build(BuildContext context) {
    // Inject the ViewModel (expects a ReportRepository provided higher up).
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New Monthly Report')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Manager’s Details ────────────────────────────────────────
                _SectionCard(
                  icon: Icons.badge,
                  title: 'Manager’s Details',
                  children: [
                    _formField(
                      context: context,
                      label: 'Stand Number',
                      initial: vm.standNumber,
                      keyboard: TextInputType.number,
                      autofillHint: AutofillHints.postalCode, // harmless filler
                      onChanged: (v) => vm.standNumber = v,
                    ),
                    _formField(
                      context: context,
                      label: 'Manager’s Name',
                      initial: vm.managerName,
                      autofillHint: AutofillHints.name,
                      onChanged: (v) => vm.managerName = v,
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Month ───────────────────────────────────────────────────
                _SectionCard(
                  icon: Icons.calendar_month,
                  title: 'Month',
                  children: [
                    DropdownButtonFormField<String>(
                      key: const ValueKey('monthDropdown'),
                      value: vm.month.isEmpty ? null : vm.month,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Select Month',
                      ),
                      items: const [
                        'January',
                        'February',
                        'March',
                        'April',
                        'May',
                        'June',
                        'July',
                        'August',
                        'September',
                        'October',
                        'November',
                        'December'
                      ].map(
                            (m) => DropdownMenuItem<String>(
                          value: m,
                          child: Text(m),
                        ),
                      ).toList(),
                      onChanged: (m) => vm.month = m ?? '',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Used for labeling & reporting.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Financial Details ───────────────────────────────────────
                _SectionCard(
                  icon: Icons.attach_money,
                  title: 'Financial Details',
                  children: [
                    _numField(
                      context: context,
                      label: 'Invoices Paid',
                      onChanged: (v) =>
                      vm.invoicesPaid = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Helper’s Salary',
                      onChanged: (v) =>
                      vm.helpersSalary = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Gross Sales',
                      onChanged: (v) =>
                      vm.grossSales = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Vending Machine Sales',
                      onChanged: (v) =>
                      vm.vendingMachineSales = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Cost of Goods Purchased',
                      onChanged: (v) =>
                      vm.costOfGoodsPurchased = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Utilities',
                      onChanged: (v) =>
                      vm.utilities = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Liability Insurance',
                      onChanged: (v) =>
                      vm.liabilityInsurance = double.tryParse(v) ?? 0,
                    ),
                    _numField(
                      context: context,
                      label: 'Vending Machine Income',
                      onChanged: (v) =>
                      vm.vendingMachineIncome = double.tryParse(v) ?? 0,
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Sales Tax Rate ──────────────────────────────────────────
                _SectionCard(
                  icon: Icons.percent,
                  title: 'Sales Tax Rate (%)',
                  children: [
                    _formField(
                      context: context,
                      label: 'e.g. 8.0 for 8%',
                      initial: vm.salesTaxRate == 0
                          ? ''
                          : (vm.salesTaxRate * 100).toString(),
                      keyboard:
                      const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) =>
                      vm.salesTaxRate = (double.tryParse(v) ?? 0) / 100,
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Actions ─────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: vm.isSaving ? null : vm.calculate,
                        child: const Text('Calculate'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: hasResult && !vm.isSaving
                            ? () async {
                          await vm.save();
                          if (!context.mounted) return;
                          if (vm.error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                Text('Report saved successfully!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(vm.error!)),
                            );
                          }
                        }
                            : null,
                        child: vm.isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Results ─────────────────────────────────────────────────
                if (hasResult)
                  _SectionCard(
                    icon: Icons.summarize,
                    title: 'Calculated Results',
                    children: _buildResults(vm, textTheme),
                  ),

                if (vm.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    vm.error!,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Results builder
  // --------------------------------------------------------------------------
  List<Widget> _buildResults(
      MonthlyReportViewModel vm,
      TextTheme t,
      ) {
    final r = vm.lastReport!;
    // Present in a two-column-ish layout using RichText rows
    Widget line(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: t.titleSmall,
              textAlign: TextAlign.right,
            ),
          ],
        ),
      );
    }

    return [
      line('Gross Cash:', vm.asCurrency(r.grossCash)),
      line('Total Gross Sales:', vm.asCurrency(r.totalGrossSales)),
      line('Net Taxable Sales:', vm.asCurrency(r.netTaxableSales)),
      line('Retail Sales Tax:', vm.asCurrency(r.retailSalesTax)),
      line(
        'Sales Tax from Vending:',
        vm.asCurrency(r.salesTaxFromVendingMachines),
      ),
      line('Total Sales Tax Due:', vm.asCurrency(r.totalSalesTaxDue)),
      line('Minus Tax Discount:', vm.asCurrency(r.minusTaxDiscount)),
      line(
        'Net Amount of Sales Tax Due:',
        vm.asCurrency(r.netAmountOfSalesTaxDue),
      ),
      line('Total of Lines:', vm.asCurrency(r.totalOfLines)),
      line(
        'Net Earnings for the Month:',
        vm.asCurrency(r.netEarningsForTheMonth),
      ),
      line('Total Net Earnings:', vm.asCurrency(r.totalNetEarnings)),
      line(
        'Earnings %:',
        '${r.percentageOfEarningsForTheMonth.toStringAsFixed(2)}%',
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // Field helpers
  // --------------------------------------------------------------------------
  Widget _formField({
    required BuildContext context,
    required String label,
    String initial = '',
    required ValueChanged<String> onChanged,
    TextInputType keyboard = TextInputType.text,
    bool isLast = false,
    String? autofillHint,
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
        autofillHints: autofillHint == null ? null : [autofillHint],
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

// ============================================================================
// Generic Section Card w/ Icon + Title
// ============================================================================
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(title, style: t.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}