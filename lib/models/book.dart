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

  // New metadata fields
  final String? binding; // hardback, paperback, etc.
  @JsonKey(name: 'isbn_10')
  final String? isbn10;
  final String? language;
  @JsonKey(name: 'page_count')
  final String? pageCount;
  final String? dimensions;
  final String? weight;
  final String? edition;
  final String? series;
  final String? subtitle;
  final String? categories; // JSON string
  final String? tags; // JSON string
  @JsonKey(name: 'maturity_rating')
  final String? maturityRating;
  final String? format;

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
    // New metadata fields
    this.binding,
    this.isbn10,
    this.language,
    this.pageCount,
    this.dimensions,
    this.weight,
    this.edition,
    this.series,
    this.subtitle,
    this.categories,
    this.tags,
    this.maturityRating,
    this.format,
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
    // New metadata fields
    String? binding,
    String? isbn10,
    String? language,
    String? pageCount,
    String? dimensions,
    String? weight,
    String? edition,
    String? series,
    String? subtitle,
    String? categories,
    String? tags,
    String? maturityRating,
    String? format,
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
      // New metadata fields
      binding: binding ?? this.binding,
      isbn10: isbn10 ?? this.isbn10,
      language: language ?? this.language,
      pageCount: pageCount ?? this.pageCount,
      dimensions: dimensions ?? this.dimensions,
      weight: weight ?? this.weight,
      edition: edition ?? this.edition,
      series: series ?? this.series,
      subtitle: subtitle ?? this.subtitle,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      maturityRating: maturityRating ?? this.maturityRating,
      format: format ?? this.format,
    );
  }

  bool get isAvailable => quantity > 0;
  bool get hasMultipleCopies => quantity > 1;
}
