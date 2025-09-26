import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/book.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../providers/inventory_provider.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book? book;
  final String scannedBarcode;
  final bool isNewBook;

  const BookDetailsScreen({
    super.key,
    this.book,
    required this.scannedBarcode,
    this.isNewBook = false,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _publisherController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isDonation = true;
  String? _bookCoverUrl;
  int _transactionQuantity = 1;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    if (widget.isNewBook) {
      _lookupBookData();
    }
  }

  void _initializeForm() {
    if (widget.book != null) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _publisherController.text = widget.book!.publisher ?? '';
      _descriptionController.text = widget.book!.description ?? '';
      _quantityController.text = widget.book!.quantity.toString();
      _bookCoverUrl = widget.book!.thumbnailUrl;
      print('Book cover URL from existing book: $_bookCoverUrl'); // Debug
    }
  }

  Future<void> _lookupBookData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookData = await ApiService.lookupBookByIsbn(widget.scannedBarcode);
      if (bookData != null) {
        // Enhanced logging for debugging
        print('=== BOOK LOOKUP DEBUG ===');
        print('Raw API response: $bookData');
        print('Authors field: ${bookData['authors']}');
        print('Authors type: ${bookData['authors'].runtimeType}');
        if (bookData['authors'] is List) {
          print('Authors list length: ${bookData['authors'].length}');
          if (bookData['authors'].isNotEmpty) {
            print('First author: ${bookData['authors'][0]}');
            print('First author type: ${bookData['authors'][0].runtimeType}');
            if (bookData['authors'][0] is Map) {
              print('First author name: ${bookData['authors'][0]['name']}');
            }
          }
        }

        setState(() {
          _titleController.text = bookData['title'] ?? '';

          // Enhanced author parsing with better error handling
          String authorName = '';
          if (bookData['authors'] != null &&
              bookData['authors'] is List &&
              bookData['authors'].isNotEmpty) {
            // Join multiple authors with ", " or just take the first one
            final authorsList = <String>[];
            for (var author in bookData['authors']) {
              if (author is Map && author['name'] != null) {
                final name = author['name'].toString().trim();
                if (name.isNotEmpty && !name.startsWith('/authors/')) {
                  authorsList.add(name);
                }
              } else if (author is String) {
                final name = author.trim();
                if (name.isNotEmpty && !name.startsWith('/authors/')) {
                  authorsList.add(name);
                }
              }
            }

            if (authorsList.isNotEmpty) {
              // Join up to 3 authors for readability
              authorName = authorsList.take(3).join(', ');
              if (authorsList.length > 3) {
                authorName += ' et al.';
              }
            }
          }
          _authorController.text = authorName;

          _publisherController.text = bookData['publishers']?.isNotEmpty == true
              ? bookData['publishers'][0]['name'] ?? ''
              : '';
          _descriptionController.text = bookData['description'] ?? '';
          _bookCoverUrl = bookData['thumbnail_url'];

          print('Final author value: "${_authorController.text}"');
          print('Book cover URL from API lookup: $_bookCoverUrl');
          print('=== END DEBUG ===');
        });

        // For existing books, save the updated information to database
        if (!widget.isNewBook && widget.book != null) {
          final updatedBook = widget.book!.copyWith(
            title: _titleController.text,
            author: _authorController.text,
            publisher: _publisherController.text.isEmpty
                ? null
                : _publisherController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            thumbnailUrl: _bookCoverUrl,
            // Add new metadata fields
            binding: bookData['binding'],
            isbn10: bookData['isbn_10'],
            language: bookData['language'],
            pageCount: bookData['page_count'],
            dimensions: bookData['dimensions'],
            weight: bookData['weight'],
            edition: bookData['edition'],
            series: bookData['series'],
            subtitle: bookData['subtitle'],
            categories: bookData['categories'],
            tags: bookData['tags'],
            maturityRating: bookData['maturity_rating'],
            format: bookData['format'],
            publishedDate: bookData['publish_date'],
            updatedAt: DateTime.now(),
          );

          // Route updates through provider to keep local state in sync
          final provider =
              Provider.of<InventoryProvider>(context, listen: false);
          await provider.updateBook(updatedBook);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Book information updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to lookup book information: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building BookDetailsScreen - Cover URL: $_bookCoverUrl'); // Debug
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: _buildBookContent(context),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColor;
        final isDarkTheme = primaryColor == Colors.black ||
            primaryColor == const Color(0xFF1A237E);

        return SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: primaryColor,
          foregroundColor: isDarkTheme ? Colors.white : Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _titleController.text.isNotEmpty
                          ? _titleController.text
                          : 'Unknown Title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _authorController.text.isNotEmpty
                          ? _authorController.text
                          : 'Unknown Author',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (!widget.isNewBook)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editBook,
                tooltip: 'Edit Book',
              ),
          ],
        );
      },
    );
  }

  Widget _buildBookContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Information Card
          _buildBookInfoCard(context),
          const SizedBox(height: 20),

          // Description Card
          if (_descriptionController.text.isNotEmpty)
            _buildDescriptionCard(context),

          if (_descriptionController.text.isNotEmpty)
            const SizedBox(height: 20),

          // Transaction Section (for both new and existing books)
          _buildTransactionSection(context),
        ],
      ),
    );
  }

  Widget _buildBookInfoCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColor;
        final isDarkTheme = primaryColor == Colors.black ||
            primaryColor == const Color(0xFF1A237E);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                        color: isDarkTheme
                            ? primaryColor.withOpacity(0.3)
                            : primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: isDarkTheme ? Colors.white : primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Book Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkTheme ? Colors.white : null,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Book cover image (small reference)
                if (_bookCoverUrl != null && _bookCoverUrl!.isNotEmpty)
                  Center(
                    child: Container(
                      height: 120,
                      width: 80,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _bookCoverUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Image load error: $error'); // Debug
                            return Container(
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.book,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No Cover',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                // Show placeholder when no cover URL
                if (_bookCoverUrl == null || _bookCoverUrl!.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 120,
                          width: 80,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.book,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No Cover',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Lookup button for existing books
                        if (!widget.isNewBook)
                          ElevatedButton.icon(
                            onPressed: _lookupBookData,
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text('Lookup Book Info'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Book details grid
                _buildInfoRow(
                    context, 'Title', _titleController.text, Icons.title),
                _buildInfoRow(
                    context, 'Author', _authorController.text, Icons.person),
                _buildInfoRow(
                    context, 'ISBN-13', widget.scannedBarcode, Icons.qr_code),

                // New metadata fields
                if (widget.book?.isbn10 != null &&
                    widget.book!.isbn10!.isNotEmpty)
                  _buildInfoRow(context, 'ISBN-10', widget.book!.isbn10!,
                      Icons.qr_code_2),
                if (widget.book?.publishedDate != null &&
                    widget.book!.publishedDate!.isNotEmpty)
                  _buildInfoRow(context, 'Published',
                      widget.book!.publishedDate!, Icons.calendar_today),
                if (widget.book?.binding != null &&
                    widget.book!.binding!.isNotEmpty)
                  _buildInfoRow(
                      context, 'Binding', widget.book!.binding!, Icons.book),
                if (widget.book?.language != null &&
                    widget.book!.language!.isNotEmpty)
                  _buildInfoRow(context, 'Language', widget.book!.language!,
                      Icons.language),
                if (widget.book?.pageCount != null &&
                    widget.book!.pageCount!.isNotEmpty)
                  _buildInfoRow(context, 'Pages', widget.book!.pageCount!,
                      Icons.menu_book),
                if (widget.book?.edition != null &&
                    widget.book!.edition!.isNotEmpty)
                  _buildInfoRow(context, 'Edition', widget.book!.edition!,
                      Icons.library_books),
                if (widget.book?.series != null &&
                    widget.book!.series!.isNotEmpty)
                  _buildInfoRow(context, 'Series', widget.book!.series!,
                      Icons.collections_bookmark),
                if (widget.book?.subtitle != null &&
                    widget.book!.subtitle!.isNotEmpty)
                  _buildInfoRow(context, 'Subtitle', widget.book!.subtitle!,
                      Icons.subtitles),
                if (widget.book?.categories != null &&
                    widget.book!.categories!.isNotEmpty)
                  _buildInfoRow(context, 'Categories', widget.book!.categories!,
                      Icons.category),
                if (widget.book?.format != null &&
                    widget.book!.format!.isNotEmpty)
                  _buildInfoRow(context, 'Format', widget.book!.format!,
                      Icons.format_align_left),

                // Original fields
                if (_publisherController.text.isNotEmpty)
                  _buildInfoRow(context, 'Publisher', _publisherController.text,
                      Icons.business),
                if (widget.book != null)
                  _buildInfoRow(context, 'Quantity',
                      widget.book!.quantity.toString(), Icons.inventory),
                if (widget.book != null)
                  _buildInfoRow(
                    context,
                    'Status',
                    widget.book!.quantity > 0 ? 'Available' : 'Out of Stock',
                    widget.book!.quantity > 0
                        ? Icons.check_circle
                        : Icons.cancel,
                    valueColor:
                        widget.book!.quantity > 0 ? Colors.green : Colors.red,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: valueColor ??
                            Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColor;
        final isDarkTheme = primaryColor == Colors.black ||
            primaryColor == const Color(0xFF1A237E);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                        color: isDarkTheme
                            ? primaryColor.withOpacity(0.3)
                            : primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description,
                        color: isDarkTheme ? Colors.white : primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkTheme ? Colors.white : null,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkTheme
                        ? primaryColor.withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkTheme
                          ? primaryColor.withOpacity(0.2)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Text(
                    _descriptionController.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: isDarkTheme ? Colors.white70 : null,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColor;
        final isDarkTheme = primaryColor == Colors.black ||
            primaryColor == const Color(0xFF1A237E);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                        color: isDarkTheme
                            ? primaryColor.withOpacity(0.3)
                            : primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.swap_horiz,
                        color: isDarkTheme ? Colors.white : primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.isNewBook
                          ? 'Add Book & Transaction'
                          : 'Transaction',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkTheme ? Colors.white : null,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Transaction Type Selector
                _buildTransactionTypeSelector(context),
                const SizedBox(height: 20),

                // Quantity Selector
                _buildQuantitySelector(context),
                const SizedBox(height: 20),

                // Notes
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any additional notes...',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _processTransaction,
                        icon: Icon(_isDonation ? Icons.add : Icons.remove),
                        label: Text(
                          widget.isNewBook
                              ? (_isDonation
                                  ? 'Add Book & Donation'
                                  : 'Add Book & Sale')
                              : (_isDonation ? 'Add Donation' : 'Process Sale'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

  Widget _buildTransactionTypeSelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColor;
        final isDarkTheme = primaryColor == Colors.black ||
            primaryColor == const Color(0xFF1A237E);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : null,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTransactionTypeButton(
                    context,
                    'Donation',
                    'Adding books to inventory',
                    Icons.add_circle_outline,
                    true,
                    _isDonation,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTransactionTypeButton(
                    context,
                    'Sale',
                    'Removing books from inventory',
                    Icons.remove_circle_outline,
                    false,
                    !_isDonation,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTypeButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isDonation,
    bool isSelected,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColor;
        final isDarkTheme = primaryColor == Colors.black ||
            primaryColor == const Color(0xFF1A237E);

        return GestureDetector(
          onTap: () {
            setState(() {
              _isDonation = isDonation;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDarkTheme
                      ? primaryColor.withOpacity(0.3)
                      : primaryColor.withOpacity(0.1))
                  : (isDarkTheme
                      ? Colors.grey[800]?.withOpacity(0.3)
                      : Colors.grey[100]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : (isDarkTheme ? Colors.grey[600]! : Colors.grey[300]!),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? (isDarkTheme ? Colors.white : primaryColor)
                      : (isDarkTheme ? Colors.grey[400] : Colors.grey[600]),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (isDarkTheme ? Colors.white : primaryColor)
                        : (isDarkTheme ? Colors.grey[300] : Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? (isDarkTheme
                            ? Colors.white70
                            : primaryColor.withOpacity(0.8))
                        : (isDarkTheme ? Colors.grey[500] : Colors.grey[500]),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantitySelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = themeProvider.primaryColor;
        final isDarkTheme = primaryColor == Colors.black ||
            primaryColor == const Color(0xFF1A237E);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : null,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkTheme
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkTheme
                      ? primaryColor.withOpacity(0.2)
                      : Colors.grey[200]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _transactionQuantity > 1
                        ? () {
                            setState(() {
                              _transactionQuantity--;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color:
                          _transactionQuantity > 1 ? primaryColor : Colors.grey,
                    ),
                  ),
                  Text(
                    '$_transactionQuantity',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkTheme ? Colors.white : primaryColor,
                        ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _transactionQuantity++;
                      });
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _editBook() {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  Future<void> _processTransaction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Book bookToUse;

      if (widget.isNewBook) {
        // For new books, save the book first
        // Get metadata from API lookup if available
        final bookData =
            await ApiService.lookupBookByIsbn(widget.scannedBarcode);

        bookToUse = Book(
          id: '', // Will be set by backend
          isbn: widget.scannedBarcode,
          title: _titleController.text,
          author: _authorController.text,
          publisher: _publisherController.text.isEmpty
              ? null
              : _publisherController.text,
          publishedDate: bookData?['publish_date'],
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          thumbnailUrl: _bookCoverUrl,
          quantity: 0, // Initial quantity is 0, transactions add/remove
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          // New metadata fields from API lookup
          binding: bookData?['binding'],
          isbn10: bookData?['isbn_10'],
          language: bookData?['language'],
          pageCount: bookData?['page_count'],
          dimensions: bookData?['dimensions'],
          weight: bookData?['weight'],
          edition: bookData?['edition'],
          series: bookData?['series'],
          subtitle: bookData?['subtitle'],
          categories: bookData?['categories'],
          tags: bookData?['tags'],
          maturityRating: bookData?['maturity_rating'],
          format: bookData?['format'],
        );

        // Save the book first
        // Ensure the book exists on the server and get the server copy
        bookToUse = await ApiService.ensureServerBook(bookToUse);

        // Add the book to the provider's local state
        final provider = Provider.of<InventoryProvider>(context, listen: false);
        await provider.addBook(bookToUse);
      } else {
        // For existing books, use the existing book
        bookToUse = widget.book!;
      }

      // Now create the transaction
      final transaction = Transaction(
        id: '', // Will be set by backend
        bookId: bookToUse.id,
        type: _isDonation ? TransactionType.donation : TransactionType.sale,
        quantity: _transactionQuantity,
        date: DateTime.now(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        volunteerName: '', // Will be auto-populated by backend
        createdAt: DateTime.now(),
      );

      // Use provider so local DB and summary stay consistent
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      await provider.addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDonation
                  ? 'Book added and donation recorded successfully!'
                  : 'Book added and sale processed successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
