// lib/data/repository/invoice_repository.dart

import 'dart:io' show File, Directory; // NOTE: packaging helpers are mobile/desktop only.
import 'package:archive/archive_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../model/invoice.dart';

/// Repository for CRUD + packaging of invoices, now **scoped per signed-in user**.
/// All Firestore reads/writes occur under `/users/{uid}/invoices/...`.
/// All Storage uploads/downloads occur under `users/{uid}/invoices/...`.
class InvoiceRepository {
  static final instance = InvoiceRepository._();
  InvoiceRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Current signed-in FirebaseAuth user UID. Throws if not signed in.
  String get _uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      throw StateError('InvoiceRepository: no signed-in user.');
    }
    return u.uid;
  }

  /// Firestore path: /users/{uid}/invoices
  CollectionReference<Map<String, dynamic>> get _invoicesCol =>
      _firestore.collection('users').doc(_uid).collection('invoices');

  /// Firestore doc ref for a given invoice ID.
  DocumentReference<Map<String, dynamic>> _invoiceDoc(String invoiceId) =>
      _invoicesCol.doc(invoiceId);

  /// Storage root for this user: users/{uid}
  Reference get _userStorageRoot => _storage.ref('users/$_uid');

  /// Storage ref for invoice attachment folder: users/{uid}/invoices/{invoiceId}
  Reference _invoiceStorageFolder(String invoiceId) =>
      _userStorageRoot.child('invoices/$invoiceId');

  /// Storage ref for packaged zips: users/{uid}/packages
  Reference get _packagesStorageFolder =>
      _userStorageRoot.child('packages');

  /// Temporary local directory for downloads/zips (mobile/desktop only).
  Future<Directory> _getTempRoot() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory(p.join(tmp.path, 'invoice_temp'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // ---------------------------------------------------------------------------
  // CREATE / UPDATE
  // ---------------------------------------------------------------------------

  /// Creates (or overwrites) an invoice doc under `/users/{uid}/invoices/{inv.id}`.
  /// If [inv.attachmentPath] points to a local file, uploads it to Storage at
  /// `users/{uid}/invoices/{inv.id}/attachment{ext}` and stores that path in Firestore.
  Future<void> createInvoice(Invoice inv) async {
    String? storageAttachmentPath;

    // Upload attachment if present and local file exists (mobile/desktop only).
    if (inv.attachmentPath != null) {
      final localFile = File(inv.attachmentPath!);
      if (await localFile.exists()) {
        final ext = p.extension(localFile.path).toLowerCase();
        final destRef = _invoiceStorageFolder(inv.id).child('attachment$ext');
        await destRef.putFile(localFile);
        // Save relative path; you can also save full gs:// URL if preferred.
        storageAttachmentPath = destRef.fullPath; // "users/{uid}/invoices/{id}/attachment.pdf"
      }
    }

    final docData = <String, dynamic>{
      'vendorName': inv.vendorName,
      'date': Timestamp.fromDate(inv.date),
      'fees': inv.fees,
      'taxes': inv.taxes,
      'total': inv.total,
      'archived': inv.archived,
      if (storageAttachmentPath != null)
        'storageAttachmentPath': storageAttachmentPath,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(), // Firestore will overwrite on update; you could conditionalize
    };

    await _invoiceDoc(inv.id).set(docData, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // READ (RANGE)
  // ---------------------------------------------------------------------------

  /// Query all invoices between [start] and [end] (inclusive) for the current user.
  Future<List<Invoice>> getInvoicesBetween(DateTime start, DateTime end) async {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);

    final querySnap = await _invoicesCol
        .where('date', isGreaterThanOrEqualTo: startTs)
        .where('date', isLessThanOrEqualTo: endTs)
        .get();

    final invoices = <Invoice>[];
    for (final doc in querySnap.docs) {
      invoices.add(_invoiceFromDoc(doc));
    }

    invoices.sort((a, b) => a.date.compareTo(b.date));
    return invoices;
  }

  // ---------------------------------------------------------------------------
  // READ (BY ID)
  // ---------------------------------------------------------------------------

  Future<Invoice?> getInvoiceById(String id) async {
    final snapshot = await _invoiceDoc(id).get();
    if (!snapshot.exists) return null;
    return _invoiceFromSnapshot(snapshot);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  /// Deletes invoice doc + all attachments from Storage.
  Future<void> deleteInvoice(String id) async {
    // Delete Firestore doc
    await _invoiceDoc(id).delete();

    // Delete all Storage files under users/{uid}/invoices/{id}
    final folderRef = _invoiceStorageFolder(id);
    try {
      final listResult = await folderRef.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (_) {
      // ignore missing
    }
  }

  // ---------------------------------------------------------------------------
  // PACKAGING (LOCAL ZIP + UPLOAD TO STORAGE)
  // NOTE: Not web-safe because it depends on local file IO; gate in UI if needed.
  // ---------------------------------------------------------------------------

  Future<String> packageInvoices(List<String> ids) async {
    final tempRoot = await _getTempRoot();
    final pkgDir = Directory(p.join(tempRoot.path, 'packages'));
    if (!await pkgDir.exists()) {
      await pkgDir.create(recursive: true);
    }

    final now = DateTime.now();
    final label = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final zipName = "$label - (${ids.length} Invoices).zip";
    final zipPath = p.join(pkgDir.path, zipName);

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    // Add each invoice summary + attachment
    for (final id in ids) {
      final invoice = await getInvoiceById(id);
      if (invoice == null) continue;

      // Summary txt
      final dateFmt = DateFormat.yMd();
      final buffer = StringBuffer()
        ..writeln('Invoice ID: ${invoice.id}')
        ..writeln('Vendor Name: ${invoice.vendorName}')
        ..writeln('Date: ${dateFmt.format(invoice.date)}')
        ..writeln('Fees Paid: \$${invoice.fees.toStringAsFixed(2)}')
        ..writeln('Taxes Paid: \$${invoice.taxes.toStringAsFixed(2)}')
        ..writeln('Total Invoice: \$${invoice.total.toStringAsFixed(2)}');

      final summaryFile = File(p.join(pkgDir.path, '${invoice.id}.txt'));
      await summaryFile.writeAsString(buffer.toString());
      encoder.addFile(summaryFile);

      // Attachment (download from Storage)
      if (invoice.attachmentPath != null) {
        final ref = _storage.ref(invoice.attachmentPath!);
        try {
          final bytes = await ref.getData();
          if (bytes != null) {
            final ext = p.extension(ref.name).toLowerCase();
            final localDownloadPath = p.join(pkgDir.path, '${invoice.id}$ext');
            final localFile = File(localDownloadPath);
            await localFile.writeAsBytes(bytes);
            encoder.addFile(localFile);
          }
        } catch (_) {
          // ignore missing attachment
        }
      }
    }

    // Close zip
    encoder.close();

    // Upload to Storage: users/{uid}/packages/{label}.zip
    final zipFile = File(zipPath);
    final storagePath = 'users/$_uid/packages/$label.zip';
    final zipRef = _storage.ref(storagePath);
    await zipRef.putFile(zipFile);

    return zipPath;
  }

  // ---------------------------------------------------------------------------
  // LOCAL PACKAGES (unchanged)
  // ---------------------------------------------------------------------------

  Future<List<File>> getInvoicePackages(String reportPath) async {
    final tempRoot = await _getTempRoot();
    final pkgDir = Directory(p.join(tempRoot.path, 'packages'));
    if (!await pkgDir.exists()) return [];
    return pkgDir
        .listSync()
        .whereType<File>()
        .where((f) => p.extension(f.path).toLowerCase() == '.zip')
        .toList();
  }

  // ---------------------------------------------------------------------------
  // REMOTE PACKAGES (FROM STORAGE)
  // ---------------------------------------------------------------------------

  Future<List<Reference>> getInvoicePackagesFromFirebase() async {
    final result = await _packagesStorageFolder.listAll();
    return result.items;
  }

  Future<List<String>> getAllPackageDownloadUrls() async {
    final refs = await getInvoicePackagesFromFirebase();
    final urls = <String>[];
    for (final r in refs) {
      urls.add(await r.getDownloadURL());
    }
    return urls;
  }

  // ---------------------------------------------------------------------------
  // Internal doc-to-model conversion
  // ---------------------------------------------------------------------------

  Invoice _invoiceFromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return _invoiceFromDoc(snapshot);
  }

  Invoice _invoiceFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final vendorName = data['vendorName'] as String;
    final date = (data['date'] as Timestamp).toDate();
    final fees = (data['fees'] as num).toDouble();
    final taxes = (data['taxes'] as num).toDouble();
    final total = (data['total'] as num).toDouble();
    final archived = data['archived'] as bool? ?? false;
    final storageAttachmentPath = data['storageAttachmentPath'] as String?;

    return Invoice(
      id: doc.id,
      vendorName: vendorName,
      date: date,
      fees: fees,
      taxes: taxes,
      total: total,
      attachmentPath: storageAttachmentPath,
      archived: archived,
    );
  }
}