import 'package:json_annotation/json_annotation.dart';

part 'transaction_analytics.g.dart';

@JsonSerializable()
class TransactionAnalytics {
  @JsonKey(name: 'total_transactions')
  final int totalTransactions;
  @JsonKey(name: 'times_donated')
  final int timesDonated;
  @JsonKey(name: 'times_sold')
  final int timesSold;
  @JsonKey(name: 'donation_count')
  final int donationCount;
  @JsonKey(name: 'sale_count')
  final int saleCount;

  const TransactionAnalytics({
    required this.totalTransactions,
    required this.timesDonated,
    required this.timesSold,
    required this.donationCount,
    required this.saleCount,
  });

  factory TransactionAnalytics.fromJson(Map<String, dynamic> json) =>
      _$TransactionAnalyticsFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionAnalyticsToJson(this);
}

@JsonSerializable()
class TimeBasedMetrics {
  @JsonKey(name: 'books_donated')
  final int booksDonated;
  @JsonKey(name: 'books_sold')
  final int booksSold;
  @JsonKey(name: 'donation_transactions')
  final int donationTransactions;
  @JsonKey(name: 'sale_transactions')
  final int saleTransactions;
  @JsonKey(name: 'total_transactions')
  final int totalTransactions;

  const TimeBasedMetrics({
    required this.booksDonated,
    required this.booksSold,
    required this.donationTransactions,
    required this.saleTransactions,
    required this.totalTransactions,
  });

  factory TimeBasedMetrics.fromJson(Map<String, dynamic> json) =>
      _$TimeBasedMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$TimeBasedMetricsToJson(this);
}

@JsonSerializable()
class TimeBasedAnalytics {
  final TimeBasedMetrics today;
  @JsonKey(name: 'this_week')
  final TimeBasedMetrics thisWeek;
  @JsonKey(name: 'this_month')
  final TimeBasedMetrics thisMonth;
  @JsonKey(name: 'this_year')
  final TimeBasedMetrics thisYear;

  const TimeBasedAnalytics({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.thisYear,
  });

  factory TimeBasedAnalytics.fromJson(Map<String, dynamic> json) =>
      _$TimeBasedAnalyticsFromJson(json);
  Map<String, dynamic> toJson() => _$TimeBasedAnalyticsToJson(this);
}
