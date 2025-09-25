import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction_analytics.dart';

class TransactionAnalyticsCard extends StatelessWidget {
  final TimeBasedAnalytics analytics;

  const TransactionAnalyticsCard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColor;
        final isDarkTheme = primaryColor == Colors.black ||
            primaryColor == const Color(0xFF1A237E);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Activity Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkTheme ? Colors.white : primaryColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Time period cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        'Today',
                        analytics.today,
                        primaryColor,
                        isDarkTheme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        'This Week',
                        analytics.thisWeek,
                        primaryColor,
                        isDarkTheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        'This Month',
                        analytics.thisMonth,
                        primaryColor,
                        isDarkTheme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        'This Year',
                        analytics.thisYear,
                        primaryColor,
                        isDarkTheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    TimeBasedMetrics metrics,
    Color primaryColor,
    bool isDarkTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkTheme ? Colors.white : primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                '${metrics.booksDonated}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.remove_circle_outline,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                '${metrics.booksSold}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
