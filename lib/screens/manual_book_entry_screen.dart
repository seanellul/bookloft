import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import 'book_details_screen.dart';

class ManualBookEntryScreen extends StatefulWidget {
  const ManualBookEntryScreen({super.key});

  @override
  State<ManualBookEntryScreen> createState() => _ManualBookEntryScreenState();
}

class _ManualBookEntryScreenState extends State<ManualBookEntryScreen> {
  final _isbnController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _isbnController.dispose();
    super.dispose();
  }

  String _cleanIsbn(String isbn) {
    // Remove all non-alphanumeric characters except X
    return isbn.replaceAll(RegExp(r'[^0-9X]'), '').toUpperCase();
  }

  bool _isValidIsbn(String isbn) {
    final clean = _cleanIsbn(isbn);
    return clean.length == 10 || clean.length == 13;
  }

  Future<void> _lookupBook() async {
    final isbn = _isbnController.text.trim();

    if (isbn.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an ISBN';
      });
      return;
    }

    // Clean and validate ISBN
    final cleanIsbn = _cleanIsbn(isbn);
    if (!_isValidIsbn(cleanIsbn)) {
      setState(() {
        _errorMessage = 'Please enter a valid ISBN (10 or 13 digits)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check if book already exists
      final existingBook = await ApiService.getBookByIsbn(cleanIsbn);
      if (existingBook != null) {
        // Book exists, navigate to book details
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(
                book: existingBook,
                scannedBarcode: cleanIsbn,
              ),
            ),
          );
        }
        return;
      }

      // Book doesn't exist, try to lookup from external APIs
      final bookData = await ApiService.lookupBookByIsbn(cleanIsbn);
      if (bookData != null) {
        // Create new book with looked up data
        // Extract author from the authors array
        String authorName = 'Unknown Author';
        if (bookData['authors'] != null &&
            bookData['authors'] is List &&
            bookData['authors'].isNotEmpty) {
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

        final newBook = Book(
          id: '', // Will be set by backend
          isbn: cleanIsbn,
          title: bookData['title'] ?? 'Unknown Title',
          author: authorName,
          publisher: bookData['publishers']?.isNotEmpty == true
              ? bookData['publishers'][0]['name'] ?? null
              : null,
          description: bookData['description'],
          thumbnailUrl: bookData['thumbnail_url'],
          quantity: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Navigate to book details screen to add the book
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(
                book: newBook,
                scannedBarcode: cleanIsbn,
                isNewBook: true,
              ),
            ),
          );
        }
      } else {
        // No data found, create book with minimal info
        final newBook = Book(
          id: '', // Will be set by backend
          isbn: cleanIsbn,
          title: 'Unknown Title',
          author: 'Unknown Author',
          publisher: null,
          description: null,
          thumbnailUrl: null,
          quantity: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Navigate to book details screen to add the book
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(
                book: newBook,
                scannedBarcode: cleanIsbn,
                isNewBook: true,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error looking up book: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Book Entry'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.library_add,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Book Manually',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter an ISBN to lookup and add a book to inventory',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ISBN Input
            TextField(
              controller: _isbnController,
              decoration: InputDecoration(
                labelText: 'ISBN Number',
                hintText: 'Enter 10 or 13 digit ISBN',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                border: const OutlineInputBorder(),
                suffixIcon: _isbnController.text.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isValidIsbn(_isbnController.text))
                            const Icon(Icons.check_circle, color: Colors.green),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _isbnController.clear();
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _errorMessage = null;
                });
              },
              onSubmitted: (_) => _lookupBook(),
            ),
            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Lookup Button
            ElevatedButton(
              onPressed: _isLoading ? null : _lookupBook,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Lookup Book',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),

            // Help Section
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'How to find ISBN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Look on the back cover or inside the book\n'
                      '• ISBN-13: 13 digits (e.g., 9781234567890)\n'
                      '• ISBN-10: 10 digits (e.g., 1234567890)\n'
                      '• You can enter with or without hyphens',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Alternative Actions
            Text(
              'Alternative Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Barcode'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to search screen
                      Navigator.of(context).pushNamed('/search');
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Search Books'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
