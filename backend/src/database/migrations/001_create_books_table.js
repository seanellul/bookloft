exports.up = function(knex) {
  return knex.schema.createTable('books', function(table) {
    table.string('id').primary();
    table.string('isbn', 13).unique().notNullable();
    table.string('title', 255).notNullable();
    table.string('author', 255).notNullable();
    table.string('publisher', 255);
    table.string('published_date');
    table.text('description');
    table.string('thumbnail_url', 500);
    table.integer('quantity').notNullable().defaultTo(0);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Indexes for better performance
    table.index('isbn');
    table.index('title');
    table.index('author');
    table.index('quantity');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('books');
};
