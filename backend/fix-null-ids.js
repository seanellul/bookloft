const knex = require('knex');
require('dotenv').config();

const config = {
  client: 'sqlite3',
  connection: {
    filename: process.env.DATABASE_URL || './bookloft.db'
  }
};

const db = knex(config);

async function fixNullIds() {
  try {
    console.log('🔧 Fixing books with null IDs...');
    
    // Get books with null IDs
    const booksWithNullIds = await db('books').whereNull('id');
    
    for (const book of booksWithNullIds) {
      const newId = Date.now().toString() + Math.random().toString(36).substr(2, 9);
      await db('books')
        .where('isbn', book.isbn)
        .update({ id: newId });
      console.log(`✅ Updated book "${book.title}" with new ID: ${newId}`);
    }
    
    console.log('🔧 Fixing transactions with null IDs...');
    
    // Get transactions with null IDs
    const transactionsWithNullIds = await db('transactions').whereNull('id');
    
    for (const transaction of transactionsWithNullIds) {
      const newId = Date.now().toString() + Math.random().toString(36).substr(2, 9);
      await db('transactions')
        .where('book_id', transaction.book_id)
        .where('created_at', transaction.created_at)
        .update({ id: newId });
      console.log(`✅ Updated transaction with new ID: ${newId}`);
    }
    
    console.log('✅ All null IDs fixed!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error fixing null IDs:', error);
    process.exit(1);
  }
}

fixNullIds();
