const express = require('express');
const Joi = require('joi');
const { db } = require('../database/connection');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const transactionSchema = Joi.object({
  book_id: Joi.string().uuid().required(),
  type: Joi.string().valid('donation', 'sale').required(),
  quantity: Joi.number().integer().min(1).required(),
  date: Joi.date().default(() => new Date()),
  volunteer_name: Joi.string().max(255).optional(),
  notes: Joi.string().optional()
});

// GET /api/transactions - Get all transactions with filtering
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const {
      book_id,
      type,
      volunteer_name,
      date_from,
      date_to,
      page = 1,
      limit = 50
    } = req.query;

    const offset = (page - 1) * limit;
    let query = db('transactions')
      .join('books', 'transactions.book_id', 'books.id')
      .select(
        'transactions.*',
        'books.title',
        'books.author',
        'books.isbn'
      );

    // Apply filters
    if (book_id) query = query.where('transactions.book_id', book_id);
    if (type) query = query.where('transactions.type', type);
    if (volunteer_name) query = query.where('transactions.volunteer_name', 'ilike', `%${volunteer_name}%`);
    if (date_from) query = query.where('transactions.date', '>=', date_from);
    if (date_to) query = query.where('transactions.date', '<=', date_to);

    // Get total count
    const totalQuery = query.clone();
    const [{ count }] = await totalQuery.count('* as count');

    // Get transactions with pagination
    const transactions = await query
      .orderBy('transactions.date', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset));

    res.json({
      success: true,
      data: {
        transactions,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(count),
          pages: Math.ceil(count / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/transactions/:id - Get transaction by ID
router.get('/:id', authenticateToken, async (req, res, next) => {
  try {
    const transaction = await db('transactions')
      .join('books', 'transactions.book_id', 'books.id')
      .select(
        'transactions.*',
        'books.title',
        'books.author',
        'books.isbn'
      )
      .where('transactions.id', req.params.id)
      .first();

    if (!transaction) {
      return res.status(404).json({
        success: false,
        error: { message: 'Transaction not found' }
      });
    }

    res.json({
      success: true,
      data: transaction
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/transactions - Create new transaction
router.post('/', process.env.NODE_ENV === 'development' ? (req, res, next) => next() : authenticateToken, async (req, res, next) => {
  try {
    const { error, value } = transactionSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.details[0].message }
      });
    }

    // Check if book exists
    const book = await db('books').where({ id: value.book_id }).first();
    if (!book) {
      return res.status(404).json({
        success: false,
        error: { message: 'Book not found' }
      });
    }

    // Check if sale quantity is available
    if (value.type === 'sale' && book.quantity < value.quantity) {
      return res.status(400).json({
        success: false,
        error: { message: 'Insufficient quantity available' }
      });
    }

    // Start transaction
    const trx = await db.transaction();

    try {
      // Create transaction record
      const [transaction] = await trx('transactions')
        .insert({
          ...value,
          volunteer_name: value.volunteer_name || req.volunteer.name,
          created_at: new Date()
        })
        .returning('*');

      // Update book quantity
      const quantityChange = value.type === 'donation' ? value.quantity : -value.quantity;
      await trx('books')
        .where({ id: value.book_id })
        .increment('quantity', quantityChange)
        .update({ updated_at: new Date() });

      await trx.commit();

      res.status(201).json({
        success: true,
        data: transaction
      });
    } catch (error) {
      await trx.rollback();
      throw error;
    }
  } catch (error) {
    next(error);
  }
});

// GET /api/books/:book_id/transactions - Get transactions for a specific book
router.get('/books/:book_id/transactions', process.env.NODE_ENV === 'development' ? (req, res, next) => next() : authenticateToken, async (req, res, next) => {
  try {
    const transactions = await db('transactions')
      .where({ book_id: req.params.book_id })
      .orderBy('date', 'desc');

    res.json({
      success: true,
      data: transactions
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
