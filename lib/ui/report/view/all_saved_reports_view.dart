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
        report.pdfPath = null;
        await ReportRepository().updateReport(report.id!, report);
        setState(_loadReports);
        break;

      case _ReportAction.share:
        if (report.pdfPath?.isNotEmpty == true) {
          await Share.shareXFiles([XFile(report.pdfPath!)]);
        }
        break;

      case _ReportAction.submit:
        if (report.pdfPath?.isNotEmpty == true) {
          // Navigate into packaged‐invoices screen for multi‐select + submit
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PackagedInvoicesView(
                reportPath: report.pdfPath!,
                multiSelect: true,
              ),
            ),
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
            return const Center(child: Text('No saved reports.'));
          }
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              return ListTile(
                title: Text(r.month),
                subtitle: Text(r.pdfPath ?? 'No PDF'),
                onTap: () async {
                  if (r.pdfPath != null && await File(r.pdfPath!).exists()) {
                    await OpenFile.open(r.pdfPath!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF not found')),
                    );
                  }
                },
                onLongPress: () => _onLongPress(r),
              );
            },
          );
        },
      ),
    );
  }
}