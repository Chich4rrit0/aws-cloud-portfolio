const assert = require('node:assert/strict');
const { once } = require('node:events');
const { test } = require('node:test');

const { createApp } = require('../src/app');

async function startTestServer(t) {
  const server = createApp().listen(0);
  await once(server, 'listening');

  t.after(() => new Promise((resolve) => server.close(resolve)));

  const { port } = server.address();
  return `http://127.0.0.1:${port}`;
}

test('tasks can be created, listed, updated, and deleted', async (t) => {
  const baseUrl = await startTestServer(t);
  const createdResponse = await fetch(`${baseUrl}/api/tasks`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: 'Document the AWS architecture',
      description: 'Add the initial architecture diagram.'
    })
  });
  const { task: createdTask } = await createdResponse.json();

  assert.equal(createdResponse.status, 201);
  assert.equal(createdTask.status, 'todo');
  assert.match(createdTask.id, /^[0-9a-f-]{36}$/);

  const listResponse = await fetch(`${baseUrl}/api/tasks`);
  const { tasks } = await listResponse.json();

  assert.equal(listResponse.status, 200);
  assert.equal(tasks.length, 1);
  assert.equal(tasks[0].id, createdTask.id);

  const updatedResponse = await fetch(`${baseUrl}/api/tasks/${createdTask.id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: 'done' })
  });
  const { task: updatedTask } = await updatedResponse.json();

  assert.equal(updatedResponse.status, 200);
  assert.equal(updatedTask.status, 'done');

  const deletedResponse = await fetch(`${baseUrl}/api/tasks/${createdTask.id}`, {
    method: 'DELETE'
  });

  assert.equal(deletedResponse.status, 204);

  const emptyListResponse = await fetch(`${baseUrl}/api/tasks`);
  const { tasks: emptyTasks } = await emptyListResponse.json();
  assert.equal(emptyTasks.length, 0);
});
