const express = require('express');
const Joi = require('joi');
const { db } = require('../database/connection');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const bookSchema = Joi.object({
  isbn: Joi.string().length(13).required(),
  title: Joi.string().max(255).required(),
  author: Joi.string().max(255).required(),
  publisher: Joi.string().max(255).optional(),
  published_date: Joi.date().optional(),
  description: Joi.string().optional(),
  thumbnail_url: Joi.string().uri().max(500).allow('').optional(),
  quantity: Joi.number().integer().min(0).default(0),
  // New metadata fields
  binding: Joi.string().max(50).optional(),
  isbn_10: Joi.string().max(10).optional(),
  language: Joi.string().max(10).optional(),
  page_count: Joi.string().max(10).optional(),
  dimensions: Joi.string().max(50).optional(),
  weight: Joi.string().max(20).optional(),
  edition: Joi.string().max(50).optional(),
  series: Joi.string().max(255).optional(),
  subtitle: Joi.string().max(500).optional(),
  categories: Joi.string().optional(), // JSON string
  tags: Joi.string().optional(), // JSON string
  maturity_rating: Joi.string().max(20).optional(),
  format: Joi.string().max(50).optional()
});

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
      query = query.where(function() {
        this.where('title', 'ilike', `%${search}%`)
            .orWhere('author', 'ilike', `%${search}%`)
            .orWhere('isbn', 'ilike', `%${search}%`);
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
    const { error, value } = bookSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.details[0].message }
      });
    }

    const [book] = await db('books')
      .insert({
        ...value,
        created_at: new Date(),
        updated_at: new Date()
      })
      .returning('*');

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
    const { error, value } = bookSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.details[0].message }
      });
    }

    const [book] = await db('books')
      .where({ id: req.params.id })
      .update({
        ...value,
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

module.exports = router;
