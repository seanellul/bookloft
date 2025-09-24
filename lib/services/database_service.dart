import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import '../models/book.dart';
import '../models/transaction.dart';
import '../models/inventory_summary.dart';

class DatabaseService {
  static sqflite.Database? _database;
  static const String _databaseName = 'bookloft.db';
  static const int _databaseVersion = 1;

  static Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<sqflite.Database> _initDatabase() async {
    String path = join(await sqflite.getDatabasesPath(), _databaseName);
    return await sqflite.openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(sqflite.Database db, int version) async {
    // Create books table
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        isbn TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        publisher TEXT,
        published_date TEXT,
        description TEXT,
        thumbnail_url TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        volunteer_name TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_books_isbn ON books (isbn)');
    await db.execute('CREATE INDEX idx_books_title ON books (title)');
    await db.execute('CREATE INDEX idx_books_author ON books (author)');
    await db.execute(
        'CREATE INDEX idx_transactions_book_id ON transactions (book_id)');
    await db
        .execute('CREATE INDEX idx_transactions_date ON transactions (date)');
  }

  // Book operations
  static Future<void> insertBook(Book book) async {
    final db = await database;
    await db.insert(
      'books',
      book.toJson(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Book>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('books', orderBy: 'title ASC');
    return List.generate(maps.length, (i) => Book.fromJson(maps[i]));
  }

  static Future<Book?> getBookById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Book.fromJson(maps.first);
    }
    return null;
  }

  static Future<Book?> getBookByIsbn(String isbn) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'isbn = ?',
      whereArgs: [isbn],
    );
    if (maps.isNotEmpty) {
      return Book.fromJson(maps.first);
    }
    return null;
  }

  static Future<List<Book>> searchBooks(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'title LIKE ? OR author LIKE ? OR isbn LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'title ASC',
    );
    return List.generate(maps.length, (i) => Book.fromJson(maps[i]));
  }

  static Future<void> updateBook(Book book) async {
    final db = await database;
    await db.update(
      'books',
      book.toJson(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  static Future<void> deleteBook(String id) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // Transaction operations
  static Future<void> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toJson());
  }

  static Future<List<Transaction>> getBookTransactions(String bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromJson(maps[i]));
  }

  static Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromJson(maps[i]));
  }

  // Inventory summary
  static Future<InventorySummary> getInventorySummary() async {
    final db = await database;

    // Get total books count
    final totalBooksResult =
        await db.rawQuery('SELECT COUNT(*) as count FROM books');
    final totalBooks = totalBooksResult.first['count'] as int;

    // Get total quantity
    final totalQuantityResult =
        await db.rawQuery('SELECT SUM(quantity) as total FROM books');
    final totalQuantity = totalQuantityResult.first['total'] as int? ?? 0;

    // Get available books (quantity > 0)
    final availableBooksResult = await db
        .rawQuery('SELECT COUNT(*) as count FROM books WHERE quantity > 0');
    final availableBooks = availableBooksResult.first['count'] as int;

    // Get books with multiple copies
    final multipleCopiesResult = await db
        .rawQuery('SELECT COUNT(*) as count FROM books WHERE quantity > 1');
    final booksWithMultipleCopies = multipleCopiesResult.first['count'] as int;

    // Get total donations
    final donationsResult = await db.rawQuery(
        'SELECT SUM(quantity) as total FROM transactions WHERE type = ?',
        ['donation']);
    final totalDonations = donationsResult.first['total'] as int? ?? 0;

    // Get total sales
    final salesResult = await db.rawQuery(
        'SELECT SUM(quantity) as total FROM transactions WHERE type = ?',
        ['sale']);
    final totalSales = salesResult.first['total'] as int? ?? 0;

    return InventorySummary(
      totalBooks: totalBooks,
      totalQuantity: totalQuantity,
      availableBooks: availableBooks,
      booksWithMultipleCopies: booksWithMultipleCopies,
      totalDonations: totalDonations,
      totalSales: totalSales,
      lastUpdated: DateTime.now(),
    );
  }

  // Sync operations for offline support
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('books');
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
