// lib/ui/common/app_nav_drawer.dart
//
// Adaptive navigation used in two modes:
//
//   • Drawer mode (mobile / small width): place in Scaffold.drawer.
//   • Embedded sidebar mode (desktop / wide web): render in a fixed-width
//     column next to body content. Pass `isEmbedded: true`.
//
// API (UNCHANGED):
//   AppNavDrawer({
//     required int currentIndex,
//     required ValueChanged<int> onSelectPrimary,
//     required VoidCallback onAllReceipts,
//     required VoidCallback onPackagedInvoices,
//     ImageProvider? appIcon,
//     String? tagline,
//     bool isEmbedded = false,
//   });
//
// Primary destinations map to:
//   0 = Monthly Summary
//   1 = Monthly Invoices
//   2 = Monthly Report
//   3 = Saved Reports
//
// Secondary: All Receipts / Packaged Invoices.
//
// Styling goals:
//   - Neutral surface background (no colored header stripe).
//   - Tight, consistent spacing.
//   - Section labels for hierarchy.
//   - Highlight selected primary route with subtle tint + primary text/icon.
//

import 'package:flutter/material.dart';

class AppNavDrawer extends StatelessWidget {
  const AppNavDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelectPrimary,
    required this.onAllReceipts,
    required this.onPackagedInvoices,
    this.appIcon,
    this.tagline,
    this.isEmbedded = false,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectPrimary;
  final VoidCallback onAllReceipts;
  final VoidCallback onPackagedInvoices;
  final ImageProvider? appIcon;
  final String? tagline;
  final bool isEmbedded;

  // A comfortable max width for sidebar mode.
  static const double _kMaxSidebarWidth = 300;

  @override
  Widget build(BuildContext context) {
    Widget content = _DrawerContents(
      currentIndex: currentIndex,
      onSelectPrimary: onSelectPrimary,
      onAllReceipts: onAllReceipts,
      onPackagedInvoices: onPackagedInvoices,
      appIcon: appIcon,
      tagline: tagline,
      isEmbedded: isEmbedded,
    );

    if (isEmbedded) {
      // When embedded, constrain width & give material surface (caller wraps in Row).
      content = Material(
        elevation: 1,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxSidebarWidth),
          child: SafeArea(
            left: true,
            right: false,
            top: true,
            bottom: true,
            child: Scrollbar(
              thumbVisibility: true,
              child: content,
            ),
          ),
        ),
      );
    } else {
      // Drawer mode: SafeArea handled inside; width controlled by Drawer.
      content = SafeArea(child: content);
    }

    return content;
  }
}

class _DrawerContents extends StatelessWidget {
  const _DrawerContents({
    required this.currentIndex,
    required this.onSelectPrimary,
    required this.onAllReceipts,
    required this.onPackagedInvoices,
    required this.appIcon,
    required this.tagline,
    required this.isEmbedded,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectPrimary;
  final VoidCallback onAllReceipts;
  final VoidCallback onPackagedInvoices;
  final ImageProvider? appIcon;
  final String? tagline;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _DrawerHeaderContent(
        appIcon: appIcon,
        tagline: tagline,
        isEmbedded: isEmbedded,
      ),
      const SizedBox(height: 12),
      _SectionLabel('Primary'),
      _PrimaryTile(
        icon: Icons.bar_chart,
        label: 'Monthly Summary',
        selected: currentIndex == 0,
        onTap: () => onSelectPrimary(0),
      ),
      _PrimaryTile(
        icon: Icons.receipt_long,
        label: 'Monthly Invoices',
        selected: currentIndex == 1,
        onTap: () => onSelectPrimary(1),
      ),
      _PrimaryTile(
        icon: Icons.description,
        label: 'Monthly Report',
        selected: currentIndex == 2,
        onTap: () => onSelectPrimary(2),
      ),
      _PrimaryTile(
        icon: Icons.insert_drive_file,
        label: 'Saved Reports',
        selected: currentIndex == 3,
        onTap: () => onSelectPrimary(3),
      ),
      const SizedBox(height: 16),
      const Divider(height: 1),
      const SizedBox(height: 16),
      _SectionLabel('Other'),
      ListTile(
        leading: const Icon(Icons.list_alt),
        title: const Text('All Receipts'),
        onTap: onAllReceipts,
        dense: true,
      ),
      ListTile(
        leading: const Icon(Icons.archive),
        title: const Text('Packaged Invoices'),
        onTap: onPackagedInvoices,
        dense: true,
      ),
      const SizedBox(height: 24),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: children,
    );
  }
}

class _DrawerHeaderContent extends StatelessWidget {
  const _DrawerHeaderContent({
    required this.appIcon,
    required this.tagline,
    required this.isEmbedded,
  });

  final ImageProvider? appIcon;
  final String? tagline;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = isEmbedded ? 16.0 : 24.0;
    final size = isEmbedded ? 56.0 : 72.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, spacing, 16, spacing / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (appIcon != null)
            Image(
              image: appIcon!,
              width: size,
              height: size,
            )
          else
            Icon(
              Icons.storefront,
              size: size,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(width: 16),
          Expanded(child: _TitleAndTagline(tagline: tagline)),
        ],
      ),
    );
  }
}

class _TitleAndTagline extends StatelessWidget {
  const _TitleAndTagline({this.tagline});

  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BEPBuddy',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (tagline != null && tagline!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tagline!,
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.labelSmall;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: t?.copyWith(
          letterSpacing: 0.8,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PrimaryTile extends StatelessWidget {
  const _PrimaryTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedColor = cs.primary;
    final textStyle = selected
        ? theme.textTheme.bodyLarge?.copyWith(
      color: selectedColor,
      fontWeight: FontWeight.w600,
    )
        : theme.textTheme.bodyLarge;

    return ListTile(
      leading: Icon(icon, color: selected ? selectedColor : null),
      title: Text(label, style: textStyle),
      selected: selected,
      selectedTileColor: cs.primary.withOpacity(0.08),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}