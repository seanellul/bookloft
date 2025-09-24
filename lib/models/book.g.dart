// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      id: json['id'] as String,
      isbn: json['isbn'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      publisher: json['publisher'] as String?,
      publishedDate: json['published_date'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      binding: json['binding'] as String?,
      isbn10: json['isbn_10'] as String?,
      language: json['language'] as String?,
      pageCount: json['page_count'] as String?,
      dimensions: json['dimensions'] as String?,
      weight: json['weight'] as String?,
      edition: json['edition'] as String?,
      series: json['series'] as String?,
      subtitle: json['subtitle'] as String?,
      categories: json['categories'] as String?,
      tags: json['tags'] as String?,
      maturityRating: json['maturity_rating'] as String?,
      format: json['format'] as String?,
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'isbn': instance.isbn,
      'title': instance.title,
      'author': instance.author,
      'publisher': instance.publisher,
      'published_date': instance.publishedDate,
      'description': instance.description,
      'thumbnail_url': instance.thumbnailUrl,
      'quantity': instance.quantity,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'binding': instance.binding,
      'isbn_10': instance.isbn10,
      'language': instance.language,
      'page_count': instance.pageCount,
      'dimensions': instance.dimensions,
      'weight': instance.weight,
      'edition': instance.edition,
      'series': instance.series,
      'subtitle': instance.subtitle,
      'categories': instance.categories,
      'tags': instance.tags,
      'maturity_rating': instance.maturityRating,
      'format': instance.format,
    };
