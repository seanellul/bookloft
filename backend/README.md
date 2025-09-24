# Book Loft Backend API

RESTful API backend for the Book Loft inventory management system for Cayman Humane Society.

## Features

- **📚 Book Management** - CRUD operations for book inventory
- **💰 Transaction Tracking** - Donations and sales with volunteer attribution
- **📊 Analytics** - Inventory summaries and reporting
- **🔄 Offline Sync** - Support for mobile app offline operations
- **🔐 Authentication** - JWT-based volunteer authentication
- **🛡️ Security** - Rate limiting, CORS, input validation

## Tech Stack

- **Node.js** with Express.js
- **PostgreSQL** database with Knex.js ORM
- **JWT** authentication
- **Joi** input validation
- **Helmet** security middleware

## Quick Start

### Prerequisites

- Node.js 18+ 
- PostgreSQL 12+
- npm or yarn

### Installation

1. **Install dependencies**
   ```bash
   cd backend
   npm install
   ```

2. **Setup environment**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

3. **Setup database**
   ```bash
   # Create PostgreSQL database
   createdb bookloft
   
   # Run migrations
   npm run migrate
   ```

4. **Start development server**
   ```bash
   npm run dev
   ```

The API will be available at `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new volunteer
- `POST /api/auth/login` - Login volunteer
- `POST /api/auth/verify` - Verify JWT token

### Books
- `GET /api/books` - List books with pagination/search
- `GET /api/books/:id` - Get book by ID
- `GET /api/books/isbn/:isbn` - Get book by ISBN
- `POST /api/books` - Create new book
- `PUT /api/books/:id` - Update book
- `DELETE /api/books/:id` - Delete book

### Transactions
- `GET /api/transactions` - List transactions with filtering
- `GET /api/transactions/:id` - Get transaction by ID
- `POST /api/transactions` - Create new transaction
- `GET /api/books/:book_id/transactions` - Get book transactions

### Inventory
- `GET /api/inventory/summary` - Get inventory summary
- `GET /api/inventory/books/multiple-copies` - Books with multiple copies
- `GET /api/inventory/books/out-of-stock` - Out of stock books
- `GET /api/inventory/analytics` - Detailed analytics

### Sync (Offline Support)
- `POST /api/sync/upload` - Upload offline changes
- `GET /api/sync/download` - Download changes since last sync
- `GET /api/sync/status` - Get sync status

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
```

### Volunteers Table
```sql
CREATE TABLE volunteers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);
```

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@host:port/db
DB_HOST=localhost
DB_PORT=5432
DB_NAME=bookloft
DB_USER=bookloft_user
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=24h

# Server
PORT=3000
NODE_ENV=development

# CORS
CORS_ORIGIN=http://localhost:3000

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

## Development

### Scripts
- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon
- `npm test` - Run tests
- `npm run migrate` - Run database migrations

### Testing
```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage
```

## Deployment

### Docker
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Environment Setup
1. Set up PostgreSQL database
2. Configure environment variables
3. Run database migrations
4. Start the server

## Security Features

- **JWT Authentication** - Secure token-based auth
- **Password Hashing** - bcrypt with salt rounds
- **Rate Limiting** - Prevent abuse
- **CORS Protection** - Configured origins
- **Input Validation** - Joi schema validation
- **SQL Injection Protection** - Knex.js ORM
- **Helmet Security** - Security headers

## API Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "message": "Error description"
  }
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

---

**Built for Cayman Humane Society** 🐾
