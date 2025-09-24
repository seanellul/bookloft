# Backend API Design for Book Loft

## Overview
This document outlines the backend API structure for the Book Loft inventory management system. The API will handle book inventory, transactions, and synchronization for the Flutter mobile app.

## Technology Stack (Recommended)
- **Framework**: Node.js with Express.js or Python with FastAPI
- **Database**: PostgreSQL for production, SQLite for development
- **Authentication**: JWT tokens
- **Documentation**: Swagger/OpenAPI

## API Endpoints

### Base URL
```
https://bookloft-api.caymanhumane.org/api/v1
```

### Authentication
All endpoints (except health check) require JWT authentication:
```
Authorization: Bearer <jwt_token>
```

### Books Endpoints

#### GET /books
Get all books with optional filtering and pagination.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 50)
- `search` (optional): Search term for title/author/ISBN
- `available_only` (optional): Filter only available books (boolean)

**Response:**
```json
{
  "books": [
    {
      "id": "book_123",
      "isbn": "9781234567890",
      "title": "Sample Book",
      "author": "Author Name",
      "publisher": "Publisher",
      "published_date": "2023-01-01",
      "description": "Book description",
      "thumbnail_url": "https://...",
      "quantity": 3,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 150,
    "pages": 3
  }
}
```

#### GET /books/{id}
Get a specific book by ID.

#### GET /books/isbn/{isbn}
Get a book by ISBN.

#### POST /books
Create a new book.

**Request Body:**
```json
{
  "isbn": "9781234567890",
  "title": "Book Title",
  "author": "Author Name",
  "publisher": "Publisher Name",
  "published_date": "2023-01-01",
  "description": "Book description",
  "thumbnail_url": "https://...",
  "quantity": 1
}
```

#### PUT /books/{id}
Update an existing book.

#### DELETE /books/{id}
Delete a book (soft delete recommended).

### Transactions Endpoints

#### GET /transactions
Get all transactions with optional filtering.

**Query Parameters:**
- `book_id` (optional): Filter by book ID
- `type` (optional): Filter by transaction type (donation/sale)
- `volunteer_name` (optional): Filter by volunteer
- `date_from` (optional): Start date filter
- `date_to` (optional): End date filter
- `page` (optional): Page number
- `limit` (optional): Items per page

#### POST /transactions
Create a new transaction.

**Request Body:**
```json
{
  "book_id": "book_123",
  "type": "donation",
  "quantity": 2,
  "date": "2024-01-01T00:00:00Z",
  "volunteer_name": "John Doe",
  "notes": "Donation from local library"
}
```

#### GET /books/{book_id}/transactions
Get all transactions for a specific book.

### Inventory Endpoints

#### GET /inventory/summary
Get inventory summary statistics.

**Response:**
```json
{
  "total_books": 150,
  "total_quantity": 500,
  "available_books": 120,
  "books_with_multiple_copies": 25,
  "total_donations": 300,
  "total_sales": 200,
  "last_updated": "2024-01-01T00:00:00Z"
}
```

### Search Endpoints

#### GET /books/search
Search books by various criteria.

**Query Parameters:**
- `q` (required): Search query
- `type` (optional): Search type (title, author, isbn, all)
- `limit` (optional): Maximum results

### Sync Endpoints (for offline support)

#### POST /sync/upload
Upload offline changes from mobile app.

**Request Body:**
```json
{
  "books": [...],
  "transactions": [...],
  "last_sync": "2024-01-01T00:00:00Z"
}
```

#### GET /sync/download
Download changes since last sync.

**Query Parameters:**
- `since` (required): Last sync timestamp

### Health Check

#### GET /health
Check API health status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z",
  "version": "1.0.0"
}
```

## Database Schema

### Books Table
```sql
CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    isbn VARCHAR(13) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    publisher VARCHAR(255),
    published_date DATE,
    description TEXT,
    thumbnail_url VARCHAR(500),
    quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_books_isbn ON books(isbn);
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_author ON books(author);
```

### Transactions Table
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id UUID NOT NULL REFERENCES books(id),
    type VARCHAR(10) NOT NULL CHECK (type IN ('donation', 'sale')),
    quantity INTEGER NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    volunteer_name VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_transactions_book_id ON transactions(book_id);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_type ON transactions(type);
```

### Volunteers Table (for authentication)
```sql
CREATE TABLE volunteers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Authentication & Security

### JWT Token Structure
```json
{
  "sub": "volunteer_id",
  "name": "Volunteer Name",
  "email": "volunteer@example.com",
  "iat": 1640995200,
  "exp": 1641081600
}
```

### Security Measures
- JWT tokens with 24-hour expiration
- Password hashing with bcrypt
- Rate limiting on API endpoints
- Input validation and sanitization
- CORS configuration for mobile app

## Error Handling

### Standard Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "isbn",
      "reason": "Invalid ISBN format"
    }
  }
}
```

### HTTP Status Codes
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `404`: Not Found
- `409`: Conflict
- `500`: Internal Server Error

## Deployment Considerations

### Environment Variables
```
DATABASE_URL=postgresql://user:pass@host:port/db
JWT_SECRET=your-secret-key
NODE_ENV=production
PORT=3000
```

### Docker Configuration
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Database Migrations
Use a migration tool like `knex.js` or `prisma` for database schema management.

## Monitoring & Logging

### Health Checks
- Database connectivity
- External API availability
- Memory and CPU usage

### Logging
- Request/response logging
- Error tracking
- Performance metrics
- Security events

## Future Enhancements

### Planned Features
- Real-time notifications
- Advanced analytics dashboard
- Bulk import/export functionality
- Integration with external book databases
- Mobile app push notifications

### Scalability Considerations
- Database indexing optimization
- Caching layer (Redis)
- Load balancing
- CDN for static assets
- API rate limiting

---

This API design provides a solid foundation for the Book Loft inventory management system while maintaining flexibility for future enhancements.
