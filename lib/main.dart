import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repository/report_repository.dart';
import 'util/settings/view/settings_manager.dart';
import 'util/settings/view/settings_view.dart';
import 'ui/summary/view/monthly_summary_view.dart';
import 'ui/invoices/view/monthly_invoices_view.dart';
import 'ui/invoices/view/invoice_creation_view.dart';
import 'ui/invoices/view/invoice_detail_view.dart';
import 'ui/invoices/view/receipt_drawer_view.dart';
import 'ui/invoices/view/packaged_invoices_view.dart';
import 'ui/report/view/monthly_report_view.dart';
import 'ui/report/view/all_saved_reports_view.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsManager.init();
  runApp(
    Provider<ReportRepository>(
      create: (_) => ReportRepository(),
      child: const BEPBuddyApp(),
    ),
  );
}

class BEPBuddyApp extends StatelessWidget {
  const BEPBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsManager.instance,
      builder: (_, __) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'BEPBuddy',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: SettingsManager.instance.themeMode,
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/invoiceCreation': (_) => const InvoiceCreationView(),
          '/invoice_creation': (_) => const InvoiceCreationView(),  // Route for external share
          '/receipts': (_) => const ReceiptDrawerView(),
          '/savedReports': (_) => const AllSavedReportsView(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/invoiceDetail' &&
              settings.arguments is String) {
            return MaterialPageRoute(
              builder: (_) => InvoiceDetailView(
                invoiceId: settings.arguments as String,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final _routes = <Widget>[
    const MonthlySummaryView(),
    const MonthlyInvoicesView(),
    const MonthlyReportView(),
    const AllSavedReportsView(),
  ];

  static const _titles = ['Summary', 'Invoices', 'Report', 'Saved Reports'];

  void _onDrawerItemTap(int idx) {
    setState(() => _selectedIndex = idx);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsView()),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('BEPBuddy',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Monthly Summary'),
            selected: _selectedIndex == 0,
            onTap: () => _onDrawerItemTap(0),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Monthly Invoices'),
            selected: _selectedIndex == 1,
            onTap: () => _onDrawerItemTap(1),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Monthly Report'),
            selected: _selectedIndex == 2,
            onTap: () => _onDrawerItemTap(2),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('All Receipts'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/receipts');
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: const Text('All Saved Reports'),
            selected: _selectedIndex == 3,
            onTap: () => _onDrawerItemTap(3),
          ),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Packaged Invoices'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const PackagedInvoicesView(
                  reportPath: '/path/to/sample/report.pdf',
                ),
              ));
            },
          ),
        ]),
      ),
      body: _routes[_selectedIndex],
    );
  }
}