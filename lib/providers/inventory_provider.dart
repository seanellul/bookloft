import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/transaction.dart';
import '../models/inventory_summary.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class InventoryProvider with ChangeNotifier {
  List<Book> _books = [];
  List<Transaction> _transactions = [];
  InventorySummary? _summary;
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;

  // Getters
  List<Book> get books => _books;
  List<Transaction> get transactions => _transactions;
  InventorySummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;

  List<Book> get availableBooks =>
      _books.where((book) => book.isAvailable).toList();
  List<Book> get booksWithMultipleCopies =>
      _books.where((book) => book.hasMultipleCopies).toList();

  // Initialize the provider
  Future<void> initialize() async {
    await _checkConnectionStatus();
    await loadBooks();
    await loadSummary();
  }

  // Check connection status and authentication
  Future<void> _checkConnectionStatus() async {
    try {
      // Try a simple API call to check connection
      await ApiService.getAllBooks();
      _isOffline = false;
      _clearError();
    } catch (e) {
      // Check if it's an authentication error
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        // Authentication failed - logout user
        await AuthService.logout();
        _setError('Session expired. Please login again.');
      } else {
        // Network error - go offline
        _isOffline = true;
        _setError('No internet connection. Working offline.');
      }
    }
  }

  // Reset offline status (call when connection is restored)
  void resetOfflineStatus() {
    _isOffline = false;
    _clearError();
    notifyListeners();
  }

  // Load all books
  Future<void> loadBooks() async {
    _setLoading(true);
    try {
      if (_isOffline) {
        _books = await DatabaseService.getAllBooks();
      } else {
        try {
          _books = await ApiService.getAllBooks();
          // Sync to local database
          for (final book in _books) {
            await DatabaseService.insertBook(book);
          }
        } catch (e) {
          // Check if it's an authentication error
          if (e.toString().contains('401') ||
              e.toString().contains('Unauthorized')) {
            await AuthService.logout();
            _setError('Session expired. Please login again.');
            return;
          }
          // Fallback to local database if API fails
          _books = await DatabaseService.getAllBooks();
          _isOffline = true;
        }
      }
      _clearError();
    } catch (e) {
      _setError('Failed to load books: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Search books
  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return _books;

    try {
      if (_isOffline) {
        return await DatabaseService.searchBooks(query);
      } else {
        try {
          return await ApiService.searchBooks(query);
        } catch (e) {
          // Fallback to local search
          return await DatabaseService.searchBooks(query);
        }
      }
    } catch (e) {
      _setError('Search failed: $e');
      return [];
    }
  }

  // Get book by ISBN
  Future<Book?> getBookByIsbn(String isbn) async {
    try {
      if (_isOffline) {
        return await DatabaseService.getBookByIsbn(isbn);
      } else {
        try {
          return await ApiService.getBookByIsbn(isbn);
        } catch (e) {
          // Fallback to local database
          return await DatabaseService.getBookByIsbn(isbn);
        }
      }
    } catch (e) {
      _setError('Failed to get book by ISBN: $e');
      return null;
    }
  }

  // Add new book
  Future<Book?> addBook(Book book) async {
    try {
      Book? newBook;
      if (_isOffline) {
        await DatabaseService.insertBook(book);
        newBook = book;
      } else {
        try {
          newBook = await ApiService.createBook(book);
          await DatabaseService.insertBook(newBook);
        } catch (e) {
          // Save locally if API fails
          await DatabaseService.insertBook(book);
          newBook = book;
          _isOffline = true;
        }
      }

      _books.add(newBook);
      notifyListeners();
      await loadSummary();
      return newBook;
    } catch (e) {
      _setError('Failed to add book: $e');
      return null;
    }
  }

  // Update book
  Future<bool> updateBook(Book book) async {
    try {
      if (_isOffline) {
        await DatabaseService.updateBook(book);
      } else {
        try {
          final updatedBook = await ApiService.updateBook(book);
          await DatabaseService.updateBook(updatedBook);
        } catch (e) {
          // Update locally if API fails
          await DatabaseService.updateBook(book);
          _isOffline = true;
        }
      }

      final index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _books[index] = book;
        notifyListeners();
        await loadSummary();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update book: $e');
      return false;
    }
  }

  // Add transaction (donation or sale)
  Future<bool> addTransaction(Transaction transaction) async {
    try {
      if (_isOffline) {
        await DatabaseService.insertTransaction(transaction);
      } else {
        try {
          await ApiService.createTransaction(transaction);
          await DatabaseService.insertTransaction(transaction);
        } catch (e) {
          // Save locally if API fails
          await DatabaseService.insertTransaction(transaction);
          _isOffline = true;
        }
      }

      _transactions.add(transaction);

      // Update book quantity
      final bookIndex = _books.indexWhere((b) => b.id == transaction.bookId);
      if (bookIndex != -1) {
        final book = _books[bookIndex];
        final newQuantity = transaction.isDonation
            ? book.quantity + transaction.quantity
            : book.quantity - transaction.quantity;

        final updatedBook = book.copyWith(
          quantity: newQuantity,
          updatedAt: DateTime.now(),
        );

        _books[bookIndex] = updatedBook;
        await updateBook(updatedBook);
      }

      notifyListeners();
      await loadSummary();
      return true;
    } catch (e) {
      _setError('Failed to add transaction: $e');
      return false;
    }
  }

  // Load inventory summary
  Future<void> loadSummary() async {
    try {
      if (_isOffline) {
        _summary = await DatabaseService.getInventorySummary();
      } else {
        try {
          _summary = await ApiService.getInventorySummary();
        } catch (e) {
          // Fallback to local summary
          _summary = await DatabaseService.getInventorySummary();
        }
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load summary: $e');
    }
  }

  // Load book transactions
  Future<Object> getBookTransactions(String bookId) async {
    try {
      if (_isOffline) {
        return await DatabaseService.getBookTransactions(bookId);
      } else {
        try {
          final transactions = await ApiService.getBookTransactions(bookId);
          return transactions;
        } catch (e) {
          // Fallback to local database
          final transactions =
              await DatabaseService.getBookTransactions(bookId);
          return transactions;
        }
      }
    } catch (e) {
      _setError('Failed to load transactions: $e');
      return [];
    }
  }

  // Check connection and sync with server
  Future<void> checkConnectionAndSync() async {
    await _checkConnectionStatus();
    if (!_isOffline) {
      await loadBooks();
      await loadSummary();
    }
  }

  // Sync with server (when connection is restored)
  Future<void> syncWithServer() async {
    if (_isOffline) {
      // TODO: Implement sync logic to upload local changes to server
      _isOffline = false;
      await loadBooks();
      await loadSummary();
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
