const assert = require('node:assert/strict');
const { once } = require('node:events');
const { test } = require('node:test');

const { createApp } = require('../src/app');

test('GET /health returns the API health status', async (t) => {
  const server = createApp().listen(0);
  await once(server, 'listening');

  t.after(() => new Promise((resolve) => server.close(resolve)));

  const { port } = server.address();
  const response = await fetch(`http://127.0.0.1:${port}/health`);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.status, 'ok');
  assert.equal(body.service, 'task-manager-api');
  assert.match(body.timestamp, /^\d{4}-\d{2}-\d{2}T/);
});
