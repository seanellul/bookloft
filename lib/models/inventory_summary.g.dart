// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventorySummary _$InventorySummaryFromJson(Map<String, dynamic> json) =>
    InventorySummary(
      totalBooks: json['total_books'] as int,
      totalQuantity: json['total_quantity'] as int,
      availableBooks: json['available_books'] as int,
      booksWithMultipleCopies: json['books_with_multiple_copies'] as int,
      totalDonations: json['total_donations'] as int,
      totalSales: json['total_sales'] as int,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$InventorySummaryToJson(InventorySummary instance) =>
    <String, dynamic>{
      'total_books': instance.totalBooks,
      'total_quantity': instance.totalQuantity,
      'available_books': instance.availableBooks,
      'books_with_multiple_copies': instance.booksWithMultipleCopies,
      'total_donations': instance.totalDonations,
      'total_sales': instance.totalSales,
      'last_updated': instance.lastUpdated.toIso8601String(),
    };
