import assert from 'node:assert/strict';
import test from 'node:test';
import {
  DeleteItemCommand,
  GetItemCommand,
  PutItemCommand
} from '@aws-sdk/client-dynamodb';
import { createDynamoDbLinkRepository } from '../src/dynamodb-link-repository.js';

const TABLE_NAME = 'project-02-links';
const LINK = {
  shortCode: 'Ab3dE9kL',
  originalUrl: 'https://example.com/article',
  ownerSub: 'cognito-subject',
  createdAt: '2026-09-09T12:00:00.000Z',
  expiresAt: 1798761600
};

function createClient(send) {
  return { send };
}

test('writes links with a conditional expression to prevent code collisions', async () => {
  const commands = [];
  const repository = createDynamoDbLinkRepository({
    client: createClient(async (command) => commands.push(command)),
    tableName: TABLE_NAME
  });

  assert.equal(await repository.putIfAbsent(LINK), true);
  assert.equal(commands.length, 1);
  assert.equal(commands[0] instanceof PutItemCommand, true);
  assert.deepEqual(commands[0].input, {
    TableName: TABLE_NAME,
    Item: {
      shortCode: { S: 'Ab3dE9kL' },
      originalUrl: { S: 'https://example.com/article' },
      ownerSub: { S: 'cognito-subject' },
      createdAt: { S: '2026-09-09T12:00:00.000Z' },
      expiresAt: { N: '1798761600' }
    },
    ConditionExpression: 'attribute_not_exists(shortCode)'
  });
});

test('reports a conditional write collision without hiding other errors', async () => {
  const collision = new Error('collision');
  collision.name = 'ConditionalCheckFailedException';
  const repository = createDynamoDbLinkRepository({
    client: createClient(async () => { throw collision; }),
    tableName: TABLE_NAME
  });

  assert.equal(await repository.putIfAbsent(LINK), false);
});

test('maps DynamoDB attributes back to a domain link', async () => {
  const repository = createDynamoDbLinkRepository({
    client: createClient(async (command) => {
      assert.equal(command instanceof GetItemCommand, true);
      assert.deepEqual(command.input, {
        TableName: TABLE_NAME,
        Key: { shortCode: { S: 'Ab3dE9kL' } }
      });
      return {
        Item: {
          shortCode: { S: 'Ab3dE9kL' },
          originalUrl: { S: 'https://example.com/article' },
          ownerSub: { S: 'cognito-subject' },
          createdAt: { S: '2026-09-09T12:00:00.000Z' }
        }
      };
    }),
    tableName: TABLE_NAME
  });

  assert.deepEqual(await repository.getByShortCode('Ab3dE9kL'), {
    shortCode: 'Ab3dE9kL',
    originalUrl: 'https://example.com/article',
    ownerSub: 'cognito-subject',
    createdAt: '2026-09-09T12:00:00.000Z'
  });
});

test('deletes only when the caller subject owns the link', async () => {
  const commands = [];
  const repository = createDynamoDbLinkRepository({
    client: createClient(async (command) => commands.push(command)),
    tableName: TABLE_NAME
  });

  assert.equal(await repository.deleteIfOwned('Ab3dE9kL', 'cognito-subject'), 'deleted');
  assert.equal(commands[0] instanceof DeleteItemCommand, true);
  assert.deepEqual(commands[0].input, {
    TableName: TABLE_NAME,
    Key: { shortCode: { S: 'Ab3dE9kL' } },
    ConditionExpression: 'ownerSub = :ownerSub',
    ExpressionAttributeValues: { ':ownerSub': { S: 'cognito-subject' } }
  });
});

test('maps a failed ownership condition to not found', async () => {
  const failure = new Error('condition failed');
  failure.name = 'ConditionalCheckFailedException';
  const repository = createDynamoDbLinkRepository({
    client: createClient(async () => { throw failure; }),
    tableName: TABLE_NAME
  });

  assert.equal(await repository.deleteIfOwned('Ab3dE9kL', 'other-subject'), 'not_found');
});
