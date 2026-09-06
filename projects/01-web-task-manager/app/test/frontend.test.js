const assert = require('node:assert/strict');
const { once } = require('node:events');
const { test } = require('node:test');

const { createApp } = require('../src/app');

test('GET / serves the local Task Manager frontend', async (t) => {
  const server = createApp().listen(0);
  await once(server, 'listening');
  t.after(() => new Promise((resolve) => server.close(resolve)));

  const { port } = server.address();
  const response = await fetch(`http://127.0.0.1:${port}/`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /^text\/html/);
  assert.match(html, /<title>AWS Cloud Portfolio — Task Manager<\/title>/);
});
