// lib/ui/report/viewmodel/monthly_report_view_model.dart

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bepbuddy/data/model/report.dart';
import 'package:bepbuddy/data/repository/report_repository.dart';
import 'package:bepbuddy/util/pdf_generator.dart';
import 'package:intl/intl.dart';

class MonthlyReportViewModel extends ChangeNotifier {
  Report? lastReport;

  String standNumber = '';
  String managerName = '';
  String month = '';
  double invoicesPaid = 0;
  double helpersSalary = 0;
  double grossSales = 0;
  double vendingMachineSales = 0;
  double costOfGoodsPurchased = 0;
  double utilities = 0;
  double liabilityInsurance = 0;
  double vendingMachineIncome = 0;
  double salesTaxRate = 0.08;

  final ReportRepository _repo;
  MonthlyReportViewModel(this._repo);

  double _round2(double v) =>
      (v * 100).round().toDouble() / 100.0;

  void calculate() {
    final totalGrossSales = _round2(grossSales - vendingMachineSales);
    final netTaxableSales = _round2(totalGrossSales / (1 + salesTaxRate));
    final retailSalesTax = _round2(netTaxableSales * salesTaxRate);
    final salesTaxFromVendingMachines =
    _round2(vendingMachineSales * salesTaxRate);
    final totalSalesTaxDue = _round2(retailSalesTax + salesTaxFromVendingMachines);
    final minusTaxDiscount = _round2(
      totalSalesTaxDue < 100
          ? totalSalesTaxDue * 0.03
          : totalSalesTaxDue * 0.02,
    );
    final netAmountOfSalesTaxDue = _round2(totalSalesTaxDue - minusTaxDiscount);
    final totalOfLines =
    _round2(netAmountOfSalesTaxDue + utilities + liabilityInsurance);
    final grossCash = _round2(grossSales - (helpersSalary + invoicesPaid));
    final netEarningsForTheMonth = _round2(grossCash - totalOfLines);
    final totalNetEarnings = _round2(netEarningsForTheMonth + vendingMachineIncome);
    final percentageOfEarningsForTheMonth = _round2(
      grossSales > 0 ? (totalNetEarnings / grossSales) * 100 : 0,
    );

    lastReport = Report(
      standNumber: standNumber,
      managerName: managerName,
      month: month,
      invoicesPaid: _round2(invoicesPaid),
      helpersSalary: _round2(helpersSalary),
      grossSales: _round2(grossSales),
      vendingMachineSales: _round2(vendingMachineSales),
      costOfGoodsPurchased: _round2(costOfGoodsPurchased),
      utilities: _round2(utilities),
      liabilityInsurance: _round2(liabilityInsurance),
      vendingMachineIncome: _round2(vendingMachineIncome),
      salesTaxRate: salesTaxRate,
      grossCash: grossCash,
      totalGrossSales: totalGrossSales,
      netTaxableSales: netTaxableSales,
      retailSalesTax: retailSalesTax,
      salesTaxFromVendingMachines: salesTaxFromVendingMachines,
      totalSalesTaxDue: totalSalesTaxDue,
      minusTaxDiscount: minusTaxDiscount,
      netAmountOfSalesTaxDue: netAmountOfSalesTaxDue,
      totalOfLines: totalOfLines,
      netEarningsForTheMonth: netEarningsForTheMonth,
      totalNetEarnings: totalNetEarnings,
      percentageOfEarningsForTheMonth: percentageOfEarningsForTheMonth,
    );

    notifyListeners();
  }

  Future<void> save() async {
    final r = lastReport;
    if (r == null) return;

    final id = await _repo.insertReport(r);
    r.id = id;

    final dir = await getApplicationDocumentsDirectory();
    final pdfFile = await PdfGenerator.generateMonthlyReportPdf(dir.path, r);

    r.pdfPath = pdfFile.path;
    await _repo.updateReport(id, r);

    notifyListeners();
  }

  String asCurrency(double v) =>
      NumberFormat.simpleCurrency().format(v);
}