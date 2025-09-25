import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/inventory_summary_card.dart';
import '../widgets/transaction_analytics_card.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/transaction_analytics.dart';
import 'search_screen.dart';
import 'scanner_screen.dart';
import 'inventory_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimeBasedAnalytics? _analytics;
  bool _analyticsLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().initialize();
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _analyticsLoading = true;
    });

    try {
      final analytics = await ApiService.getTimeBasedAnalytics();
      setState(() {
        _analytics = analytics;
      });
    } catch (e) {
      print('Error loading analytics: $e');
    } finally {
      setState(() {
        _analyticsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final primaryColor = themeProvider.primaryColor;
            final isDarkTheme = primaryColor == Colors.black ||
                primaryColor == const Color(0xFF1A237E);

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkTheme
                        ? primaryColor.withOpacity(0.3)
                        : primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.library_books,
                    size: 20,
                    color: isDarkTheme ? Colors.white : primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Book Loft',
                  style: TextStyle(
                    color: isDarkTheme
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        shadowColor: Colors.transparent,
        actions: [
          // Theme selector
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (themeName) async {
                  await themeProvider.setTheme(themeName);
                },
                itemBuilder: (context) =>
                    ThemeProvider.availableThemes.map((theme) {
                  return PopupMenuItem(
                    value: theme,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: ThemeProvider.colorSchemes[theme],
                            shape: BoxShape.circle,
                            border: ThemeProvider.colorSchemes[theme] ==
                                        Colors.black ||
                                    ThemeProvider.colorSchemes[theme] ==
                                        const Color(0xFF1A237E)
                                ? Border.all(color: Colors.grey[300]!, width: 1)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(theme),
                        if (themeProvider.themeName == theme) ...[
                          const Spacer(),
                          const Icon(Icons.check, size: 16),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                icon: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final primaryColor = themeProvider.primaryColor;
                    final isDarkTheme = primaryColor == Colors.black ||
                        primaryColor == const Color(0xFF1A237E);

                    return Icon(
                      Icons.palette,
                      color: isDarkTheme ? Colors.white : primaryColor,
                    );
                  },
                ),
                tooltip: 'Change theme color',
              );
            },
          ),
          Consumer<InventoryProvider>(
            builder: (context, provider, child) {
              if (provider.isOffline) {
                return IconButton(
                  onPressed: () async {
                    await provider.checkConnectionAndSync();
                  },
                  icon: Icon(
                    Icons.cloud_off,
                    color: Colors.orange,
                  ),
                  tooltip: 'Offline - Tap to retry connection',
                );
              }
              return IconButton(
                onPressed: () async {
                  await provider.checkConnectionAndSync();
                },
                icon: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final primaryColor = themeProvider.primaryColor;
                    final isDarkTheme = primaryColor == Colors.black ||
                        primaryColor == const Color(0xFF1A237E);

                    return Icon(
                      Icons.cloud_done,
                      color: isDarkTheme ? Colors.white : primaryColor,
                    );
                  },
                ),
                tooltip: 'Online - Tap to refresh',
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadBooks();
              await provider.loadSummary();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection status banner
                  if (provider.isOffline)
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        final primaryColor = themeProvider.primaryColor;
                        final isDarkTheme = primaryColor == Colors.black ||
                            primaryColor == const Color(0xFF1A237E);

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkTheme
                                  ? [
                                      primaryColor.withOpacity(0.3),
                                      primaryColor.withOpacity(0.2),
                                    ]
                                  : [
                                      primaryColor.withOpacity(0.1),
                                      primaryColor.withOpacity(0.05),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkTheme
                                  ? primaryColor.withOpacity(0.4)
                                  : primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDarkTheme
                                      ? primaryColor.withOpacity(0.4)
                                      : primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.cloud_off,
                                  color:
                                      isDarkTheme ? Colors.white : primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Working Offline',
                                      style: TextStyle(
                                        color: isDarkTheme
                                            ? Colors.white
                                            : primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap the cloud icon to retry connection',
                                      style: TextStyle(
                                        color: isDarkTheme
                                            ? Colors.white70
                                            : primaryColor.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Welcome message with gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.library_books,
                                  size: 28,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome to Book Loft',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cayman Humane Society',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Manage your book inventory with ease. Scan barcodes, track donations, and process sales.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Inventory summary
                  if (provider.summary != null)
                    InventorySummaryCard(summary: provider.summary!),

                  const SizedBox(height: 16),

                  // Transaction analytics
                  if (_analytics != null)
                    TransactionAnalyticsCard(analytics: _analytics!)
                  else if (_analyticsLoading)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Recent activity section
                  _buildRecentActivitySection(provider),

                  // Bottom spacing to prevent FAB overlap
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final primaryColor = themeProvider.primaryColor;
          final isDarkTheme = primaryColor == Colors.black ||
              primaryColor == const Color(0xFF1A237E);

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ScannerScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.qr_code_scanner,
                size: 24,
                color: isDarkTheme ? Colors.white : Colors.white,
              ),
              label: Text(
                'Scan Book',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDarkTheme ? Colors.white : Colors.white,
                ),
              ),
              backgroundColor: primaryColor,
              foregroundColor: isDarkTheme ? Colors.white : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivitySection(InventoryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildQuickAccessCard(
              context,
              'Search Books',
              Icons.search,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              ),
            ),
            _buildQuickAccessCard(
              context,
              'View Inventory',
              Icons.inventory,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InventoryScreen(),
                ),
              ),
            ),
            _buildQuickAccessCard(
              context,
              'Add Donation',
              Icons.add_box,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ScannerScreen(),
                ),
              ),
            ),
            _buildQuickAccessCard(
              context,
              'Process Sale',
              Icons.shopping_cart,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ScannerScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
