const express = require('express');
const Joi = require('joi');
const { db } = require('../database/connection');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const transactionSchema = Joi.object({
  book_id: Joi.string().required(), // Accept any string ID (not just UUID)
  type: Joi.string().valid('donation', 'sale').required(),
  quantity: Joi.number().integer().min(1).required(),
  date: Joi.alternatives().try(
    Joi.date(),
    Joi.string(),
    Joi.number()
  ).default(() => new Date()),
  volunteer_name: Joi.string().allow('', null).max(255).optional(),
  notes: Joi.string().allow('', null).optional(),
  
}).options({ stripUnknown: true }); // Remove unknown fields

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
    if (volunteer_name) query = query.where('transactions.volunteer_name', 'like', `%${volunteer_name}%`);
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
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    // Remove fields that the backend should control
    const cleanedBody = { ...req.body };
    delete cleanedBody.id;
    delete cleanedBody.created_at;
    
    const { error, value } = transactionSchema.validate(cleanedBody);
    if (error) {
      console.log('Transaction creation validation error:', error.details[0].message);
      console.log('Cleaned request body:', JSON.stringify(cleanedBody, null, 2));
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
      // Generate unique ID for transaction
      const transactionId = Date.now().toString();
      
      // Create transaction record
      const [transaction] = await trx('transactions')
        .insert({
          id: transactionId,
          ...value,
          volunteer_name: req.volunteer.name, // Always use authenticated user's name
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

// GET /api/transactions/analytics/time-based - Get time-based transaction analytics
router.get('/analytics/time-based', authenticateToken, async (req, res, next) => {
  try {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekStart = new Date(todayStart.getTime() - (todayStart.getDay() * 24 * 60 * 60 * 1000));
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const yearStart = new Date(now.getFullYear(), 0, 1);

    // Get transactions for different time periods
    const [todayTransactions, weekTransactions, monthTransactions, yearTransactions] = await Promise.all([
      db('transactions').where('date', '>=', todayStart),
      db('transactions').where('date', '>=', weekStart),
      db('transactions').where('date', '>=', monthStart),
      db('transactions').where('date', '>=', yearStart)
    ]);

    const calculateMetrics = (transactions) => ({
      books_donated: transactions.filter(t => t.type === 'donation').reduce((sum, t) => sum + t.quantity, 0),
      books_sold: transactions.filter(t => t.type === 'sale').reduce((sum, t) => sum + t.quantity, 0),
      donation_transactions: transactions.filter(t => t.type === 'donation').length,
      sale_transactions: transactions.filter(t => t.type === 'sale').length,
      total_transactions: transactions.length
    });

    const analytics = {
      today: calculateMetrics(todayTransactions),
      this_week: calculateMetrics(weekTransactions),
      this_month: calculateMetrics(monthTransactions),
      this_year: calculateMetrics(yearTransactions)
    };

    res.json({
      success: true,
      data: analytics
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
