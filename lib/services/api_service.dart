import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../models/transaction.dart';
import '../models/inventory_summary.dart';
import '../models/transaction_analytics.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl =
      'https://web-production-0001.up.railway.app/api';
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
          return jsonList
              .map((json) => Book.fromSafeJson(json as Map<String, dynamic>))
              .toList();
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
          return Book.fromSafeJson(responseData['data']);
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
            Uri.parse('$baseUrl/books?search=${Uri.encodeComponent(query)}'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> jsonList =
              responseData['data']['books'] ?? responseData['data'];
          return jsonList
              .map((json) => Book.fromSafeJson(json as Map<String, dynamic>))
              .toList();
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
          return Book.fromSafeJson(responseData['data']);
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
          return Book.fromSafeJson(responseData['data']);
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 404) {
        // Fallback: try to find the book on server by ISBN and update that ID
        try {
          final serverBook = await getBookByIsbn(book.isbn);
          if (serverBook != null) {
            final retry = await http
                .put(
                  Uri.parse('$baseUrl/books/${serverBook.id}'),
                  headers: headers,
                  body: json.encode(book.copyWith(id: serverBook.id).toJson()),
                )
                .timeout(timeout);
            if (retry.statusCode == 200) {
              final Map<String, dynamic> retryData = jsonDecode(retry.body);
              if (retryData['success'] == true && retryData['data'] != null) {
                return Book.fromJson(retryData['data']);
              }
            }
          }
          // If not found by ISBN, create it
          return await createBook(book);
        } catch (e) {
          throw Exception('Failed to update book (after 404): $e');
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

  // Admin utilities
  static Future<void> resetDatabase() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/reset-database'),
          headers: headers,
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to reset database: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> fixNullIds() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/fix-null-ids'),
          headers: headers,
        )
        .timeout(timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fix null IDs: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> getBookTransactions(String bookId) async {
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
          return responseData[
              'data']; // Returns both transactions and analytics
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

  // Ensure a book exists on the server; if missing, create it and return the server copy
  static Future<Book> ensureServerBook(Book localBook) async {
    final existing = await getBookByIsbn(localBook.isbn);
    if (existing != null) return existing;
    return await createBook(localBook);
  }

  // Resolve author names from Open Library author keys
  static Future<void> _resolveAuthorNames(Map<String, dynamic> data) async {
    if (data['authors'] == null || data['authors'] is! List) return;

    final List<dynamic> authors = data['authors'];
    final List<Map<String, dynamic>> resolvedAuthors = [];

    print('=== RESOLVING AUTHORS DEBUG ===');
    print('Input authors: $authors');

    for (var author in authors) {
      try {
        String? authorName;

        if (author is Map) {
          print('Processing author map: $author');
          // Check if we already have a name
          if (author['name'] != null &&
              author['name'].toString().isNotEmpty &&
              !author['name'].toString().startsWith('/authors/')) {
            authorName = author['name'].toString();
            print('Found existing name: $authorName');
          }
          // If name is empty or we have a key that looks like an author reference
          else if (author['key'] != null &&
              author['key'].toString().startsWith('/authors/')) {
            print('Resolving author key: ${author['key']}');
            authorName = await _fetchAuthorName(author['key'].toString());
            print('Resolved to: $authorName');
          }
        } else if (author is String) {
          print('Processing author string: $author');
          // If it's a string that looks like an author key
          if (author.startsWith('/authors/')) {
            print('Resolving author key string: $author');
            authorName = await _fetchAuthorName(author);
            print('Resolved to: $authorName');
          } else {
            authorName = author;
            print('Using author string as-is: $authorName');
          }
        }

        // Add resolved author name
        if (authorName != null && authorName.isNotEmpty) {
          resolvedAuthors.add({'name': authorName});
        }
      } catch (e) {
        print('Error resolving author: $e');
        // If we can't resolve, keep whatever we have
        if (author is Map && author['name'] != null) {
          resolvedAuthors.add({'name': author['name'].toString()});
        } else if (author is String) {
          resolvedAuthors.add({'name': author});
        }
      }
    }

    print('Final resolved authors: $resolvedAuthors');
    print('=== END RESOLVING AUTHORS DEBUG ===');

    // Update the data with resolved author names
    data['authors'] = resolvedAuthors;
  }

  // Fetch author name from Open Library author API
  static Future<String?> _fetchAuthorName(String authorKey) async {
    try {
      // Remove leading slash if present and construct the API URL
      final cleanKey =
          authorKey.startsWith('/') ? authorKey.substring(1) : authorKey;
      final url = 'https://openlibrary.org/$cleanKey.json';
      print('Fetching author data from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final authorData = jsonDecode(response.body);
        print('Author API response: $authorData');
        final name = authorData['name'] ?? authorData['personal_name'];
        print('Extracted author name: $name');
        return name;
      } else {
        print('Author API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching author name for $authorKey: $e');
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

        // Resolve author names from author keys
        await _resolveAuthorNames(data);

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
    // Process authors (should already be resolved at this point)
    List<Map<String, String>> authors = [];
    print('=== OPEN LIBRARY AUTHORS DEBUG ===');
    print('Raw authors data: ${data['authors']}');
    print('Authors type: ${data['authors'].runtimeType}');

    if (data['authors'] != null && data['authors'] is List) {
      for (var author in data['authors']) {
        print('Processing author: $author (type: ${author.runtimeType})');
        if (author is Map && author['name'] != null) {
          final name = author['name'].toString();
          print('Extracted name: "$name"');
          authors.add({'name': name});
        } else if (author is String) {
          print('Author is string: "$author"');
          authors.add({'name': author});
        }
      }
    }
    print('Final authors array: $authors');
    print('=== END AUTHORS DEBUG ===');

    final result = {
      'title': data['title'] ?? '',
      'authors': authors,
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

  // Time-based transaction analytics
  static Future<TimeBasedAnalytics> getTimeBasedAnalytics() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/transactions/analytics/time-based'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return TimeBasedAnalytics.fromJson(responseData['data']);
        } else {
          throw Exception(
              'API returned error: ${responseData['error']?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }

  // Get all transactions for general transaction log
  static Future<List<Transaction>> getAllTransactions({
    int page = 1,
    int limit = 50,
    String? type,
    String? volunteerName,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (type != null) queryParams['type'] = type;
      if (volunteerName != null) queryParams['volunteer_name'] = volunteerName;

      final uri = Uri.parse('$baseUrl/transactions')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(timeout);

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
}
