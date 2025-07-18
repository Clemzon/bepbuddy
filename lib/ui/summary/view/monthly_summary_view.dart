// lib/ui/summary/view/monthly_summary_view.dart
//
// MonthlySummaryView: 3-tab PageView (Summary / Sales / More)
// Polished for consistent app-wide UI:
//  • Responsive width constraint
//  • BottomNavigationBar sync w/ PageView
//  • Summary page: month header + refresh + totals cards
//  • Currency formatting via intl
//  • Error + empty states
//  • Pull-to-refresh support
//
// NOTE: Adjust the relative import paths below if your folder structure differs.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repository/invoice_repository.dart';
import 'monthly_sales_screen.dart';

class MonthlySummaryView extends StatefulWidget {
  const MonthlySummaryView({super.key});

  @override
  State<MonthlySummaryView> createState() => _MonthlySummaryViewState();
}

class _MonthlySummaryViewState extends State<MonthlySummaryView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // NOTE: _pages is no longer const because _SummaryPage now has a const constructor
  // but contains state; we want fresh build if needed.
  late final List<Widget> _pages = <Widget>[
    const _SummaryPage(),
    const MonthlySalesScreen(),
    const _PlaceholderScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int idx) {
    setState(() => _currentIndex = idx);
    _pageController.animateToPage(
      idx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // We let each child screen manage its own Scaffold-like layout,
    // so this wrapper Scaffold just holds the bottom nav + PageView body.
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Summary'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SUMMARY PAGE
// -----------------------------------------------------------------------------
class _SummaryPage extends StatefulWidget {
  const _SummaryPage();

  @override
  State<_SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<_SummaryPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  int _count = 0;
  double _fees = 0;
  double _taxes = 0;
  double _total = 0;

  late DateTime _periodStart;
  late DateTime _periodEnd;
  late DateFormat _monthLabelFmt;
  late NumberFormat _currencyFmt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodStart = DateTime(now.year, now.month, 1);
    // Use DateTime(year, month+1, 0) trick to get last day; safe across year wrap
    _periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    _monthLabelFmt = DateFormat.yMMMM(); // e.g., "July 2025"
    _currencyFmt = NumberFormat.simpleCurrency(); // based on locale
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final invoices = await InvoiceRepository.instance.getInvoicesBetween(
        _periodStart,
        _periodEnd,
      );

      setState(() {
        _count = invoices.length;
        _fees = invoices.fold<double>(0, (sum, inv) => sum + inv.fees);
        _taxes = invoices.fold<double>(0, (sum, inv) => sum + inv.taxes);
        _total = invoices.fold<double>(0, (sum, inv) => sum + inv.total);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Pull-to-refresh uses the same loader
  Future<void> _onRefresh() => _loadSummary();

  @override
  Widget build(BuildContext context) {
    final maxWidth = kIsWeb ? 600.0 : 480.0;

    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_hasError) {
      body = _ErrorState(
        message: 'Could not load monthly summary.',
        details: _errorMessage,
        onRetry: _loadSummary,
      );
    } else {
      body = _SummaryContent(
        monthLabel: _monthLabelFmt.format(_periodStart),
        invoiceCount: _count,
        fees: _fees,
        taxes: _taxes,
        total: _total,
        currencyFmt: _currencyFmt,
        onRefreshTap: _loadSummary,
      );
    }

    // Wrap in RefreshIndicator for mobile pull-to-refresh behavior
    // For web, the refresh icon in header is the primary refresh affordance.
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              // Ensure RefreshIndicator can trigger: need alwaysScrollable
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SUMMARY CONTENT WIDGET
// -----------------------------------------------------------------------------
class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    required this.monthLabel,
    required this.invoiceCount,
    required this.fees,
    required this.taxes,
    required this.total,
    required this.currencyFmt,
    required this.onRefreshTap,
  });

  final String monthLabel;
  final int invoiceCount;
  final double fees;
  final double taxes;
  final double total;
  final NumberFormat currencyFmt;
  final VoidCallback onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Row(
          children: [
            Expanded(
              child: Text(
                monthLabel,
                style: textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefreshTap,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Invoices this month: $invoiceCount',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 24),

        // Summary Cards
        _SummaryCard(
          label: 'Total Fees',
          value: currencyFmt.format(fees),
          icon: Icons.request_quote,
          color: colorScheme.tertiary,
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: 'Total Taxes',
          value: currencyFmt.format(taxes),
          icon: Icons.receipt_long,
          color: colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: 'Grand Total',
          value: currencyFmt.format(total),
          icon: Icons.summarize,
          color: colorScheme.primary,
          emphasize: true,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SUMMARY CARD
// -----------------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final cardColor = emphasize
        ? color.withOpacity(0.15)
        : Theme.of(context).cardColor;

    final borderColor = color.withOpacity(0.4);

    return Card(
      elevation: emphasize ? 2 : 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: textTheme.titleMedium,
              ),
            ),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: emphasize ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ERROR STATE
// -----------------------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    this.details,
    required this.onRetry,
  });

  final String message;
  final String? details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final errColor = Colors.red.shade700;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: errColor),
        const SizedBox(height: 16),
        Text(message, style: textTheme.titleMedium, textAlign: TextAlign.center),
        if (details != null) ...[
          const SizedBox(height: 8),
          Text(
            details!,
            style: textTheme.bodySmall?.copyWith(color: errColor),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// PLACEHOLDER SCREEN FOR THIRD TAB
// -----------------------------------------------------------------------------
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('More coming soon...'),
    );
  }
}