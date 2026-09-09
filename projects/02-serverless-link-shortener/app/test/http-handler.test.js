import assert from 'node:assert/strict';
import test from 'node:test';
import { createHttpHandler } from '../src/http-handler.js';
import { createInMemoryLinkRepository } from '../src/in-memory-link-repository.js';
import { createShortLinkService } from '../src/short-link-service.js';

const NOW = new Date('2026-09-09T12:00:00.000Z');

function createHandler() {
  const repository = createInMemoryLinkRepository();
  let codeIndex = 0;
  const service = createShortLinkService({
    repository,
    generateCode: () => ['Ab3dE9kL', 'Zy8xW7vU'][codeIndex++],
    now: () => NOW
  });
  const logs = [];
  return {
    handler: createHttpHandler({ service, logger: { error: (entry) => logs.push(entry) } }),
    logs
  };
}

function event({ method, path, body, ownerSub, isBase64Encoded = false }) {
  return {
    rawPath: path,
    body,
    isBase64Encoded,
    requestContext: {
      http: { method },
      ...(ownerSub === undefined ? {} : { authorizer: { jwt: { claims: { sub: ownerSub } } } })
    }
  };
}

test('creates a short link using the Cognito subject rather than request input', async () => {
  const { handler } = createHandler();
  const response = await handler(event({
    method: 'POST',
    path: '/urls',
    ownerSub: 'cognito-subject',
    body: JSON.stringify({ url: 'https://example.com/article', ownerSub: 'forged-owner' })
  }));

  assert.equal(response.statusCode, 201);
  assert.deepEqual(JSON.parse(response.body), {
    shortCode: 'Ab3dE9kL',
    shortUrlPath: '/r/Ab3dE9kL',
    createdAt: NOW.toISOString()
  });
});

test('redirects a public request without requiring a JWT', async () => {
  const { handler } = createHandler();
  await handler(event({
    method: 'POST',
    path: '/urls',
    ownerSub: 'cognito-subject',
    body: JSON.stringify({ url: 'https://example.com/article' })
  }));

  const response = await handler(event({ method: 'GET', path: '/r/Ab3dE9kL' }));

  assert.equal(response.statusCode, 302);
  assert.equal(response.headers.location, 'https://example.com/article');
  assert.equal(response.headers['cache-control'], 'no-store');
});

test('rejects administrative requests without an authenticated subject', async () => {
  const { handler } = createHandler();

  const response = await handler(event({
    method: 'POST',
    path: '/urls',
    body: JSON.stringify({ url: 'https://example.com/article' })
  }));

  assert.equal(response.statusCode, 401);
  assert.deepEqual(JSON.parse(response.body), { code: 'UNAUTHORIZED' });
});

test('normalizes invalid bodies and oversized payloads as validation errors', async () => {
  const { handler } = createHandler();

  const invalidJson = await handler(event({ method: 'POST', path: '/urls', ownerSub: 'subject', body: '{' }));
  const oversized = await handler(event({ method: 'POST', path: '/urls', ownerSub: 'subject', body: 'x'.repeat(4097) }));

  assert.equal(invalidJson.statusCode, 400);
  assert.equal(oversized.statusCode, 400);
});

test('does not disclose a link when another owner tries to delete it', async () => {
  const { handler } = createHandler();
  await handler(event({
    method: 'POST',
    path: '/urls',
    ownerSub: 'owner-a',
    body: JSON.stringify({ url: 'https://example.com/article' })
  }));

  const response = await handler(event({ method: 'DELETE', path: '/urls/Ab3dE9kL', ownerSub: 'owner-b' }));

  assert.equal(response.statusCode, 404);
  assert.deepEqual(JSON.parse(response.body), { code: 'NOT_FOUND' });
});

test('logs only route metadata for an unexpected service failure', async () => {
  const { handler, logs } = createHandler();
  const failingHandler = createHttpHandler({
    service: { resolve: async () => { throw new Error('unexpected'); } },
    logger: { error: (entry) => logs.push(entry) }
  });

  const response = await failingHandler(event({ method: 'GET', path: '/r/Ab3dE9kL' }));

  assert.equal(response.statusCode, 500);
  assert.deepEqual(logs, [{
    event: 'unhandled_http_handler_error',
    method: 'GET',
    pathCategory: 'redirect'
  }]);
  assert.equal(handler instanceof Function, true);
});
