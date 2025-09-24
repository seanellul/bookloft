import 'package:json_annotation/json_annotation.dart';

part 'inventory_summary.g.dart';

@JsonSerializable()
class InventorySummary {
  final int totalBooks;
  final int totalQuantity;
  final int availableBooks;
  final int booksWithMultipleCopies;
  final int totalDonations;
  final int totalSales;
  final DateTime lastUpdated;

  const InventorySummary({
    required this.totalBooks,
    required this.totalQuantity,
    required this.availableBooks,
    required this.booksWithMultipleCopies,
    required this.totalDonations,
    required this.totalSales,
    required this.lastUpdated,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) =>
      _$InventorySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$InventorySummaryToJson(this);

  double get salesRate =>
      totalSales > 0 ? (totalSales / (totalDonations + totalSales)) * 100 : 0.0;
}
