import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/book.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

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
  final _volunteerNameController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isDonation = true;
  String? _bookCoverUrl;

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
    } else {
      _quantityController.text = '1';
    }
  }

  Future<void> _lookupBookData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookData = await ApiService.lookupBookByIsbn(widget.scannedBarcode);
      if (bookData != null) {
        setState(() {
          _titleController.text = bookData['title'] ?? '';
          _authorController.text = bookData['authors'] != null
              ? (bookData['authors'] as List).map((a) => a['name']).join(', ')
              : '';
          _publisherController.text = bookData['publishers'] != null
              ? (bookData['publishers'] as List)
                  .map((p) => p['name'])
                  .join(', ')
              : '';
          _descriptionController.text = bookData['description'] ?? '';
          _bookCoverUrl = bookData['thumbnail_url'];
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Book information loaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show message that no data was found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No book information found. Please enter manually.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to lookup book information: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
    _volunteerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewBook ? 'Add New Book' : 'Book Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (!widget.isNewBook)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editBook,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book information card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.book,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Book Information',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Book cover image
                          if (_bookCoverUrl != null) ...[
                            Center(
                              child: Container(
                                height: 200,
                                width: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _bookCoverUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.book,
                                          size: 50,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title *',
                              border: OutlineInputBorder(),
                            ),
                            enabled: widget.isNewBook,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _authorController,
                            decoration: const InputDecoration(
                              labelText: 'Author *',
                              border: OutlineInputBorder(),
                            ),
                            enabled: widget.isNewBook,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _publisherController,
                            decoration: const InputDecoration(
                              labelText: 'Publisher',
                              border: OutlineInputBorder(),
                            ),
                            enabled: widget.isNewBook,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            enabled: widget.isNewBook,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: TextEditingController(
                                text: widget.scannedBarcode),
                            decoration: const InputDecoration(
                              labelText: 'ISBN',
                              border: OutlineInputBorder(),
                            ),
                            enabled: false,
                          ),
                          if (widget.isNewBook) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _lookupBookData,
                              icon: _isLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(Icons.search),
                              label: Text(_isLoading
                                  ? 'Looking up...'
                                  : 'Lookup Book Info'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transaction type selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Type',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Donation'),
                                  subtitle:
                                      const Text('Adding books to inventory'),
                                  value: true,
                                  groupValue: _isDonation,
                                  onChanged: (value) {
                                    setState(() {
                                      _isDonation = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Sale'),
                                  subtitle: const Text(
                                      'Removing books from inventory'),
                                  value: false,
                                  groupValue: _isDonation,
                                  onChanged: (value) {
                                    setState(() {
                                      _isDonation = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transaction details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantity *',
                              border: const OutlineInputBorder(),
                              suffixText: _isDonation ? 'books' : 'books',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _volunteerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Volunteer Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _processTransaction,
                          child: Text(widget.isNewBook
                              ? 'Add Book'
                              : 'Process Transaction'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  void _editBook() {
    // TODO: Implement edit book functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  Future<void> _processTransaction() async {
    if (_titleController.text.isEmpty || _authorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<InventoryProvider>();

      if (widget.isNewBook) {
        // Create new book
        final newBook = Book(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isbn: widget.scannedBarcode,
          title: _titleController.text,
          author: _authorController.text,
          publisher: _publisherController.text.isEmpty
              ? null
              : _publisherController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          quantity: _isDonation ? quantity : 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdBook = await provider.addBook(newBook);
        if (createdBook != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Book "${createdBook.title}" added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else if (widget.book != null) {
        // Create transaction for existing book
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          bookId: widget.book!.id,
          type: _isDonation ? TransactionType.donation : TransactionType.sale,
          quantity: quantity,
          date: DateTime.now(),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          volunteerName: _volunteerNameController.text.isEmpty
              ? null
              : _volunteerNameController.text,
          createdAt: DateTime.now(),
        );

        final success = await provider.addTransaction(transaction);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction processed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
