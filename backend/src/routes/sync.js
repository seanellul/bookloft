const express = require('express');
const Joi = require('joi');
const { db } = require('../database/connection');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const syncUploadSchema = Joi.object({
  books: Joi.array().items(Joi.object({
    id: Joi.string().required(),
    isbn: Joi.string().required(),
    title: Joi.string().required(),
    author: Joi.string().required(),
    publisher: Joi.string().optional(),
    published_date: Joi.date().optional(),
    description: Joi.string().optional(),
    thumbnail_url: Joi.string().optional(),
    quantity: Joi.number().integer().min(0).required(),
    created_at: Joi.date().required(),
    updated_at: Joi.date().required()
  })).optional(),
  transactions: Joi.array().items(Joi.object({
    id: Joi.string().required(),
    book_id: Joi.string().required(),
    type: Joi.string().valid('donation', 'sale').required(),
    quantity: Joi.number().integer().min(1).required(),
    date: Joi.date().required(),
    volunteer_name: Joi.string().optional(),
    notes: Joi.string().optional(),
    created_at: Joi.date().required()
  })).optional(),
  last_sync: Joi.date().required()
});

// POST /api/sync/upload - Upload offline changes
router.post('/upload', authenticateToken, async (req, res, next) => {
  try {
    const { error, value } = syncUploadSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.details[0].message }
      });
    }

    const { books = [], transactions = [], last_sync } = value;
    const results = {
      books_processed: 0,
      transactions_processed: 0,
      errors: []
    };

    // Process books
    for (const book of books) {
      try {
        await db('books')
          .insert(book)
          .onConflict('id')
          .merge(['title', 'author', 'publisher', 'published_date', 'description', 'thumbnail_url', 'quantity', 'updated_at']);
        
        results.books_processed++;
      } catch (error) {
        results.errors.push(`Book ${book.id}: ${error.message}`);
      }
    }

    // Process transactions
    for (const transaction of transactions) {
      try {
        await db('transactions')
          .insert(transaction)
          .onConflict('id')
          .ignore();
        
        results.transactions_processed++;
      } catch (error) {
        results.errors.push(`Transaction ${transaction.id}: ${error.message}`);
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

// GET /api/sync/download - Download changes since last sync
router.get('/download', authenticateToken, async (req, res, next) => {
  try {
    const { since } = req.query;
    
    if (!since) {
      return res.status(400).json({
        success: false,
        error: { message: 'since parameter is required' }
      });
    }

    const sinceDate = new Date(since);
    if (isNaN(sinceDate.getTime())) {
      return res.status(400).json({
        success: false,
        error: { message: 'Invalid since date format' }
      });
    }

    // Get updated books
    const books = await db('books')
      .where('updated_at', '>', sinceDate)
      .orderBy('updated_at', 'asc');

    // Get new transactions
    const transactions = await db('transactions')
      .where('created_at', '>', sinceDate)
      .orderBy('created_at', 'asc');

    res.json({
      success: true,
      data: {
        books,
        transactions,
        sync_timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/sync/status - Get sync status
router.get('/status', authenticateToken, async (req, res, next) => {
  try {
    // Get counts
    const [{ total_books }] = await db('books').count('* as total_books');
    const [{ total_transactions }] = await db('transactions').count('* as total_transactions');
    
    // Get last update times
    const [{ last_book_update }] = await db('books')
      .max('updated_at as last_book_update');
    
    const [{ last_transaction }] = await db('transactions')
      .max('created_at as last_transaction');

    res.json({
      success: true,
      data: {
        total_books: parseInt(total_books),
        total_transactions: parseInt(total_transactions),
        last_book_update: last_book_update,
        last_transaction: last_transaction,
        server_time: new Date().toISOString()
      }
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
