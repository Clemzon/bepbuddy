import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:share_handler_platform_interface/share_handler_platform_interface.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../../data/model/invoice.dart';
import '../../../data/repository/invoice_repository.dart';

/// Screen for creating a new invoice.
class InvoiceCreationView extends StatefulWidget {
  /// Path of a file shared or opened externally.
  final String? sharedFilePath;

  const InvoiceCreationView({super.key, this.sharedFilePath});

  @override
  State<InvoiceCreationView> createState() => _InvoiceCreationViewState();
}

class _InvoiceCreationViewState extends State<InvoiceCreationView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _vendorCtl = TextEditingController();
  final _feesCtl   = TextEditingController();
  final _taxesCtl  = TextEditingController();
  final _totalCtl  = TextEditingController();
  final _dateCtl = TextEditingController();

  // Focus nodes
  late final FocusNode _vendorFocus;
  late final FocusNode _feesFocus;
  late final FocusNode _taxesFocus;
  late final FocusNode _totalFocus;

  DateTime _pickedDate = DateTime.now();
  File? _attachment;

  final ImagePicker _cameraPicker = ImagePicker();
  final InvoiceRepository _repo = InvoiceRepository.instance;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // If launched with a shared file, attach it immediately
    if (widget.sharedFilePath != null) {
      _attachment = File(widget.sharedFilePath!);
    }

    _vendorFocus = FocusNode();
    _feesFocus   = FocusNode();
    _taxesFocus  = FocusNode();
    _totalFocus  = FocusNode();

    final handler = ShareHandlerPlatform.instance;

    // Handle cold-start shared media
    handler.getInitialSharedMedia().then((media) {
      final attachments = media?.attachments ?? [];
      if (attachments.isNotEmpty && attachments.first?.path != null) {
        setState(() => _attachment = File(attachments.first!.path));
      }
    });

    // Listen for new share events while running
    handler.sharedMediaStream.listen((media) {
      final attachments = media.attachments ?? [];
      if (attachments.isNotEmpty && attachments.first?.path != null) {
        setState(() => _attachment = File(attachments.first!.path));
      }
    });

    _dateCtl.text = DateFormat.yMd().format(_pickedDate);
  }

  @override
  void dispose() {
    _vendorCtl.dispose();
    _feesCtl.dispose();
    _taxesCtl.dispose();
    _totalCtl.dispose();
    _dateCtl.dispose();
    _vendorFocus.dispose();
    _feesFocus.dispose();
    _taxesFocus.dispose();
    _totalFocus.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picked = await _cameraPicker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _attachment = File(picked.path));
  }

  Future<void> _pickFile() async {
    try {
      // On iOS / macOS / Windows / Web: unfiltered picker so UI always appears
      // On Android: keep your original extension filter
      final List<XFile> files = (Platform.isAndroid)
          ? await openFiles(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'documents',
            extensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt'],
          )
        ],
      )
          : await openFiles();

      if (files.isEmpty) {
        debugPrint('🗂️ openFiles() returned no files');
        return;
      }

      final candidate = files.first;
      final ext = p.extension(candidate.path).toLowerCase();

      // Enforce allowed extensions on all platforms
      if (!['.jpg', '.jpeg', '.png', '.pdf', '.txt'].contains(ext)) {
        debugPrint('⚠️ Unsupported extension: $ext');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unsupported file type: $ext')),
          );
        }
        // Optionally: showDialog error to user
        return;
      }

      setState(() => _attachment = File(candidate.path));
    } on PlatformException catch (e) {
      debugPrint('❌ openFiles PlatformException: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    } catch (e) {
      debugPrint('❌ openFiles unknown error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime(2000),
      lastDate : DateTime(2100),
    );
    if (d != null) {
      setState(() => _pickedDate = d);
      _dateCtl.text = DateFormat.yMd().format(_pickedDate);
    }
  }

  Future<void> _saveInvoice() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    if (!_formKey.currentState!.validate()) {
      setState(() => _isSaving = false);
      return;
    }

    final vendor = _vendorCtl.text.trim();
    final fees   = double.tryParse(_feesCtl.text.trim())  ?? 0.0;
    final taxes  = double.tryParse(_taxesCtl.text.trim()) ?? 0.0;
    final total  = double.parse(_totalCtl.text.trim());
    final id     = const Uuid().v4();
    final attach = _attachment?.path;

    final inv = Invoice(
      id            : id,
      vendorName    : vendor,
      date          : _pickedDate,
      fees          : fees,
      taxes         : taxes,
      total         : total,
      attachmentPath: attach,
    );

    try {
      await _repo.createInvoice(inv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Invoice saved')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🚨 Save failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
        appBar: AppBar(title: const Text('New Invoice')),
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 80),
                    children: [
                    // Invoice Details
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invoice Details', style: t.titleLarge),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _vendorCtl,
                              focusNode: _vendorFocus,
                              decoration: const InputDecoration(labelText: 'Vendor Name'),
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_feesFocus),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              readOnly: true,
                              controller: _dateCtl,
                              decoration: InputDecoration(
                                labelText: 'Date',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: _pickDate,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Amounts
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amounts', style: t.titleLarge),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _feesCtl,
                              focusNode: _feesFocus,
                              decoration: const InputDecoration(labelText: 'Fees Paid'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_taxesFocus),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _taxesCtl,
                              focusNode: _taxesFocus,
                              decoration: const InputDecoration(labelText: 'Taxes Paid'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_totalFocus),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _totalCtl,
                              focusNode: _totalFocus,
                              decoration: const InputDecoration(labelText: 'Total Invoice'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _saveInvoice(),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final tVal = double.tryParse(v) ?? 0;
                                final fVal = double.tryParse(_feesCtl.text) ?? 0;
                                final xVal = double.tryParse(_taxesCtl.text) ?? 0;
                                if (tVal < fVal + xVal) return 'Total must ≥ fees + taxes';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Attachment
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Attachment', style: t.titleLarge),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Tooltip(
                                  message: 'Take photo',
                                  child: FilledButton(
                                    onPressed: _takePhoto,
                                    child: const Icon(Icons.camera_alt),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Tooltip(
                                  message: 'Attach file',
                                  child: FilledButton.tonal(
                                    onPressed: _pickFile,
                                    child: const Icon(Icons.attach_file),
                                  ),
                                ),
                              ],
                            ),
                            if (_attachment != null) ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => OpenFile.open(_attachment!.path),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    if (['.jpg', '.jpeg', '.png']
                                        .contains(p.extension(_attachment!.path).toLowerCase()))
                                      Image.file(_attachment!, height: 120)
                                    else
                                      Text(p.basename(_attachment!.path)),
                                    Tooltip(
                                      message: 'Remove attachment',
                                      child: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => setState(() => _attachment = null),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          if (_isSaving) ...[
            ModalBarrier(color: Colors.black45, dismissible: false),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Tooltip(
          message: 'Save invoice',
          child: FilledButton(
            onPressed: _isSaving ? null : _saveInvoice,
            child: _isSaving
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Invoice'),
          ),
        ),
      ),
    );
  }
  }