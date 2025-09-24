// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventorySummary _$InventorySummaryFromJson(Map<String, dynamic> json) =>
    InventorySummary(
      totalBooks: (json['totalBooks'] as num).toInt(),
      totalQuantity: (json['totalQuantity'] as num).toInt(),
      availableBooks: (json['availableBooks'] as num).toInt(),
      booksWithMultipleCopies: (json['booksWithMultipleCopies'] as num).toInt(),
      totalDonations: (json['totalDonations'] as num).toInt(),
      totalSales: (json['totalSales'] as num).toInt(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$InventorySummaryToJson(InventorySummary instance) =>
    <String, dynamic>{
      'totalBooks': instance.totalBooks,
      'totalQuantity': instance.totalQuantity,
      'availableBooks': instance.availableBooks,
      'booksWithMultipleCopies': instance.booksWithMultipleCopies,
      'totalDonations': instance.totalDonations,
      'totalSales': instance.totalSales,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
