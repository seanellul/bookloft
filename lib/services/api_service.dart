import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../models/transaction.dart';
import '../models/inventory_summary.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl =
      'http://localhost:3000/api'; // Local development backend
  static const Duration timeout = Duration(seconds: 30);

  // Book operations
  static Future<List<Book>> getAllBooks() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/books'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> jsonList =
              responseData['data']['books'] ?? responseData['data'];
          return jsonList.map((json) => Book.fromJson(json)).toList();
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching books: $e');
    }
  }

  static Future<Book?> getBookByIsbn(String isbn) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/books/isbn/$isbn'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Book.fromJson(responseData['data']);
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
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
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/books/search?q=${Uri.encodeComponent(query)}'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> jsonList =
              responseData['data']['books'] ?? responseData['data'];
          return jsonList.map((json) => Book.fromJson(json)).toList();
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to search books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching books: $e');
    }
  }

  static Future<Book> createBook(Book book) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/books'),
            headers: headers,
            body: json.encode(book.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Book.fromJson(responseData['data']);
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to create book: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating book: $e');
    }
  }

  static Future<Book> updateBook(Book book) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/books/${book.id}'),
            headers: headers,
            body: json.encode(book.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Book.fromJson(responseData['data']);
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
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
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/transactions'),
            headers: headers,
            body: json.encode(transaction.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Transaction.fromJson(responseData['data']);
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to create transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  static Future<List<Transaction>> getBookTransactions(String bookId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/books/$bookId/transactions'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> jsonList =
              responseData['data']['transactions'] ?? responseData['data'];
          return jsonList.map((json) => Transaction.fromJson(json)).toList();
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
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
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/inventory/summary'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return InventorySummary.fromJson(responseData['data']);
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
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
    final result = {
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
      // New metadata fields
      'binding': _extractBinding(data),
      'isbn_10': data['isbn_10']?.first,
      'language':
          data['languages']?.first?['key']?.replaceAll('/languages/', ''),
      'page_count': data['number_of_pages']?.toString(),
      'dimensions': _extractDimensions(data),
      'weight': data['weight'],
      'edition': data['edition_name'],
      'series': data['series']?.first,
      'subtitle': data['subtitle'],
      'categories': _extractCategories(data),
      'tags': _extractTags(data),
      'maturity_rating': data['maturity_rating'],
      'format': _extractFormat(data),
    };
    print('Open Library API result: $result'); // Debug
    return result;
  }

  // Format Google Books data to our standard format
  static Map<String, dynamic> _formatGoogleBooksData(
      Map<String, dynamic> data) {
    final volumeInfo = data['volumeInfo'] ?? {};
    final result = {
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
      // New metadata fields
      'binding': _extractBindingFromGoogle(volumeInfo),
      'isbn_10': _extractIsbn10(volumeInfo),
      'language': volumeInfo['language'],
      'page_count': volumeInfo['pageCount']?.toString(),
      'dimensions': _extractDimensionsFromGoogle(volumeInfo),
      'weight': _extractWeightFromGoogle(volumeInfo),
      'edition': volumeInfo['edition'],
      'series': _extractSeriesFromGoogle(volumeInfo),
      'subtitle': volumeInfo['subtitle'],
      'categories': _extractCategoriesFromGoogle(volumeInfo),
      'tags': _extractTagsFromGoogle(volumeInfo),
      'maturity_rating': volumeInfo['maturityRating'],
      'format': _extractFormatFromGoogle(volumeInfo),
    };
    print('Google Books API result: $result'); // Debug
    return result;
  }

  // Helper methods for extracting metadata from Open Library
  static String? _extractBinding(Map<String, dynamic> data) {
    // Open Library doesn't always have binding info, but we can infer from other fields
    return null; // Will be populated by Google Books if available
  }

  static String? _extractDimensions(Map<String, dynamic> data) {
    // Open Library doesn't typically have dimensions
    return null;
  }

  static String? _extractCategories(Map<String, dynamic> data) {
    final subjects = data['subjects'] as List?;
    if (subjects != null && subjects.isNotEmpty) {
      return subjects.take(5).join(', '); // Limit to 5 categories
    }
    return null;
  }

  static String? _extractTags(Map<String, dynamic> data) {
    final subjects = data['subjects'] as List?;
    if (subjects != null && subjects.isNotEmpty) {
      return subjects.take(10).join(', '); // Limit to 10 tags
    }
    return null;
  }

  static String? _extractFormat(Map<String, dynamic> data) {
    // Open Library doesn't typically have format info
    return null;
  }

  // Helper methods for extracting metadata from Google Books
  static String? _extractBindingFromGoogle(Map<String, dynamic> volumeInfo) {
    // Google Books sometimes has binding info in printType
    final printType = volumeInfo['printType'];
    if (printType == 'BOOK') {
      // Could be hardback or paperback, but Google Books doesn't always specify
      return 'book'; // Generic book format
    }
    return printType?.toLowerCase();
  }

  static String? _extractIsbn10(Map<String, dynamic> volumeInfo) {
    final identifiers = volumeInfo['industryIdentifiers'] as List?;
    if (identifiers != null) {
      for (final id in identifiers) {
        if (id['type'] == 'ISBN_10') {
          return id['identifier'];
        }
      }
    }
    return null;
  }

  static String? _extractDimensionsFromGoogle(Map<String, dynamic> volumeInfo) {
    // Google Books doesn't typically provide dimensions
    return null;
  }

  static String? _extractWeightFromGoogle(Map<String, dynamic> volumeInfo) {
    // Google Books doesn't typically provide weight
    return null;
  }

  static String? _extractSeriesFromGoogle(Map<String, dynamic> volumeInfo) {
    // Google Books doesn't typically provide series info
    return null;
  }

  static String? _extractCategoriesFromGoogle(Map<String, dynamic> volumeInfo) {
    final categories = volumeInfo['categories'] as List?;
    if (categories != null && categories.isNotEmpty) {
      return categories.take(5).join(', '); // Limit to 5 categories
    }
    return null;
  }

  static String? _extractTagsFromGoogle(Map<String, dynamic> volumeInfo) {
    final categories = volumeInfo['categories'] as List?;
    if (categories != null && categories.isNotEmpty) {
      return categories.take(10).join(', '); // Limit to 10 tags
    }
    return null;
  }

  static String? _extractFormatFromGoogle(Map<String, dynamic> volumeInfo) {
    final printType = volumeInfo['printType'];
    if (printType != null) {
      return printType.toLowerCase();
    }
    return null;
  }
}
