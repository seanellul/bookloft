// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionAnalytics _$TransactionAnalyticsFromJson(
        Map<String, dynamic> json) =>
    TransactionAnalytics(
      totalTransactions: (json['total_transactions'] as num).toInt(),
      timesDonated: (json['times_donated'] as num).toInt(),
      timesSold: (json['times_sold'] as num).toInt(),
      donationCount: (json['donation_count'] as num).toInt(),
      saleCount: (json['sale_count'] as num).toInt(),
    );

Map<String, dynamic> _$TransactionAnalyticsToJson(
        TransactionAnalytics instance) =>
    <String, dynamic>{
      'total_transactions': instance.totalTransactions,
      'times_donated': instance.timesDonated,
      'times_sold': instance.timesSold,
      'donation_count': instance.donationCount,
      'sale_count': instance.saleCount,
    };

TimeBasedMetrics _$TimeBasedMetricsFromJson(Map<String, dynamic> json) =>
    TimeBasedMetrics(
      booksDonated: (json['books_donated'] as num).toInt(),
      booksSold: (json['books_sold'] as num).toInt(),
      donationTransactions: (json['donation_transactions'] as num).toInt(),
      saleTransactions: (json['sale_transactions'] as num).toInt(),
      totalTransactions: (json['total_transactions'] as num).toInt(),
    );

Map<String, dynamic> _$TimeBasedMetricsToJson(TimeBasedMetrics instance) =>
    <String, dynamic>{
      'books_donated': instance.booksDonated,
      'books_sold': instance.booksSold,
      'donation_transactions': instance.donationTransactions,
      'sale_transactions': instance.saleTransactions,
      'total_transactions': instance.totalTransactions,
    };

TimeBasedAnalytics _$TimeBasedAnalyticsFromJson(Map<String, dynamic> json) =>
    TimeBasedAnalytics(
      today: TimeBasedMetrics.fromJson(json['today'] as Map<String, dynamic>),
      thisWeek:
          TimeBasedMetrics.fromJson(json['this_week'] as Map<String, dynamic>),
      thisMonth:
          TimeBasedMetrics.fromJson(json['this_month'] as Map<String, dynamic>),
      thisYear:
          TimeBasedMetrics.fromJson(json['this_year'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TimeBasedAnalyticsToJson(TimeBasedAnalytics instance) =>
    <String, dynamic>{
      'today': instance.today,
      'this_week': instance.thisWeek,
      'this_month': instance.thisMonth,
      'this_year': instance.thisYear,
    };
