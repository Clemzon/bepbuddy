// lib/util/pdf_generator.dart

import 'dart:io';
import 'package:flutter/foundation.dart';              // ← for debugPrint
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


import 'package:bepbuddy/data/model/report.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static final _currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  /// Generates a Monthly Stand Report PDF inside [dirPath], returns the created File.
  static Future<File> generateMonthlyReportPdf(
      String dirPath, Report report) async {
    try {
      final doc = pw.Document();

      // 1) load a Unicode-capable font
      final ttf = await PdfGoogleFonts.openSansRegular();
      // (Or load your own TTF via rootBundle if preferred)

      // 2) add a MultiPage instead of a single Page
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(36),
          footer: (ctx) {
            final timestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Generated on $timestamp',
                    style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          },
          build: (ctx) {
            return <pw.Widget>[
              // ——— Title —
              pw.Center(
                child: pw.Text(
                  'MONTHLY STAND REPORT',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'South Carolina Commission for the Blind – Business Enterprise Program',
                style: pw.TextStyle(font: ttf, fontSize: 11, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 12),

              // ——— Manager + Period Info (vertical) —
              pw.Text(
                'Stand #: ${report.standNumber}',
                style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Manager: ${report.managerName}',
                style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Reporting Period: ${report.month}',
                style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),

              // ——— Divider before data list ———
              pw.Divider(color: PdfColors.grey700),
              pw.SizedBox(height: 8),

              // ——— Data List ———
              // Header row
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Item',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'Amount',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Divider(color: PdfColors.blue800),
              pw.SizedBox(height: 8),

              // Data rows
              pw.Column(
                children: [
                  for (final entry in [
                    ['Gross Cash', _currencyFormatter.format(report.grossCash)],
                    ['Invoices Paid', _currencyFormatter.format(report.invoicesPaid)],
                    ['Helper’s Salary', _currencyFormatter.format(report.helpersSalary)],
                    ['Gross Sales', _currencyFormatter.format(report.grossSales)],
                    ['Vending Machine Sales', _currencyFormatter.format(report.vendingMachineSales)],
                    ['Total Gross Sales', _currencyFormatter.format(report.totalGrossSales)],
                    ['Net Taxable Sales', _currencyFormatter.format(report.netTaxableSales)],
                    ['Retail Sales Tax', _currencyFormatter.format(report.retailSalesTax)],
                    ['Cost of Goods Purchased', _currencyFormatter.format(report.costOfGoodsPurchased)],
                    ['Sales Tax from Vending', _currencyFormatter.format(report.salesTaxFromVendingMachines)],
                    ['Total Sales Tax Due', _currencyFormatter.format(report.totalSalesTaxDue)],
                    ['Minus Tax Discount', _currencyFormatter.format(report.minusTaxDiscount)],
                    ['Net Amount Tax Due', _currencyFormatter.format(report.netAmountOfSalesTaxDue)],
                    ['Utilities', _currencyFormatter.format(report.utilities)],
                    ['Liability Insurance', _currencyFormatter.format(report.liabilityInsurance)],
                    ['Total of Lines', _currencyFormatter.format(report.totalOfLines)],
                    ['Net Earnings', _currencyFormatter.format(report.netEarningsForTheMonth)],
                    ['Vending Machine Income', _currencyFormatter.format(report.vendingMachineIncome)],
                    ['Total Net Earnings', _currencyFormatter.format(report.totalNetEarnings)],
                    ['% Earnings', '${report.percentageOfEarningsForTheMonth.toStringAsFixed(2)}%'],
                  ]) ...[
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            entry[0],
                            style: pw.TextStyle(font: ttf, fontSize: 12),
                          ),
                          pw.Text(
                            entry[1],
                            style: pw.TextStyle(font: ttf, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    pw.Divider(color: PdfColors.grey300),
                  ],
                ],
              ),
            ];
          },
        ),
      );

      // 3) save to file
      final file = File('$dirPath/MSR-${report.month}.pdf');
      final bytes = await doc.save();
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e, st) {
      debugPrint('❌ PDF generation failed: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// Generates a Sales Report PDF at [filePath], returns the created File.
  static Future<File> generate({
    required String filePath,
    required DateTime startDate,
    required DateTime endDate,
    required String posName,
    required String posType,
    required double salesTotal,
    required double ccFees,
    required double serviceFees,
    required String notes,
  }) async {
    try {
      final doc = pw.Document();
      // load Unicode-capable font
      final ttf = await PdfGoogleFonts.openSansRegular();

      // Add a page with sales report details
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(36),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'SALES REPORT',
                    style: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Period: ${DateFormat.yMd().format(startDate)} – ${DateFormat.yMd().format(endDate)}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('POS Location: $posName ($posType)',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Sales Total: ${_currencyFormatter.format(salesTotal)}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text('CC/EV Fees: ${_currencyFormatter.format(ccFees)}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text('Commission/Service Fees: ${_currencyFormatter.format(serviceFees)}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
                pw.SizedBox(height: 8),
                if (notes.isNotEmpty) pw.Text('Notes: $notes', style: pw.TextStyle(font: ttf, fontSize: 12)),
              ],
            );
          },
        ),
      );

      final file = File(filePath);
      final bytes = await doc.save();
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e, st) {
      debugPrint('❌ Sales PDF generation failed: $e');
      debugPrint('$st');
      rethrow;
    }
  }
}