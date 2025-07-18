// lib/data/repository/report_repository.dart

import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../model/report.dart';

/// Interface for saving/fetching reports and their PDFs.
abstract class ReportRepository {
  /// Returns the single, Firebase‐backed implementation.
  factory ReportRepository() => _ReportRepositoryFirebase._();

  /// Inserts a new report; returns its generated ID (int).
  Future<int> insertReport(Report r);

  /// Updates an existing report by ID.
  Future<void> updateReport(int id, Report r);

  /// Deletes a report (and its PDF in Storage, if recorded).
  Future<void> deleteReport(int id);

  /// Fetches all saved reports, most recent first.
  Future<List<Report>> getAllReports();

  /// Uploads the PDF file for [r] and returns its download URL.
  Future<String> uploadReport(Report r, File pdfFile);

  /// Downloads the PDF at [r.pdfPath] (URL) into a local temp File.
  Future<File> downloadReport(Report r);
}

/// Firebase‐backed implementation of [ReportRepository].
class _ReportRepositoryFirebase implements ReportRepository {
  _ReportRepositoryFirebase._();

  // Firebase handles
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static final _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Signed-in user UID or throws.
  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'NO_USER',
        message: 'No user is currently signed in.',
      );
    }
    return uid;
  }

  /// Firestore: /users/{uid}/reports
  CollectionReference<Map<String, dynamic>> get _userReportsColl =>
      _firestore.collection('users').doc(_uid).collection('reports');

  /// Firestore doc ref for a given report id.
  DocumentReference<Map<String, dynamic>> _reportDoc(int id) =>
      _userReportsColl.doc(id.toString());

  /// Storage folder for this user’s reports: users/{uid}/reports/
  Reference get _userReportsStorageRoot =>
      _storage.ref('users/$_uid/reports');

  /// Storage file ref for a given report’s PDF.
  /// `fileName` should include extension.
  Reference _reportPdfRef(String fileName) =>
      _userReportsStorageRoot.child(fileName);

  // ---------------------------------------------------------------------------
  // INSERT
  // ---------------------------------------------------------------------------

  @override
  Future<int> insertReport(Report r) async {
    // Generate ID (keep your existing ms-since-epoch int strategy)
    final newId = DateTime.now().millisecondsSinceEpoch;

    // Convert model
    final data = r.toMap()..['id'] = newId;

    // Add timestamps — don't overwrite existing ones if provided
    data['createdAt'] ??= FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _reportDoc(newId).set(data, SetOptions(merge: true));
    return newId;
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  @override
  Future<void> updateReport(int id, Report r) async {
    final data = r.toMap()..['id'] = id;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _reportDoc(id).set(data, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  @override
  Future<void> deleteReport(int id) async {
    // Grab the doc to learn where the PDF lives (if recorded)
    final docSnap = await _reportDoc(id).get();
    String? pdfUrl;
    String? pdfStoragePath;

    if (docSnap.exists) {
      final data = docSnap.data();
      if (data != null) {
        // Your model may only track pdfPath; we try to read both.
        pdfUrl = (data['pdfPath'] ?? data['pdfUrl']) as String?;
        pdfStoragePath = data['pdfStoragePath'] as String?;
      }
    }

    // Delete Firestore doc
    await _reportDoc(id).delete();

    // Delete from Storage (best effort)
    try {
      // Prefer internal storagePath (never changes). Fallback: download URL.
      if (pdfStoragePath != null && pdfStoragePath.isNotEmpty) {
        await _storage.ref(pdfStoragePath).delete();
      } else if (pdfUrl != null && pdfUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(pdfUrl).delete();
      }
    } catch (_) {
      // Ignore if already deleted / not found
    }
  }

  // ---------------------------------------------------------------------------
  // LIST / QUERY
  // ---------------------------------------------------------------------------

  @override
  Future<List<Report>> getAllReports() async {
    final snap = await _userReportsColl
    // If you rely on createdAt server timestamp, you can order by that.
    // .orderBy('createdAt', descending: true)
        .orderBy('id', descending: true)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return Report.fromMap(data);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // UPLOAD PDF
  // ---------------------------------------------------------------------------

  /// Uploads [pdfFile] for [r] to Storage under:
  ///   users/{uid}/reports/{reportId-or-timestamp}_{originalFilename}
  ///
  /// Returns the **download URL**. You should then update the report doc
  /// (insert or update) with:
  ///  - pdfPath or pdfUrl: the download URL
  ///  - pdfStoragePath: the Storage fullPath (for reliable deletion later)
  @override
  Future<String> uploadReport(Report r, File pdfFile) async {
    final fileName = p.basename(pdfFile.path);

    // Use report ID if available; else timestamp for uniqueness.
    final idPart = r.id?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final storageFileName = '${idPart}_$fileName';

    final ref = _reportPdfRef(storageFileName);
    final task = await ref.putFile(pdfFile);
    final url = await task.ref.getDownloadURL();

    // Caller must persist this info; we return URL but also supply the storage path.
    // Example usage:
    //   final url = await repo.uploadReport(r, file);
    //   await repo.updateReport(id, r.copyWith(pdfPath: url));
    //
    // If you want automatic Firestore update here, we could do:
    // await _reportDoc(id).update({'pdfPath': url, 'pdfStoragePath': ref.fullPath});
    // but we don't know id yet if caller hasn't inserted.
    return url;
  }

  // ---------------------------------------------------------------------------
  // DOWNLOAD PDF TO LOCAL TEMP FILE
  // ---------------------------------------------------------------------------

  @override
  Future<File> downloadReport(Report r) async {
    final urlStr = r.pdfPath ?? '';
    if (urlStr.isEmpty) {
      throw ArgumentError('Report has no pdfPath to download.');
    }

    final bytes = await http.readBytes(Uri.parse(urlStr));
    final tmpDir = await getTemporaryDirectory();
    final localFile = File(p.join(tmpDir.path, '${r.id ?? 'report'}.pdf'));
    await localFile.writeAsBytes(bytes, flush: true);
    return localFile;
  }
}