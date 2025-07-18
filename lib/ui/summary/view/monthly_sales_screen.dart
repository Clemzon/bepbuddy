// lib/ui/summary/view/monthly_sales_screen.dart
//
// MonthlySalesScreen
// ------------------
// Local monthly sales report generator + viewer.
// • Lists locally generated PDF sales reports (stored in /sales_reports).
// • FAB to add a new report (bottom sheet form).
// • Long-press list item to Share / Delete.
// • Improved UI consistency w/ rest of BEPBuddy app.
// • Defensive filename parsing & validation.
// • Updated share_plus usage.
//
// NOTE: This screen currently stores reports locally only (original behavior).

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../util/pdf_generator.dart';

class MonthlySalesScreen extends StatefulWidget {
  const MonthlySalesScreen({super.key});

  @override
  State<MonthlySalesScreen> createState() => _MonthlySalesScreenState();
}

class _MonthlySalesScreenState extends State<MonthlySalesScreen> {
  late Directory _pdfDir;
  List<File> _pdfFiles = [];
  bool _dirReady = false;
  bool _loadError = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initDirectory();
  }

  Future<void> _initDirectory() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      _pdfDir = Directory('${docs.path}/sales_reports');
      if (!await _pdfDir.exists()) {
        await _pdfDir.create(recursive: true);
      }
      await _loadFiles();
      if (!mounted) return;
      setState(() {
        _dirReady = true;
        _loadError = false;
        _errorMsg = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dirReady = false;
        _loadError = true;
        _errorMsg = e.toString();
      });
      _showSnack('Storage init failed: $e', isError: true);
    }
  }

  Future<void> _loadFiles() async {
    final all = _pdfDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.pdf'))
        .toList();

    // Newest first
    all.sort(
          (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );

    setState(() {
      _pdfFiles = all;
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red.shade700 : null,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddReport() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return _AddReportSheet(
          pdfDir: _pdfDir,
        );
      },
    );

    if (created == true) {
      await _loadFiles();
      _showSnack('PDF saved!');
    }
  }

  void _showPdfActions(File file) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(context).pop();
                Share.shareXFiles(
                  [XFile(file.path)],
                  text: file.uri.pathSegments.last,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.of(context).pop();
                try {
                  await file.delete();
                  await _loadFiles();
                  _showSnack('Deleted.');
                } catch (e) {
                  _showSnack('Delete failed: $e', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = kIsWeb ? 600.0 : 480.0;

    Widget body;
    if (_loadError) {
      body = _ErrorState(
        message: 'Unable to access storage.',
        details: _errorMsg,
        onRetry: _initDirectory,
      );
    } else if (!_dirReady) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_pdfFiles.isEmpty) {
      body = _EmptyState(onCreateFirst: _openAddReport);
    } else {
      body = _ReportList(
        files: _pdfFiles,
        onLongPress: _showPdfActions,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Sales'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadFiles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: body,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddReport,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// ADD REPORT SHEET
// ============================================================================
class _AddReportSheet extends StatefulWidget {
  const _AddReportSheet({
    required this.pdfDir,
  });

  final Directory pdfDir;

  @override
  State<_AddReportSheet> createState() => _AddReportSheetState();
}

class _AddReportSheetState extends State<_AddReportSheet> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _posNameController = TextEditingController();
  final _salesTotalController = TextEditingController();
  final _ccFeesController = TextEditingController();
  final _serviceFeesController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _posType;

  bool _saving = false;

  final _numInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ];

  @override
  void dispose() {
    _posNameController.dispose();
    _salesTotalController.dispose();
    _ccFeesController.dispose();
    _serviceFeesController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat.yMd().format(picked);
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat.yMd().format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startDate == null || _endDate == null) return;

    setState(() => _saving = true);
    try {
      // Build safe filename
      final formattedStart = DateFormat('M-d').format(_startDate!);
      final formattedEnd = DateFormat('M-d').format(_endDate!);
      final salesTotal = double.parse(_salesTotalController.text);
      final safePos = _posNameController.text.replaceAll(RegExp(r'\s+'), '');
      final fileName =
          '${safePos}_$formattedStart-$formattedEnd\$${salesTotal.toStringAsFixed(2)}.pdf';
      final filePath = '${widget.pdfDir.path}/$fileName';

      await PdfGenerator.generate(
        filePath: filePath,
        startDate: _startDate!,
        endDate: _endDate!,
        posName: _posNameController.text,
        posType: _posType!,
        salesTotal: salesTotal,
        ccFees: double.parse(_ccFeesController.text),
        serviceFees: double.parse(_serviceFeesController.text),
        notes: _notesController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true); // success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Error saving PDF: $e'),
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: bottomInset + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _SheetGrabber(),
              const SizedBox(height: 16),
              Text(
                'New Sales Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                      ),
                      readOnly: true,
                      onTap: _pickStart,
                      validator: (_) => _startDate == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                      ),
                      readOnly: true,
                      onTap: _pickEnd,
                      validator: (_) => _endDate == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // POS name
              TextFormField(
                controller: _posNameController,
                decoration: const InputDecoration(
                  labelText: 'POS Location Name',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // POS type
              DropdownButtonFormField<String>(
                value: _posType,
                decoration: const InputDecoration(
                  labelText: 'POS Location Type',
                ),
                items: const [
                  'Kiosk',
                  'Register',
                  'Drink Machine',
                  'Snack Machine',
                  'Other',
                ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _posType = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Sales total
              TextFormField(
                controller: _salesTotalController,
                decoration: const InputDecoration(
                  labelText: 'Sales Total',
                  prefixText: '\$',
                ),
                inputFormatters: _numInputFormatters,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CC/EV Fees
              TextFormField(
                controller: _ccFeesController,
                decoration: const InputDecoration(
                  labelText: 'CC/EV Fees',
                  prefixText: '\$',
                ),
                inputFormatters: _numInputFormatters,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Commission / Service Fees
              TextFormField(
                controller: _serviceFeesController,
                decoration: const InputDecoration(
                  labelText: 'Commission / Service Fees',
                  prefixText: '\$',
                ),
                inputFormatters: _numInputFormatters,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: null,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Visual grabber at top of bottom sheet
class _SheetGrabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor.withOpacity(0.4);
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ============================================================================
// REPORT LIST
// ============================================================================
class _ReportList extends StatelessWidget {
  const _ReportList({
    required this.files,
    required this.onLongPress,
  });

  final List<File> files;
  final void Function(File file) onLongPress;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMd();
    final currencyFmt = NumberFormat.simpleCurrency();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = files[index];
        final stat = file.statSync();
        final modified = dateFmt.format(stat.modified);

        // Parse name metadata: safePos_start-end$total.pdf
        final name = file.uri.pathSegments.last;
        String pos = name;
        String period = '';
        String totalStr = '';

        final underParts = name.split('_');
        if (underParts.length >= 2) {
          pos = underParts[0];
          final rest = underParts.sublist(1).join('_'); // in case POS had underscores
          final dollarIdx = rest.lastIndexOf(r'$');
          if (dollarIdx >= 0) {
            period = rest.substring(0, dollarIdx);
            totalStr = rest.substring(dollarIdx + 1).replaceAll('.pdf', '');
          } else {
            period = rest.replaceAll('.pdf', '');
          }
        }

        double? total;
        if (totalStr.isNotEmpty) {
          total = double.tryParse(totalStr);
        }

        return GestureDetector(
          onLongPress: () => onLongPress(file),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(pos),
              subtitle: Text(
                'Period: $period\nModified: $modified',
                maxLines: 2,
              ),
              trailing: total != null
                  ? Text(
                currencyFmt.format(total),
                style: Theme.of(context).textTheme.titleMedium,
              )
                  : null,
              onTap: () => onLongPress(file), // show actions
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateFirst});

  final VoidCallback onCreateFirst;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 72, color: color),
          const SizedBox(height: 16),
          const Text(
            'No sales reports yet.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create your first sales report.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreateFirst,
            icon: const Icon(Icons.add),
            label: const Text('Create Report'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ERROR STATE
// ============================================================================
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
    final errColor = Colors.red.shade700;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: errColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(
              details!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: errColor),
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
      ),
    );
  }
}