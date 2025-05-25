import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._();
  static Database? _db;

  AppDatabase._();

  factory AppDatabase() => _instance;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'bepbuddy.db');
    _db = await openDatabase(
      path,
      version: 3, // ← bump to 3
      onCreate: (db, version) async {
        // invoices table (always)
        await db.execute('''
          CREATE TABLE invoices (
            id TEXT PRIMARY KEY,
            vendorName TEXT NOT NULL,
            fees REAL NOT NULL,
            taxes REAL NOT NULL,
            tips REAL NOT NULL,
            total REAL NOT NULL,
            date TEXT NOT NULL,
            attachmentPath TEXT
          );
        ''');

        // reports table (fresh installs)
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
          );
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        // if upgrading from anything less than 3, make sure reports exists:
        if (oldV < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS reports (
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
            );
          ''');
        }
      },
    );
    return _db!;
  }
}