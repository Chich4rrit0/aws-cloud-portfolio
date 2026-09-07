const assert = require('node:assert/strict');
const { test } = require('node:test');

const { createTaskStoreFromEnvironment } = require('../src/task-store-factory');

test('the default task store remains in memory for local development', async () => {
  const store = createTaskStoreFromEnvironment({});
  await store.initialize();

  const task = await store.create({ title: 'Keep local development simple' });
  const tasks = await store.list();

  assert.equal(tasks.length, 1);
  assert.equal(tasks[0].id, task.id);
});

test('postgres mode requires explicit database configuration', () => {
  assert.throws(
    () => createTaskStoreFromEnvironment({ TASK_STORE: 'postgres' }),
    /DB_HOST is required/
  );
});
