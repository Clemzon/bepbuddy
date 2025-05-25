class Report {
  int? id;
  String standNumber;
  String managerName;
  String month;
  double invoicesPaid;
  double helpersSalary;
  double grossSales;
  double vendingMachineSales;
  double costOfGoodsPurchased;
  double utilities;
  double liabilityInsurance;
  double vendingMachineIncome;
  double salesTaxRate;
  double grossCash;
  double totalGrossSales;
  double netTaxableSales;
  double retailSalesTax;
  double salesTaxFromVendingMachines;
  double totalSalesTaxDue;
  double minusTaxDiscount;
  double netAmountOfSalesTaxDue;
  double totalOfLines;
  double netEarningsForTheMonth;
  double totalNetEarnings;
  double percentageOfEarningsForTheMonth;
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

  Map<String, dynamic> toMap() => {
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

  static Report fromMap(int id, Map<String, dynamic> m) => Report(
    id: id,
    standNumber: m['standNumber'],
    managerName: m['managerName'],
    month: m['month'],
    invoicesPaid: m['invoicesPaid'],
    helpersSalary: m['helpersSalary'],
    grossSales: m['grossSales'],
    vendingMachineSales: m['vendingMachineSales'],
    costOfGoodsPurchased: m['costOfGoodsPurchased'],
    utilities: m['utilities'],
    liabilityInsurance: m['liabilityInsurance'],
    vendingMachineIncome: m['vendingMachineIncome'],
    salesTaxRate: m['salesTaxRate'],
    grossCash: m['grossCash'],
    totalGrossSales: m['totalGrossSales'],
    netTaxableSales: m['netTaxableSales'],
    retailSalesTax: m['retailSalesTax'],
    salesTaxFromVendingMachines: m['salesTaxFromVendingMachines'],
    totalSalesTaxDue: m['totalSalesTaxDue'],
    minusTaxDiscount: m['minusTaxDiscount'],
    netAmountOfSalesTaxDue: m['netAmountOfSalesTaxDue'],
    totalOfLines: m['totalOfLines'],
    netEarningsForTheMonth: m['netEarningsForTheMonth'],
    totalNetEarnings: m['totalNetEarnings'],
    percentageOfEarningsForTheMonth: m['percentageOfEarningsForTheMonth'],
    pdfPath: m['pdfPath'],
  );
}