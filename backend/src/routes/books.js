const express = require('express');
const Joi = require('joi');
const { db } = require('../database/connection');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const bookSchema = Joi.object({
  // Required fields
  isbn: Joi.string().length(13).required(),
  title: Joi.string().max(255).required(),
  author: Joi.string().allow('').max(255).required(), // Allow empty for debugging
  
  // Optional core fields
  publisher: Joi.string().allow('', null).max(255).optional(),
  published_date: Joi.alternatives().try(
    Joi.date(),
    Joi.string().allow('', null)
  ).optional(),
  description: Joi.string().allow('', null).optional(),
  thumbnail_url: Joi.string().allow('', null).max(500).optional(),
  quantity: Joi.number().integer().min(0).default(0),
  
  
  // New metadata fields
  binding: Joi.string().allow('', null).max(50).optional(),
  isbn_10: Joi.string().allow('', null).max(10).optional(),
  language: Joi.string().allow('', null).max(10).optional(),
  page_count: Joi.alternatives().try(
    Joi.string().allow('', null).max(10),
    Joi.number().integer().min(0)
  ).optional(),
  dimensions: Joi.string().allow('', null).max(50).optional(),
  weight: Joi.string().allow('', null).max(20).optional(),
  edition: Joi.string().allow('', null).max(50).optional(),
  series: Joi.string().allow('', null).max(255).optional(),
  subtitle: Joi.string().allow('', null).max(500).optional(),
  categories: Joi.string().allow('', null).optional(), // JSON string
  tags: Joi.string().allow('', null).optional(), // JSON string
  maturity_rating: Joi.string().allow('', null).max(20).optional(),
  format: Joi.string().allow('', null).max(50).optional()
}).options({ stripUnknown: true }); // Remove unknown fields

const searchSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(50),
  search: Joi.string().max(255).optional(),
  available_only: Joi.boolean().default(false)
});

// GET /api/books - Get all books with pagination and search
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const { error, value } = searchSchema.validate(req.query);
    if (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.details[0].message }
      });
    }

    const { page, limit, search, available_only } = value;
    const offset = (page - 1) * limit;

    let query = db('books');

    // Apply search filter
    if (search) {
      const like = `%${search}%`;
      query = query.where(function() {
        this.where('title', 'like', like)
            .orWhere('author', 'like', like)
            .orWhere('isbn', 'like', like);
      });
    }

    // Apply availability filter
    if (available_only) {
      query = query.where('quantity', '>', 0);
    }

    // Get total count
    const totalQuery = query.clone();
    const [{ count }] = await totalQuery.count('* as count');

    // Get books with pagination
    const books = await query
      .select('*')
      .orderBy('title', 'asc')
      .limit(limit)
      .offset(offset);

    res.json({
      success: true,
      data: {
        books,
        pagination: {
          page,
          limit,
          total: parseInt(count),
          pages: Math.ceil(count / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/books/:id - Get book by ID
router.get('/:id', authenticateToken, async (req, res, next) => {
  try {
    const book = await db('books').where({ id: req.params.id }).first();
    
    if (!book) {
      return res.status(404).json({
        success: false,
        error: { message: 'Book not found' }
      });
    }

    res.json({
      success: true,
      data: book
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/books/isbn/:isbn - Get book by ISBN
router.get('/isbn/:isbn', authenticateToken, async (req, res, next) => {
  try {
    const book = await db('books').where({ isbn: req.params.isbn }).first();
    
    if (!book) {
      return res.status(404).json({
        success: false,
        error: { message: 'Book not found' }
      });
    }

    res.json({
      success: true,
      data: book
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/books - Create new book
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    // Remove fields that the backend should control
    const cleanedBody = { ...req.body };
    delete cleanedBody.id;
    delete cleanedBody.created_at;
    delete cleanedBody.updated_at;
    
    const { error, value } = bookSchema.validate(cleanedBody);
    if (error) {
      console.log('=== BOOK VALIDATION ERROR ===');
      console.log('Error message:', error.details[0].message);
      console.log('Error path:', error.details[0].path);
      console.log('Error context:', error.details[0].context);
      console.log('Original request body keys:', Object.keys(req.body));
      console.log('Cleaned request body:', JSON.stringify(cleanedBody, null, 2));
      console.log('=== END VALIDATION ERROR ===');
      return res.status(400).json({
        success: false,
        error: { 
          message: error.details[0].message,
          field: error.details[0].path?.join('.'),
          received_value: error.details[0].context?.value
        }
      });
    }

    // Generate unique ID
    const bookId = Date.now().toString();
    
    await db('books')
      .insert({
        id: bookId,
        ...value,
        created_at: new Date(),
        updated_at: new Date()
      });

    // Fetch the created book
    const book = await db('books').where({ id: bookId }).first();

    res.status(201).json({
      success: true,
      data: book
    });
  } catch (error) {
    next(error);
  }
});

// PUT /api/books/:id - Update book
router.put('/:id', authenticateToken, async (req, res, next) => {
  try {
    // Remove fields that the backend should control
    const cleanedBody = { ...req.body };
    delete cleanedBody.id;
    delete cleanedBody.created_at;
    delete cleanedBody.updated_at;
    
    const { error, value } = bookSchema.validate(cleanedBody);
    if (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.details[0].message }
      });
    }

    const updateCount = await db('books')
      .where({ id: req.params.id })
      .update({
        ...value,
        updated_at: new Date()
      });

    if (updateCount === 0) {
      return res.status(404).json({
        success: false,
        error: { message: 'Book not found' }
      });
    }

    // Fetch the updated book
    const book = await db('books').where({ id: req.params.id }).first();

    res.json({
      success: true,
      data: book
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/books/:id - Delete book (soft delete by setting quantity to 0)
router.delete('/:id', authenticateToken, async (req, res, next) => {
  try {
    const [book] = await db('books')
      .where({ id: req.params.id })
      .update({
        quantity: 0,
        updated_at: new Date()
      })
      .returning('*');

    if (!book) {
      return res.status(404).json({
        success: false,
        error: { message: 'Book not found' }
      });
    }

    res.json({
      success: true,
      data: { message: 'Book deleted successfully' }
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/books/:book_id/transactions - Get transactions for a specific book with analytics
router.get('/:book_id/transactions', authenticateToken, async (req, res, next) => {
  try {
    // Get all transactions for the book
    const transactions = await db('transactions')
      .where({ book_id: req.params.book_id })
      .orderBy('date', 'desc');

    // Calculate analytics
    const analytics = {
      total_transactions: transactions.length,
      times_donated: transactions.filter(t => t.type === 'donation').reduce((sum, t) => sum + t.quantity, 0),
      times_sold: transactions.filter(t => t.type === 'sale').reduce((sum, t) => sum + t.quantity, 0),
      donation_count: transactions.filter(t => t.type === 'donation').length,
      sale_count: transactions.filter(t => t.type === 'sale').length,
    };

    res.json({
      success: true,
      data: {
        transactions,
        analytics
      }
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
