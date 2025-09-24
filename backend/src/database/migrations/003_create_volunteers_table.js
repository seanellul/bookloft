exports.up = function(knex) {
  return knex.schema.createTable('volunteers', function(table) {
    table.string('id').primary();
    table.string('name', 255).notNullable();
    table.string('email', 255).unique().notNullable();
    table.string('password_hash', 255).notNullable();
    table.boolean('is_active').defaultTo(true);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('last_login');
    
    // Indexes
    table.index('email');
    table.index('is_active');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('volunteers');
};
