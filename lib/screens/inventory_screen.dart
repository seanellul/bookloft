import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/book.dart';
import '../models/transaction.dart';
import '../widgets/book_card.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Book details
              Row(
                children: [
                  Icon(
                    Icons.book,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      book.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Author', book.author),
                      _buildDetailRow('ISBN', book.isbn),
                      if (book.publisher != null)
                        _buildDetailRow('Publisher', book.publisher!),
                      if (book.publishedDate != null)
                        _buildDetailRow('Published', book.publishedDate!),
                      _buildDetailRow('Quantity', book.quantity.toString()),
                      _buildDetailRow('Status',
                          book.isAvailable ? 'Available' : 'Out of Stock'),
                      if (book.description != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Description',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showTransactionDialog(book, true);
                      },
                      icon: const Icon(Icons.add_box),
                      label: const Text('Add Donation'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: book.isAvailable
                          ? () {
                              Navigator.of(context).pop();
                              _showTransactionDialog(book, false);
                            }
                          : null,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Process Sale'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDialog(Book book, bool isDonation) {
    final quantityController = TextEditingController();
    final volunteerController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDonation ? 'Add Donation' : 'Process Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Book: ${book.title}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: volunteerController,
              decoration: const InputDecoration(
                labelText: 'Volunteer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final provider = context.read<InventoryProvider>();
              final transaction = Transaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                bookId: book.id,
                type: isDonation
                    ? TransactionType.donation
                    : TransactionType.sale,
                quantity: quantity,
                date: DateTime.now(),
                notes:
                    notesController.text.isEmpty ? null : notesController.text,
                volunteerName: volunteerController.text.isEmpty
                    ? null
                    : volunteerController.text,
                createdAt: DateTime.now(),
              );

              final success = await provider.addTransaction(transaction);
              if (success) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transaction processed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(isDonation ? 'Add Donation' : 'Process Sale'),
          ),
        ],
      ),
    );
  }
}
