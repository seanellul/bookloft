const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Joi = require('joi');
const { db } = require('../database/connection');

const router = express.Router();

// Validation schemas
const registerSchema = Joi.object({
  name: Joi.string().max(255).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required()
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required()
});

// POST /api/auth/register - Register new volunteer
router.post('/register', async (req, res, next) => {
  try {
    const { error, value } = registerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.details[0].message }
      });
    }

    const { name, email, password } = value;

    // Check if volunteer already exists
    const existingVolunteer = await db('volunteers').where({ email }).first();
    if (existingVolunteer) {
      return res.status(409).json({
        success: false,
        error: { message: 'Volunteer already exists with this email' }
      });
    }

    // Hash password
    const saltRounds = 12;
    const password_hash = await bcrypt.hash(password, saltRounds);

    // Create volunteer
    const [volunteer] = await db('volunteers')
      .insert({
        name,
        email,
        password_hash,
        created_at: new Date()
      })
      .returning(['id', 'name', 'email', 'created_at']);

    // Generate JWT token
    const token = jwt.sign(
      { 
        sub: volunteer.id,
        name: volunteer.name,
        email: volunteer.email 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    res.status(201).json({
      success: true,
      data: {
        volunteer: {
          id: volunteer.id,
          name: volunteer.name,
          email: volunteer.email
        },
        token
      }
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/auth/login - Login volunteer
router.post('/login', async (req, res, next) => {
  try {
    const { error, value } = loginSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.details[0].message }
      });
    }

    const { email, password } = value;

    // Find volunteer
    const volunteer = await db('volunteers')
      .where({ email, is_active: true })
      .first();

    if (!volunteer) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid credentials' }
      });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, volunteer.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid credentials' }
      });
    }

    // Update last login
    await db('volunteers')
      .where({ id: volunteer.id })
      .update({ last_login: new Date() });

    // Generate JWT token
    const token = jwt.sign(
      { 
        sub: volunteer.id,
        name: volunteer.name,
        email: volunteer.email 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    res.json({
      success: true,
      data: {
        volunteer: {
          id: volunteer.id,
          name: volunteer.name,
          email: volunteer.email
        },
        token
      }
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/auth/verify - Verify token
router.post('/verify', async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        error: { message: 'No token provided' }
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get volunteer info
    const volunteer = await db('volunteers')
      .select('id', 'name', 'email', 'is_active')
      .where({ id: decoded.sub })
      .first();

    if (!volunteer || !volunteer.is_active) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid or inactive volunteer' }
      });
    }

    res.json({
      success: true,
      data: { volunteer }
    });
  } catch (error) {
    res.status(401).json({
      success: false,
      error: { message: 'Invalid token' }
    });
  }
});

module.exports = router;
