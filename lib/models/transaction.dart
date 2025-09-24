import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

enum TransactionType {
  @JsonValue('donation')
  donation,
  @JsonValue('sale')
  sale,
}

@JsonSerializable()
class Transaction {
  final String id;
  final String bookId;
  final TransactionType type;
  final int quantity;
  final DateTime date;
  final String? notes;
  final String? volunteerName;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.bookId,
    required this.type,
    required this.quantity,
    required this.date,
    this.notes,
    this.volunteerName,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  Transaction copyWith({
    String? id,
    String? bookId,
    TransactionType? type,
    int? quantity,
    DateTime? date,
    String? notes,
    String? volunteerName,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      volunteerName: volunteerName ?? this.volunteerName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isDonation => type == TransactionType.donation;
  bool get isSale => type == TransactionType.sale;
}
