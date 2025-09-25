const express = require('express');
const { db } = require('../database/connection');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// POST /api/admin/fix-null-ids - Fix books and transactions with null IDs
router.post('/fix-null-ids', authenticateToken, async (req, res, next) => {
  try {
    const results = {
      books_fixed: 0,
      transactions_fixed: 0,
      errors: []
    };

    // Fix books with null IDs
    const booksWithNullIds = await db('books').whereNull('id');
    
    for (const book of booksWithNullIds) {
      try {
        const newId = Date.now().toString() + Math.random().toString(36).substr(2, 9);
        await db('books')
          .where('isbn', book.isbn)
          .where('created_at', book.created_at)
          .update({ id: newId });
        results.books_fixed++;
      } catch (error) {
        results.errors.push(`Book ${book.title}: ${error.message}`);
      }
    }
    
    // Fix transactions with null IDs
    const transactionsWithNullIds = await db('transactions').whereNull('id');
    
    for (const transaction of transactionsWithNullIds) {
      try {
        const newId = Date.now().toString() + Math.random().toString(36).substr(2, 9);
        await db('transactions')
          .where('book_id', transaction.book_id)
          .where('created_at', transaction.created_at)
          .update({ id: newId });
        results.transactions_fixed++;
      } catch (error) {
        results.errors.push(`Transaction: ${error.message}`);
      }
    }

    res.json({
      success: true,
      data: results
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/admin/reset-database - Clear all books and transactions (for testing)
router.post('/reset-database', authenticateToken, async (req, res, next) => {
  try {
    // Delete all transactions first (foreign key constraint)
    const deletedTransactions = await db('transactions').del();
    
    // Then delete all books
    const deletedBooks = await db('books').del();

    res.json({
      success: true,
      data: {
        message: 'Database reset successfully',
        deleted_transactions: deletedTransactions,
        deleted_books: deletedBooks
      }
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
