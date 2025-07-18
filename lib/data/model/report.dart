class Report {
  int? id;
  final String standNumber;
  final String managerName;
  final String month;
  final double invoicesPaid;
  final double helpersSalary;
  final double grossSales;
  final double vendingMachineSales;
  final double costOfGoodsPurchased;
  final double utilities;
  final double liabilityInsurance;
  final double vendingMachineIncome;
  final double salesTaxRate;
  final double grossCash;
  final double totalGrossSales;
  final double netTaxableSales;
  final double retailSalesTax;
  final double salesTaxFromVendingMachines;
  final double totalSalesTaxDue;
  final double minusTaxDiscount;
  final double netAmountOfSalesTaxDue;
  final double totalOfLines;
  final double netEarningsForTheMonth;
  final double totalNetEarnings;
  final double percentageOfEarningsForTheMonth;
  String? pdfPath;

  Report({
    this.id,
    required this.standNumber,
    required this.managerName,
    required this.month,
    required this.invoicesPaid,
    required this.helpersSalary,
    required this.grossSales,
    required this.vendingMachineSales,
    required this.costOfGoodsPurchased,
    required this.utilities,
    required this.liabilityInsurance,
    required this.vendingMachineIncome,
    required this.salesTaxRate,
    required this.grossCash,
    required this.totalGrossSales,
    required this.netTaxableSales,
    required this.retailSalesTax,
    required this.salesTaxFromVendingMachines,
    required this.totalSalesTaxDue,
    required this.minusTaxDiscount,
    required this.netAmountOfSalesTaxDue,
    required this.totalOfLines,
    required this.netEarningsForTheMonth,
    required this.totalNetEarnings,
    required this.percentageOfEarningsForTheMonth,
    this.pdfPath,
  });

  factory Report.fromMap(Map<String, dynamic> m) => Report(
    id: m['id'] as int?,
    standNumber: m['standNumber'] as String,
    managerName: m['managerName'] as String,
    month: m['month'] as String,
    invoicesPaid: (m['invoicesPaid'] as num).toDouble(),
    helpersSalary: (m['helpersSalary'] as num).toDouble(),
    grossSales: (m['grossSales'] as num).toDouble(),
    vendingMachineSales: (m['vendingMachineSales'] as num).toDouble(),
    costOfGoodsPurchased: (m['costOfGoodsPurchased'] as num).toDouble(),
    utilities: (m['utilities'] as num).toDouble(),
    liabilityInsurance: (m['liabilityInsurance'] as num).toDouble(),
    vendingMachineIncome: (m['vendingMachineIncome'] as num).toDouble(),
    salesTaxRate: (m['salesTaxRate'] as num).toDouble(),
    grossCash: (m['grossCash'] as num).toDouble(),
    totalGrossSales: (m['totalGrossSales'] as num).toDouble(),
    netTaxableSales: (m['netTaxableSales'] as num).toDouble(),
    retailSalesTax: (m['retailSalesTax'] as num).toDouble(),
    salesTaxFromVendingMachines:
    (m['salesTaxFromVendingMachines'] as num).toDouble(),
    totalSalesTaxDue: (m['totalSalesTaxDue'] as num).toDouble(),
    minusTaxDiscount: (m['minusTaxDiscount'] as num).toDouble(),
    netAmountOfSalesTaxDue:
    (m['netAmountOfSalesTaxDue'] as num).toDouble(),
    totalOfLines: (m['totalOfLines'] as num).toDouble(),
    netEarningsForTheMonth:
    (m['netEarningsForTheMonth'] as num).toDouble(),
    totalNetEarnings: (m['totalNetEarnings'] as num).toDouble(),
    percentageOfEarningsForTheMonth:
    (m['percentageOfEarningsForTheMonth'] as num).toDouble(),
    pdfPath: m['pdfPath'] as String?,
  );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'standNumber': standNumber,
      'managerName': managerName,
      'month': month,
      'invoicesPaid': invoicesPaid,
      'helpersSalary': helpersSalary,
      'grossSales': grossSales,
      'vendingMachineSales': vendingMachineSales,
      'costOfGoodsPurchased': costOfGoodsPurchased,
      'utilities': utilities,
      'liabilityInsurance': liabilityInsurance,
      'vendingMachineIncome': vendingMachineIncome,
      'salesTaxRate': salesTaxRate,
      'grossCash': grossCash,
      'totalGrossSales': totalGrossSales,
      'netTaxableSales': netTaxableSales,
      'retailSalesTax': retailSalesTax,
      'salesTaxFromVendingMachines': salesTaxFromVendingMachines,
      'totalSalesTaxDue': totalSalesTaxDue,
      'minusTaxDiscount': minusTaxDiscount,
      'netAmountOfSalesTaxDue': netAmountOfSalesTaxDue,
      'totalOfLines': totalOfLines,
      'netEarningsForTheMonth': netEarningsForTheMonth,
      'totalNetEarnings': totalNetEarnings,
      'percentageOfEarningsForTheMonth': percentageOfEarningsForTheMonth,
      'pdfPath': pdfPath,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}