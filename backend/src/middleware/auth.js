const jwt = require('jsonwebtoken');
const { db } = require('../database/connection');

const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        error: { message: 'Access token required' }
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Verify volunteer still exists and is active
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

    req.volunteer = volunteer;
    next();
  } catch (error) {
    return res.status(403).json({
      success: false,
      error: { message: 'Invalid token' }
    });
  }
};

module.exports = { authenticateToken };
