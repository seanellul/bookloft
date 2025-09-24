exports.up = function(knex) {
  return knex.schema.createTable('transactions', function(table) {
    table.string('id').primary();
    table.string('book_id').notNullable();
    table.string('type').notNullable(); // SQLite doesn't support enums
    table.integer('quantity').notNullable();
    table.timestamp('date').notNullable();
    table.string('volunteer_name', 255);
    table.text('notes');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    
    // Foreign key constraint
    table.foreign('book_id').references('id').inTable('books').onDelete('CASCADE');
    
    // Indexes for better performance
    table.index('book_id');
    table.index('type');
    table.index('date');
    table.index('volunteer_name');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('transactions');
};
