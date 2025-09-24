const express = require('express');
const { db } = require('../database/connection');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/inventory/summary - Get inventory summary statistics
router.get('/summary', process.env.NODE_ENV === 'development' ? (req, res, next) => next() : authenticateToken, async (req, res, next) => {
  try {
    // Get total books count
    const [{ total_books }] = await db('books').count('* as total_books');

    // Get total quantity
    const [{ total_quantity }] = await db('books').sum('quantity as total_quantity');

    // Get available books (quantity > 0)
    const [{ available_books }] = await db('books')
      .where('quantity', '>', 0)
      .count('* as available_books');

    // Get books with multiple copies
    const [{ books_with_multiple_copies }] = await db('books')
      .where('quantity', '>', 1)
      .count('* as books_with_multiple_copies');

    // Get total donations
    const [{ total_donations }] = await db('transactions')
      .where('type', 'donation')
      .sum('quantity as total_donations');

    // Get total sales
    const [{ total_sales }] = await db('transactions')
      .where('type', 'sale')
      .sum('quantity as total_sales');

    const summary = {
      total_books: parseInt(total_books) || 0,
      total_quantity: parseInt(total_quantity) || 0,
      available_books: parseInt(available_books) || 0,
      books_with_multiple_copies: parseInt(books_with_multiple_copies) || 0,
      total_donations: parseInt(total_donations) || 0,
      total_sales: parseInt(total_sales) || 0,
      last_updated: new Date().toISOString()
    };

    // Calculate sales rate
    const total_transactions = summary.total_donations + summary.total_sales;
    summary.sales_rate = total_transactions > 0 
      ? ((summary.total_sales / total_transactions) * 100).toFixed(1)
      : 0;

    res.json({
      success: true,
      data: summary
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/inventory/books/multiple-copies - Get books with multiple copies
router.get('/books/multiple-copies', authenticateToken, async (req, res, next) => {
  try {
    const books = await db('books')
      .where('quantity', '>', 1)
      .orderBy('quantity', 'desc')
      .orderBy('title', 'asc');

    res.json({
      success: true,
      data: books
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/inventory/books/out-of-stock - Get out of stock books
router.get('/books/out-of-stock', authenticateToken, async (req, res, next) => {
  try {
    const books = await db('books')
      .where('quantity', 0)
      .orderBy('title', 'asc');

    res.json({
      success: true,
      data: books
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/inventory/analytics - Get detailed analytics
router.get('/analytics', authenticateToken, async (req, res, next) => {
  try {
    const { period = '30' } = req.query; // days
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    // Recent transactions
    const recentTransactions = await db('transactions')
      .join('books', 'transactions.book_id', 'books.id')
      .select(
        'transactions.*',
        'books.title',
        'books.author'
      )
      .where('transactions.date', '>=', startDate)
      .orderBy('transactions.date', 'desc')
      .limit(20);

    // Top selling books
    const topSellingBooks = await db('transactions')
      .join('books', 'transactions.book_id', 'books.id')
      .select(
        'books.id',
        'books.title',
        'books.author',
        'books.isbn'
      )
      .sum('transactions.quantity as total_sold')
      .where('transactions.type', 'sale')
      .where('transactions.date', '>=', startDate)
      .groupBy('books.id', 'books.title', 'books.author', 'books.isbn')
      .orderBy('total_sold', 'desc')
      .limit(10);

    // Daily transaction counts
    const dailyStats = await db('transactions')
      .select(
        db.raw('DATE(date) as date'),
        db.raw('SUM(CASE WHEN type = \'donation\' THEN quantity ELSE 0 END) as donations'),
        db.raw('SUM(CASE WHEN type = \'sale\' THEN quantity ELSE 0 END) as sales')
      )
      .where('date', '>=', startDate)
      .groupBy(db.raw('DATE(date)'))
      .orderBy('date', 'desc');

    res.json({
      success: true,
      data: {
        recent_transactions: recentTransactions,
        top_selling_books: topSellingBooks,
        daily_stats: dailyStats,
        period_days: parseInt(period)
      }
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
