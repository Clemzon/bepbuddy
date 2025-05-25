// lib/util/pdf_generator.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:bepbuddy/data/model/report.dart';

class PdfGenerator {
  /// Generates a Monthly Stand Report PDF inside [dirPath], returns the created File.
  static Future<File> generateMonthlyReportPdf(
      String dirPath, Report report) async {
    final pdf = pw.Document();

    // Single page: Title, headers, and table only
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Title
            pw.Center(
              child: pw.Text(
                'MONTHLY STAND REPORT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            // Agency line
            pw.Text(
              'South Carolina Commission for the Blind – Business Enterprise Program',
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 12),
            // Header fields
            pw.Text('Stand #: ${report.standNumber}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Manager: ${report.managerName}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Reporting Period: ${report.month}', style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),

            pw.Table.fromTextArray(
              headers: ['Item', 'Amount'],
              data: [
                ['Gross Cash', report.grossCash.toStringAsFixed(2)],
                ['Invoices Paid', report.invoicesPaid.toStringAsFixed(2)],
                ['Helper’s Salary', report.helpersSalary.toStringAsFixed(2)],
                ['Gross Sales', report.grossSales.toStringAsFixed(2)],
                ['Vending Machine Sales', report.vendingMachineSales.toStringAsFixed(2)],
                ['Total Gross Sales', report.totalGrossSales.toStringAsFixed(2)],
                ['Net Taxable Sales', report.netTaxableSales.toStringAsFixed(2)],
                ['Retail Sales Tax', report.retailSalesTax.toStringAsFixed(2)],
                ['Cost of Goods Purchased', report.costOfGoodsPurchased.toStringAsFixed(2)],
                ['Sales Tax from Vending', report.salesTaxFromVendingMachines.toStringAsFixed(2)],
                ['Total Sales Tax Due', report.totalSalesTaxDue.toStringAsFixed(2)],
                ['Minus Tax Discount', report.minusTaxDiscount.toStringAsFixed(2)],
                ['Net Amount Tax Due', report.netAmountOfSalesTaxDue.toStringAsFixed(2)],
                ['Utilities', report.utilities.toStringAsFixed(2)],
                ['Liability Insurance', report.liabilityInsurance.toStringAsFixed(2)],
                ['Total of Lines', report.totalOfLines.toStringAsFixed(2)],
                ['Net Earnings', report.netEarningsForTheMonth.toStringAsFixed(2)],
                ['Vending Machine Income', report.vendingMachineIncome.toStringAsFixed(2)],
                ['Total Net Earnings', report.totalNetEarnings.toStringAsFixed(2)],
                ['% Earnings', '${report.percentageOfEarningsForTheMonth.toStringAsFixed(2)}%'],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              border: null,
            ),
          ],
        ),
      ),
    );

    final file = File('$dirPath/MSR-${report.month}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}