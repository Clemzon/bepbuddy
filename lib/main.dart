// lib/main.dart
//
// App bootstrap + global routing + adaptive navigation.
//
// Responsive navigation behavior:
//  • < _kSidebarBreakpoint px  => hamburger + modal drawer (mobile-style).
//  • >= _kSidebarBreakpoint px => persistent sidebar using AppNavDrawer; no hamburger.
//
// The AppNavDrawer is reused for both modes. When embedded (sidebar), its scrollable
// content expands to full height and no colored header will clash with background.
//

import 'dart:async';

import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

import 'data/repository/report_repository.dart';
import 'util/settings/view/settings_manager.dart';
import 'util/settings/view/settings_view.dart';
import 'ui/summary/view/monthly_summary_view.dart';
import 'ui/invoices/view/monthly_invoices_view.dart';
import 'ui/invoices/view/invoice_detail_view.dart';
import 'ui/invoices/view/invoice_creation_view.dart';
import 'ui/invoices/view/packaged_invoices_view.dart';
import 'ui/report/view/monthly_report_view.dart';
import 'ui/report/view/all_saved_reports_view.dart';

// ★ NEW: modularized drawer widget
import 'ui/common/app_nav_drawer.dart';

/// Breakpoint (logical px width) at which we switch to always-open sidebar.
/// Tune as needed.
const double _kSidebarBreakpoint = 700;

/// Routes user based on FirebaseAuth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();

/// Lists folders/files under 'reports/' in Cloud Storage. Debug only.
Future<void> debugListStorage() async {
  final storage = FirebaseStorage.instance;
  try {
    final listResult = await storage.ref('reports').listAll();

    debugPrint('📂 FOLDERS under reports/:');
    for (final prefix in listResult.prefixes) {
      debugPrint('    • ${prefix.fullPath}');
    }

    debugPrint('📄 FILES under reports/:');
    for (final item in listResult.items) {
      debugPrint('    • ${item.fullPath}');
    }

    if (listResult.prefixes.isEmpty && listResult.items.isEmpty) {
      debugPrint('⚠️ No entries found under reports/.');
    }
  } catch (e, st) {
    debugPrint('❌ Error listing Storage: $e');
    debugPrint(st.toString());
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Settings
  await SettingsManager.init();

  // 2) Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    debugPrint('✅ Firebase initialized for project '
        '${Firebase.app().options.projectId}');
  }

  // 3) Debug Storage listing (DISABLED for now; causes CORS spam on web)
  // if (kDebugMode) unawaited(debugListStorage());

  // 4) Launch the app
  runApp(
    MultiProvider(
      providers: [
        Provider<ReportRepository>(create: (_) => ReportRepository()),
        Provider<FirebaseStorage>(create: (_) => FirebaseStorage.instance),
      ],
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

        // Start here (fixes blank screen / route assertion)
        home: const AuthGate(),

        routes: {
          // '/': (_) => const AuthGate(), // <-- MUST NOT define '/' when using home:
          '/invoiceCreation': (_) => const InvoiceCreationView(),
          '/invoice_creation': (_) => const InvoiceCreationView(),
          '/invoiceDetail': (ctx) {
            final id = ModalRoute.of(ctx)!.settings.arguments as String;
            return InvoiceDetailView(invoiceId: id);
          },
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/invoiceCreation') {
            return MaterialPageRoute(
              builder: (_) => const InvoiceCreationView(),
            );
          }
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

/// The “shell” screen that hosts the app-wide navigation and page content.
///
/// NOTE: Primary tab content (_routes) is kept local so state is preserved
/// when switching tabs. Secondary destinations (Receipts, Packaged Invoices)
/// push onto the Navigator stack.
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final _routes = <Widget>[
    const MonthlySummaryView(),
    const MonthlyInvoicesView(),
    const MonthlyReportView(),
    const AllSavedReportsView(),
  ];

  static const _titles = ['Summary', 'Invoices', 'Report', 'Saved Reports'];

  // --- Navigation handlers ---
  void _handlePrimaryNav(int idx) {
    setState(() => _selectedIndex = idx);
    // If we are in slide-out drawer mode (mobile), close drawer.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _openReceipts() {
    // close drawer if open
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    Navigator.pushNamed(context, '/receipts');
  }

  void _openPackagedInvoices() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PackagedInvoicesView(
          reportPath: '/path/to/sample/report.pdf',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = _titles[_selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showSidebar = constraints.maxWidth >= _kSidebarBreakpoint;

        // When showing sidebar, we DO NOT provide a Scaffold.drawer or AppBar leading hamburger.
        // Instead we render the drawer content permanently in a Row.
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: showSidebar
                ? null // ★ no hamburger in sidebar mode
                : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsView()),
                ),
              ),
            ],
          ),

          // Drawer only used in narrow layout.
          drawer: showSidebar
              ? null
              : AppNavDrawer(
            currentIndex: _selectedIndex,
            onSelectPrimary: _handlePrimaryNav,
            onAllReceipts: _openReceipts,
            onPackagedInvoices: _openPackagedInvoices,
            // Provide your actual app icon asset (ensure declared in pubspec).
            appIcon: const AssetImage('assets/icon/app_icon.png'),
            tagline:
            'Track invoices & reports', // Short tagline in mobile drawer
          ),

          body: showSidebar
              ? Row(
            children: [
              // ★ Persistent sidebar nav (width tuned; scrolls if needed)
              ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 280),
                child: Material( // ensures proper surface + theme
                  elevation: 1,
                  color: Theme.of(context).colorScheme.surface,
                  child: SafeArea(
                    child: AppNavDrawer(
                      currentIndex: _selectedIndex,
                      onSelectPrimary: _handlePrimaryNav,
                      onAllReceipts: _openReceipts,
                      onPackagedInvoices: _openPackagedInvoices,
                      appIcon:
                      const AssetImage('assets/icon/app_icon.png'),
                      tagline:
                      'Track invoices & reports', // we can later extend copy here
                      isEmbedded: true, // ★ tells drawer to render flat
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              // Page content
              Expanded(child: _routes[_selectedIndex]),
            ],
          )
              : _routes[_selectedIndex],
        );
      },
    );
  }
}