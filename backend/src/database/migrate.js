const knex = require('knex');
require('dotenv').config();

const config = {
  client: 'sqlite3',
  connection: {
    filename: process.env.DATABASE_URL || './bookloft.db'
  },
  migrations: {
    tableName: 'knex_migrations',
    directory: './src/database/migrations'
  }
};

const db = knex(config);

async function migrate() {
  try {
    console.log('🔄 Running database migrations...');
    await db.migrate.latest();
    console.log('✅ Database migrations completed successfully!');
    
    // Create a default volunteer for testing
    const bcrypt = require('bcryptjs');
    const defaultPassword = await bcrypt.hash('password123', 12);
    
    const existingVolunteer = await db('volunteers').where({ email: 'admin@bookloft.org' }).first();
    if (!existingVolunteer) {
      await db('volunteers').insert({
        id: 'admin-001',
        name: 'Admin User',
        email: 'admin@bookloft.org',
        password_hash: defaultPassword,
        is_active: true,
        created_at: new Date()
      });
      console.log('👤 Default admin user created (admin@bookloft.org / password123)');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
