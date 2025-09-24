import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../models/transaction.dart';
import '../models/inventory_summary.dart';

class ApiService {
  static const String baseUrl =
      'https://bookloft-api.example.com'; // Replace with actual backend URL
  static const Duration timeout = Duration(seconds: 30);

  // Book operations
  static Future<List<Book>> getAllBooks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/books'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching books: $e');
    }
  }

  static Future<Book?> getBookByIsbn(String isbn) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/books/isbn/$isbn'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return Book.fromJson(json);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load book: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching book by ISBN: $e');
    }
  }

  static Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/books/search?q=${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching books: $e');
    }
  }

  static Future<Book> createBook(Book book) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/books'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(book.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return Book.fromJson(json);
      } else {
        throw Exception('Failed to create book: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating book: $e');
    }
  }

  static Future<Book> updateBook(Book book) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/books/${book.id}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(book.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return Book.fromJson(json);
      } else {
        throw Exception('Failed to update book: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating book: $e');
    }
  }

  // Transaction operations
  static Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/transactions'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(transaction.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return Transaction.fromJson(json);
      } else {
        throw Exception('Failed to create transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  static Future<List<Transaction>> getBookTransactions(String bookId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/books/$bookId/transactions'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  // Inventory summary
  static Future<InventorySummary> getInventorySummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inventory/summary'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return InventorySummary.fromJson(json);
      } else {
        throw Exception(
            'Failed to load inventory summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching inventory summary: $e');
    }
  }

  // Enhanced ISBN lookup from multiple APIs
  static Future<Map<String, dynamic>?> lookupBookByIsbn(String isbn) async {
    // Try Open Library first
    final openLibraryData = await _lookupFromOpenLibrary(isbn);
    if (openLibraryData != null) {
      return openLibraryData;
    }

    // Fallback to Google Books API
    final googleBooksData = await _lookupFromGoogleBooks(isbn);
    if (googleBooksData != null) {
      return googleBooksData;
    }

    return null;
  }

  // Open Library API lookup
  static Future<Map<String, dynamic>?> _lookupFromOpenLibrary(
      String isbn) async {
    try {
      final response = await http.get(
        Uri.parse('https://openlibrary.org/isbn/$isbn.json'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Get additional details from work API if available
        if (data['works'] != null && data['works'].isNotEmpty) {
          final workKey = data['works'][0]['key'];
          final workResponse = await http.get(
            Uri.parse('https://openlibrary.org$workKey.json'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(timeout);

          if (workResponse.statusCode == 200) {
            final workData = jsonDecode(workResponse.body);
            data['description'] =
                workData['description']?['value'] ?? workData['description'];
          }
        }

        return _formatOpenLibraryData(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Google Books API lookup
  static Future<Map<String, dynamic>?> _lookupFromGoogleBooks(
      String isbn) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return _formatGoogleBooksData(data['items'][0]);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Format Open Library data to our standard format
  static Map<String, dynamic> _formatOpenLibraryData(
      Map<String, dynamic> data) {
    return {
      'title': data['title'] ?? '',
      'authors': data['authors']
              ?.map((author) => {'name': author['name'] ?? ''})
              .toList() ??
          [],
      'publishers': data['publishers']
              ?.map((publisher) => {'name': publisher ?? ''})
              .toList() ??
          [],
      'publish_date': data['publish_date'] ?? data['first_publish_date'] ?? '',
      'description': data['description'] ?? '',
      'thumbnail_url': data['covers'] != null && data['covers'].isNotEmpty
          ? 'https://covers.openlibrary.org/b/id/${data['covers'][0]}-M.jpg'
          : null,
      'isbn': data['isbn_13']?.first ?? data['isbn_10']?.first ?? '',
    };
  }

  // Format Google Books data to our standard format
  static Map<String, dynamic> _formatGoogleBooksData(
      Map<String, dynamic> data) {
    final volumeInfo = data['volumeInfo'] ?? {};
    return {
      'title': volumeInfo['title'] ?? '',
      'authors': volumeInfo['authors']
              ?.map((author) => {'name': author ?? ''})
              .toList() ??
          [],
      'publishers': volumeInfo['publisher'] != null
          ? [
              {'name': volumeInfo['publisher']}
            ]
          : [],
      'publish_date': volumeInfo['publishedDate'] ?? '',
      'description': volumeInfo['description'] ?? '',
      'thumbnail_url': volumeInfo['imageLinks']?['thumbnail'] ??
          volumeInfo['imageLinks']?['smallThumbnail'],
      'isbn': volumeInfo['industryIdentifiers']?.firstWhere(
              (id) => id['type'] == 'ISBN_13' || id['type'] == 'ISBN_10',
              orElse: () => {'identifier': ''})['identifier'] ??
          '',
    };
  }
}
