import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
class Book {
  final String id;
  final String isbn;
  final String title;
  final String author;
  final String? publisher;
  @JsonKey(name: 'published_date')
  final String? publishedDate;
  final String? description;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  final int quantity;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.publisher,
    this.publishedDate,
    this.description,
    this.thumbnailUrl,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);

  Book copyWith({
    String? id,
    String? isbn,
    String? title,
    String? author,
    String? publisher,
    String? publishedDate,
    String? description,
    String? thumbnailUrl,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAvailable => quantity > 0;
  bool get hasMultipleCopies => quantity > 1;
}
