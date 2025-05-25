// lib/data/repository/invoice_repository.dart

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../model/invoice.dart';

class InvoiceRepository {
  static final instance = InvoiceRepository._();
  InvoiceRepository._();

  /// The root "invoices" directory under the app's documents folder.
  Future<Directory> _invoicesRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'invoices'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Creates an invoice by writing:
  /// 1) A human-readable .txt
  /// 2) A companion .json for lookup
  /// 3) Copying the attachment (if any)
  Future<void> createInvoice(Invoice inv) async {
    final root = await _invoicesRoot();
    final vendorDir = Directory(
      p.join(root.path, inv.vendorName.toLowerCase()),
    );
    if (!await vendorDir.exists()) {
      await vendorDir.create(recursive: true);
    }

    // 1) Write human-readable .txt
    final dateFmt = DateFormat.yMd(); // e.g. 5/27/2025
    final buffer = StringBuffer()
      ..writeln('Invoice ID: ${inv.id}')
      ..writeln('Vendor Name: ${inv.vendorName}')
      ..writeln('Date: ${dateFmt.format(inv.date)}')
      ..writeln('Fees Paid: \$${inv.fees.toStringAsFixed(2)}')
      ..writeln('Taxes Paid: \$${inv.taxes.toStringAsFixed(2)}')
      ..writeln('Total Invoice: \$${inv.total.toStringAsFixed(2)}');

    final txtFile = File(p.join(vendorDir.path, '${inv.id}.txt'));
    await txtFile.writeAsString(buffer.toString());

    // 2) ALSO write companion .json for reads
    final jsonFile = File(p.join(vendorDir.path, '${inv.id}.json'));
    await jsonFile.writeAsString(jsonEncode(inv.toJson()));

    // 3) Copy attachment (if present)
    if (inv.attachmentPath != null) {
      final src = File(inv.attachmentPath!);
      if (await src.exists()) {
        await src.copy(
          p.join(vendorDir.path, p.basename(src.path)),
        );
      }
    }
  }

  /// Returns all invoices whose date is between [start] and [end].
  /// Reads from the companion .json files.
  Future<List<Invoice>> getInvoicesBetween(
      DateTime start, DateTime end) async {
    final root = await _invoicesRoot();
    final out = <Invoice>[];

    await for (var vendor in root.list()) {
      if (vendor is! Directory) continue;
      await for (var file in vendor.list()) {
        if (file is File && p.extension(file.path).toLowerCase() == '.json') {
          try {
            final m =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
            final inv = Invoice.fromJson(m);
            if (!inv.date.isBefore(start) && !inv.date.isAfter(end)) {
              out.add(inv);
            }
          } catch (_) {
            // ignore parse errors
          }
        }
      }
    }

    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// Retrieves a single Invoice by its ID via the .json file.
  Future<Invoice?> getInvoiceById(String id) async {
    final root = await _invoicesRoot();

    await for (var vendor in root.list()) {
      if (vendor is! Directory) continue;
      final jsonFile = File(p.join(vendor.path, '$id.json'));
      if (await jsonFile.exists()) {
        final m =
        jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
        return Invoice.fromJson(m);
      }
    }
    return null;
  }

  /// Deletes both the .txt and .json for an invoice.
  Future<void> deleteInvoice(String id) async {
    final root = await _invoicesRoot();

    await for (var vendor in root.list()) {
      if (vendor is! Directory) continue;
      final txtFile = File(p.join(vendor.path, '$id.txt'));
      if (await txtFile.exists()) await txtFile.delete();

      final jsonFile = File(p.join(vendor.path, '$id.json'));
      if (await jsonFile.exists()) await jsonFile.delete();
      return;
    }
  }

  /// Packages the .txt plus attachments into a ZIP.
  /// Skips any .json files so they won’t appear in the ZIP.
  Future<String> packageInvoices(List<String> ids) async {
    final root = await _invoicesRoot();
    final pkgDir = Directory(p.join(root.path, 'packages'));
    if (!await pkgDir.exists()) {
      await pkgDir.create(recursive: true);
    }

    final now = DateTime.now();
    final label = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final name = "$label - (${ids.length} Invoices).zip";
    final zipPath = p.join(pkgDir.path, name);

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    for (var id in ids) {
      // Find the folder and txt file
      File? txtFile;
      Directory? vendorDir;
      await for (var dir in root.list()) {
        if (dir is Directory) {
          final candidate = File(p.join(dir.path, '$id.txt'));
          if (await candidate.exists()) {
            txtFile = candidate;
            vendorDir = dir;
            break;
          }
        }
      }
      if (txtFile == null || vendorDir == null) continue;

      encoder.addFile(txtFile);

      // Add attachments but skip any .json
      await for (var file in vendorDir.list()) {
        if (file is File) {
          final base = p.basename(file.path);
          final ext = p.extension(base).toLowerCase();
          if (base == '$id.txt' || ext == '.json') continue;
          encoder.addFile(file);
        }
      }
    }

    encoder.close();
    return zipPath;
  }

  /// Matches your existing call (takes a reportPath argument, which is unused).
  Future<List<File>> getInvoicePackages(String reportPath) async {
    final root = await _invoicesRoot();
    final pkgDir = Directory(p.join(root.path, 'packages'));
    if (!await pkgDir.exists()) return [];
    return pkgDir
        .listSync()
        .whereType<File>()
        .where((f) => p.extension(f.path).toLowerCase() == '.zip')
        .toList();
  }
}