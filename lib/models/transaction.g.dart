// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      type: TransactionType.values
          .firstWhere((e) => e.toString().split('.').last == json['type']),
      quantity: json['quantity'] as int,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      volunteerName: json['volunteer_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'book_id': instance.bookId,
      'type': instance.type.toString().split('.').last,
      'quantity': instance.quantity,
      'date': instance.date.toIso8601String(),
      'notes': instance.notes,
      'volunteer_name': instance.volunteerName,
      'created_at': instance.createdAt.toIso8601String(),
    };
