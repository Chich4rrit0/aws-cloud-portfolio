import assert from 'node:assert/strict';
import test from 'node:test';
import { createInMemoryLinkRepository } from '../src/in-memory-link-repository.js';
import { createShortLinkService, ValidationError } from '../src/short-link-service.js';

const NOW = new Date('2026-09-09T12:00:00.000Z');

function createService({ codes = ['Ab3dE9kL'], repository = createInMemoryLinkRepository() } = {}) {
  let index = 0;
  return {
    repository,
    service: createShortLinkService({
      repository,
      generateCode: () => codes[index++],
      now: () => NOW
    })
  };
}

test('creates an HTTPS link owned by the JWT subject', async () => {
  const { service, repository } = createService();

  const link = await service.create({ url: 'https://example.com/article' }, 'owner-123');

  assert.deepEqual(link, {
    shortCode: 'Ab3dE9kL',
    originalUrl: 'https://example.com/article',
    ownerSub: 'owner-123',
    createdAt: NOW.toISOString()
  });
  assert.deepEqual(await repository.getByShortCode('Ab3dE9kL'), link);
});

test('retries a code collision without overwriting the existing link', async () => {
  const repository = createInMemoryLinkRepository();
  await repository.putIfAbsent({ shortCode: 'Ab3dE9kL', originalUrl: 'https://existing.example/', ownerSub: 'existing', createdAt: NOW.toISOString() });
  const { service } = createService({ codes: ['Ab3dE9kL', 'Zy8xW7vU'], repository });

  const link = await service.create({ url: 'https://new.example/' }, 'owner-123');

  assert.equal(link.shortCode, 'Zy8xW7vU');
  assert.equal((await repository.getByShortCode('Ab3dE9kL')).originalUrl, 'https://existing.example/');
});

test('rejects unsafe URLs and invalid expiry values', async () => {
  const { service } = createService();

  await assert.rejects(() => service.create({ url: 'http://example.com' }, 'owner-123'), ValidationError);
  await assert.rejects(() => service.create({ url: 'https://user:secret@example.com' }, 'owner-123'), ValidationError);
  await assert.rejects(() => service.create({ url: 'https://example.com', expiresAt: 1 }, 'owner-123'), ValidationError);
});

test('resolves an active code and returns a redirect target', async () => {
  const { service } = createService();
  await service.create({ url: 'https://example.com/article' }, 'owner-123');

  assert.deepEqual(await service.resolve('Ab3dE9kL'), {
    status: 'redirect',
    location: 'https://example.com/article'
  });
});

test('returns expired before DynamoDB TTL physical cleanup', async () => {
  const repository = createInMemoryLinkRepository();
  await repository.putIfAbsent({
    shortCode: 'Ab3dE9kL',
    originalUrl: 'https://example.com/article',
    ownerSub: 'owner-123',
    createdAt: NOW.toISOString(),
    expiresAt: Math.floor(NOW.getTime() / 1000) - 1
  });
  const { service } = createService({ repository });

  assert.deepEqual(await service.resolve('Ab3dE9kL'), { status: 'expired' });
});

test('does not disclose or delete a link owned by someone else', async () => {
  const { service } = createService();
  await service.create({ url: 'https://example.com/article' }, 'owner-123');

  assert.deepEqual(await service.remove('Ab3dE9kL', 'other-owner'), { status: 'not_found' });
  assert.deepEqual(await service.resolve('Ab3dE9kL'), {
    status: 'redirect',
    location: 'https://example.com/article'
  });
});
