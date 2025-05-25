import 'dart:async';
import 'package:bepbuddy/data/model/report.dart';

/// A simple in-memory stub for the web.
class ReportRepository {
  static final ReportRepository _instance = ReportRepository._();
  factory ReportRepository() => _instance;
  ReportRepository._();

  final List<Report> _store = <Report>[];
  int _nextId = 1;

  Future<int> insertReport(Report r) async {
    r.id = _nextId;
    _nextId++;
    _store.add(r);
    return r.id!;
  }

  Future<void> updateReport(int id, Report r) async {
    final i = _store.indexWhere((e) => e.id == id);
    if (i >= 0) _store[i] = r;
  }

  Future<List<Report>> getAllReports() async {
    // newest first
    return List<Report>.from(_store.reversed);
  }
}