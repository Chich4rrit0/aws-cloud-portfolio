const { randomUUID } = require('node:crypto');
const { Pool } = require('pg');

const taskColumns = `
  id,
  title,
  description,
  status,
  created_at,
  updated_at
`;

const createTasksTable = `
  CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY,
    title VARCHAR(200) NOT NULL CHECK (char_length(title) > 0),
    description VARCHAR(1000) NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'todo'
      CHECK (status IN ('todo', 'in_progress', 'done')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
`;

function mapTask(row) {
  if (!row) {
    return null;
  }

  return {
    id: row.id,
    title: row.title,
    description: row.description,
    status: row.status,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString()
  };
}

function createPostgresTaskStore(options) {
  const pool = options.pool || new Pool(options);

  return {
    async initialize() {
      await pool.query(createTasksTable);
    },

    async create({ title, description = '', status = 'todo' }) {
      const result = await pool.query(
        `INSERT INTO tasks (${taskColumns})
         VALUES ($1, $2, $3, $4, NOW(), NOW())
         RETURNING ${taskColumns};`,
        [randomUUID(), title, description, status]
      );
      return mapTask(result.rows[0]);
    },

    async list() {
      const result = await pool.query(
        `SELECT ${taskColumns} FROM tasks ORDER BY created_at DESC;`
      );
      return result.rows.map(mapTask);
    },

    async findById(id) {
      const result = await pool.query(
        `SELECT ${taskColumns} FROM tasks WHERE id = $1;`,
        [id]
      );
      return mapTask(result.rows[0]);
    },

    async update(id, changes) {
      const columnByField = {
        title: 'title',
        description: 'description',
        status: 'status'
      };
      const assignments = [];
      const values = [id];

      for (const [field, value] of Object.entries(changes)) {
        const column = columnByField[field];
        if (!column) {
          continue;
        }
        values.push(value);
        assignments.push(`${column} = $${values.length}`);
      }

      if (assignments.length === 0) {
        return null;
      }

      const result = await pool.query(
        `UPDATE tasks
         SET ${assignments.join(', ')}, updated_at = NOW()
         WHERE id = $1
         RETURNING ${taskColumns};`,
        values
      );
      return mapTask(result.rows[0]);
    },

    async remove(id) {
      const result = await pool.query('DELETE FROM tasks WHERE id = $1;', [id]);
      return result.rowCount === 1;
    },

    async close() {
      await pool.end();
    }
  };
}

module.exports = {
  createPostgresTaskStore
};
