import 'package:flutter/material.dart';
import '../models/inventory_summary.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class InventorySummaryCard extends StatelessWidget {
  final InventorySummary summary;

  const InventorySummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Inventory Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildStatItem(
                      context,
                      'Total Books',
                      summary.totalBooks.toString(),
                      Icons.library_books,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildStatItem(
                      context,
                      'Available',
                      summary.availableBooks.toString(),
                      Icons.check_circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildStatItem(
                      context,
                      'Total Quantity',
                      summary.totalQuantity.toString(),
                      Icons.inventory,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildStatItem(
                      context,
                      'Multiple Copies',
                      summary.booksWithMultipleCopies.toString(),
                      Icons.copy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildStatItem(
                      context,
                      'Donations',
                      summary.totalDonations.toString(),
                      Icons.add_box,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildStatItem(
                      context,
                      'Sales',
                      summary.totalSales.toString(),
                      Icons.shopping_cart,
                    ),
                  ),
                ),
              ],
            ),
            if (summary.salesRate > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sales Rate: ${summary.salesRate.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColor;
        final isDarkTheme = primaryColor == Colors.black ||
            primaryColor == const Color(0xFF1A237E);

        // Use white for dark themes, primary color for light themes
        final iconColor = isDarkTheme
            ? Colors.white
            : Theme.of(context).colorScheme.primary.withOpacity(0.8);
        final textColor = isDarkTheme
            ? Colors.white
            : Theme.of(context).colorScheme.primary.withOpacity(0.8);
        final labelColor = isDarkTheme
            ? Colors.white70
            : Theme.of(context).colorScheme.onSurfaceVariant;

        // Use darker background for dark themes, lighter for light themes
        final backgroundColor = isDarkTheme
            ? primaryColor.withOpacity(0.3)
            : primaryColor.withOpacity(0.15);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkTheme
                  ? primaryColor.withOpacity(0.4)
                  : primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
