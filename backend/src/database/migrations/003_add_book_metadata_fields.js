exports.up = function(knex) {
  return knex.schema.alterTable('books', function(table) {
    // Add new metadata fields
    table.string('binding', 50); // hardback, paperback, etc.
    table.string('isbn_10', 10); // ISBN-10 version
    table.string('language', 10); // Language code (en, es, etc.)
    table.string('page_count', 10); // Number of pages
    table.string('dimensions', 50); // Physical dimensions
    table.string('weight', 20); // Weight information
    table.string('edition', 50); // Edition information
    table.string('series', 255); // Book series name
    table.string('subtitle', 500); // Book subtitle
    table.text('categories'); // JSON array of categories/genres
    table.text('tags'); // JSON array of tags
    table.string('maturity_rating', 20); // Age rating
    table.string('format', 50); // Format (ebook, audiobook, etc.)
    
    // Add indexes for new fields
    table.index('binding');
    table.index('language');
    table.index('series');
  });
};

exports.down = function(knex) {
  return knex.schema.alterTable('books', function(table) {
    // Remove the new fields
    table.dropColumn('binding');
    table.dropColumn('isbn_10');
    table.dropColumn('language');
    table.dropColumn('page_count');
    table.dropColumn('dimensions');
    table.dropColumn('weight');
    table.dropColumn('edition');
    table.dropColumn('series');
    table.dropColumn('subtitle');
    table.dropColumn('categories');
    table.dropColumn('tags');
    table.dropColumn('maturity_rating');
    table.dropColumn('format');
  });
};
