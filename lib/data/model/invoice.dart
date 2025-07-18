// lib/data/model/invoice.dart

import 'dart:convert';

class Invoice {
  final String id;
  final String vendorName;
  final DateTime date;
  final double fees;
  final double taxes;
  final double total;
  final String? attachmentPath;
  final bool archived;

  Invoice({
    required this.id,
    required this.vendorName,
    required this.date,
    required this.fees,
    required this.taxes,
    required this.total,
    this.attachmentPath,
    this.archived = false,
  });

  Invoice copyWith({
    String? id,
    String? vendorName,
    DateTime? date,
    double? fees,
    double? taxes,
    double? total,
    String? attachmentPath,
    bool? archived,
  }) {
    return Invoice(
      id: id ?? this.id,
      vendorName: vendorName ?? this.vendorName,
      date: date ?? this.date,
      fees: fees ?? this.fees,
      taxes: taxes ?? this.taxes,
      total: total ?? this.total,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vendorName': vendorName,
    'date': date.toIso8601String(),
    'fees': fees,
    'taxes': taxes,
    'total': total,
    'attachmentPath': attachmentPath,
    'archived': archived,
  };

  factory Invoice.fromJson(Map<String, dynamic> m) => Invoice(
    id: m['id'] as String,
    vendorName: m['vendorName'] as String,
    date: DateTime.parse(m['date'] as String),
    fees: (m['fees'] as num).toDouble(),
    taxes: (m['taxes'] as num).toDouble(),
    total: (m['total'] as num).toDouble(),
    attachmentPath: m['attachmentPath'] as String?,
    archived: m['archived'] as bool? ?? false,
  );

  String toJsonString() => jsonEncode(toJson());
}