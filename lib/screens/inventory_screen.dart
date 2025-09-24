import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import 'book_details_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _filter = 'all';
  String _sortBy = 'title';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Books'),
              ),
              const PopupMenuItem(
                value: 'available',
                child: Text('Available Only'),
              ),
              const PopupMenuItem(
                value: 'multiple',
                child: Text('Multiple Copies'),
              ),
              const PopupMenuItem(
                value: 'out_of_stock',
                child: Text('Out of Stock'),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getFilterLabel()),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    const Text('Title'),
                    if (_sortBy == 'title')
                      Icon(_sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'author',
                child: Row(
                  children: [
                    const Text('Author'),
                    if (_sortBy == 'author')
                      Icon(_sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quantity',
                child: Row(
                  children: [
                    const Text('Quantity'),
                    if (_sortBy == 'quantity')
                      Icon(_sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.sort),
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

          final books = _getFilteredAndSortedBooks(provider.books);

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadBooks();
            },
            child: books.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BookCard(
                          book: book,
                          onTap: () => _showBookDetails(book),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No books found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add some books to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Book> _getFilteredAndSortedBooks(List<Book> books) {
    List<Book> filteredBooks = books.where((book) {
      switch (_filter) {
        case 'available':
          return book.isAvailable;
        case 'multiple':
          return book.hasMultipleCopies;
        case 'out_of_stock':
          return !book.isAvailable;
        default:
          return true;
      }
    }).toList();

    filteredBooks.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'author':
          comparison = a.author.compareTo(b.author);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredBooks;
  }

  String _getFilterLabel() {
    switch (_filter) {
      case 'available':
        return 'Available';
      case 'multiple':
        return 'Multiple';
      case 'out_of_stock':
        return 'Out of Stock';
      default:
        return 'All';
    }
  }

  void _showBookDetails(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookDetailsScreen(
          book: book,
          scannedBarcode: book.isbn,
          isNewBook: false,
        ),
      ),
    );
  }
}
