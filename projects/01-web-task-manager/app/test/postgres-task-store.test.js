const assert = require('node:assert/strict');
const { test } = require('node:test');

const { createPostgresTaskStore } = require('../src/postgres-task-store');

test('PostgreSQL task store creates a schema and parameterizes task values', async () => {
  const queries = [];
  const timestamp = new Date('2026-09-07T00:00:00.000Z');
  const pool = {
    async query(statement, values = []) {
      queries.push({ statement, values });
      if (statement.includes('INSERT INTO tasks')) {
        return {
          rows: [{
            id: values[0],
            title: values[1],
            description: values[2],
            status: values[3],
            created_at: timestamp,
            updated_at: timestamp
          }]
        };
      }
      return { rows: [], rowCount: 0 };
    },
    async end() {}
  };
  const store = createPostgresTaskStore({ pool });

  await store.initialize();
  const task = await store.create({
    title: "Task with a quote: ' never becomes SQL",
    description: 'Validate parameterized statements.'
  });

  assert.match(queries[0].statement, /CREATE TABLE IF NOT EXISTS tasks/);
  assert.match(queries[1].statement, /VALUES \(\$1, \$2, \$3, \$4, NOW\(\), NOW\(\)\)/);
  assert.equal(queries[1].values[1], "Task with a quote: ' never becomes SQL");
  assert.equal(task.createdAt, timestamp.toISOString());
});
