// lib/ui/reports/all_saved_reports_view.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bepbuddy/data/model/report.dart';
import 'package:bepbuddy/data/repository/report_repository.dart';
import 'package:bepbuddy/ui/invoices/view/packaged_invoices_view.dart';

enum _ReportAction { delete, share, submit }

class AllSavedReportsView extends StatefulWidget {
  const AllSavedReportsView({super.key});
  static const routeName = '/report/all';

  @override
  State<AllSavedReportsView> createState() => _AllSavedReportsViewState();
}

class _AllSavedReportsViewState extends State<AllSavedReportsView> {
  late Future<List<Report>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = ReportRepository().getAllReports();
  }

  Future<File?> _ensureLocalPdf(Report r) async {
    final path = r.pdfPath;
    if (path == null || path.isEmpty) return null;
    // URL?
    if (path.startsWith('http')) {
      // download into temp and return that file
      return await ReportRepository().downloadReport(r);
    } else {
      final file = File(path);
      return await file.exists() ? file : null;
    }
  }

  Future<void> _onLongPress(Report report) async {
    final choice = await showDialog<_ReportAction>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Report: ${report.month}'),
        children: [
          SimpleDialogOption(
            child: const Text('Delete Report'),
            onPressed: () => Navigator.pop(ctx, _ReportAction.delete),
          ),
          SimpleDialogOption(
            child: const Text('Share Report'),
            onPressed: () => Navigator.pop(ctx, _ReportAction.share),
          ),
          SimpleDialogOption(
            child: const Text('Submit Report'),
            onPressed: () => Navigator.pop(ctx, _ReportAction.submit),
          ),
        ],
      ),
    );

    switch (choice) {
      case _ReportAction.delete:
        await ReportRepository().deleteReport(report.id!);
        setState(_loadReports);
        break;

      case _ReportAction.share:
        final local = await _ensureLocalPdf(report);
        if (local != null) {
          await Share.shareXFiles([XFile(local.path)]);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF not available to share')),
          );
        }
        break;

      case _ReportAction.submit:
        final local = await _ensureLocalPdf(report);
        if (local != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PackagedInvoicesView(
                reportPath: local.path,
                multiSelect: true,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF not available to submit')),
          );
        }
        break;

      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Saved Reports')),
      body: FutureBuilder<List<Report>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No saved reports.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_loadReports),
            child: ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final r = reports[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(
                      r.month,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Report Date: ${r.month}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    trailing: PopupMenuButton<_ReportAction>(
                      onSelected: (action) async {
                        switch (action) {
                          case _ReportAction.delete:
                            await ReportRepository().deleteReport(r.id!);
                            setState(_loadReports);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deleted report ${r.month}')),
                            );
                            break;
                          case _ReportAction.share:
                            final local = await _ensureLocalPdf(r);
                            if (local != null) {
                              await Share.shareXFiles([XFile(local.path)]);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PDF not available to share')),
                              );
                            }
                            break;
                          case _ReportAction.submit:
                            final local = await _ensureLocalPdf(r);
                            if (local != null) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PackagedInvoicesView(
                                    reportPath: local.path,
                                    multiSelect: true,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PDF not available to submit')),
                              );
                            }
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: _ReportAction.delete, child: Text('Delete')),
                        const PopupMenuItem(value: _ReportAction.share, child: Text('Share')),
                        const PopupMenuItem(value: _ReportAction.submit, child: Text('Submit')),
                      ],
                    ),
                    onTap: () async {
                      final local = await _ensureLocalPdf(r);
                      if (local != null) {
                        await OpenFile.open(local.path);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDF not found')),
                        );
                      }
                    },
                    onLongPress: () => _onLongPress(r),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}