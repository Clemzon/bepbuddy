// lib/data/repository/report_repository.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bepbuddy/data/model/report.dart';

class ReportRepository {
  static final ReportRepository _instance = ReportRepository._();
  static Database? _db;
  ReportRepository._();
  factory ReportRepository() => _instance;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'bepbuddy.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        standNumber TEXT,
        managerName TEXT,
        month TEXT,
        invoicesPaid REAL,
        helpersSalary REAL,
        grossSales REAL,
        vendingMachineSales REAL,
        costOfGoodsPurchased REAL,
        utilities REAL,
        liabilityInsurance REAL,
        vendingMachineIncome REAL,
        salesTaxRate REAL,
        grossCash REAL,
        totalGrossSales REAL,
        netTaxableSales REAL,
        retailSalesTax REAL,
        salesTaxFromVendingMachines REAL,
        totalSalesTaxDue REAL,
        minusTaxDiscount REAL,
        netAmountOfSalesTaxDue REAL,
        totalOfLines REAL,
        netEarningsForTheMonth REAL,
        totalNetEarnings REAL,
        percentageOfEarningsForTheMonth REAL,
        pdfPath TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // check whether "reports" exists
    final exists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='reports'"
    );
    if (exists.isEmpty) {
      // no table at all — just create fresh
      await _onCreate(db, newVersion);
    } else if (oldVersion < 2) {
      // upgrading from v1 to v2: add the new column
      await db.execute('ALTER TABLE reports ADD COLUMN pdfPath TEXT');
    }
  }

  Future<int> insertReport(Report r) async {
    final db = await _database;
    return db.insert('reports', r.toMap());
  }

  Future<void> updateReport(int id, Report r) async {
    final db = await _database;
    await db.update('reports', r.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Report>> getAllReports() async {
    final db = await _database;
    final rows = await db.query('reports', orderBy: 'id DESC');
    return rows.map((m) => Report.fromMap(m['id'] as int, m)).toList();
  }
}