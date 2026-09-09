import assert from 'node:assert/strict';
import test from 'node:test';
import { PutItemCommand } from '@aws-sdk/client-dynamodb';
import { createLambdaHandler } from '../src/lambda-handler.js';

function event({ method, path, body, ownerSub }) {
  return {
    rawPath: path,
    body,
    requestContext: {
      http: { method },
      authorizer: { jwt: { claims: { sub: ownerSub } } }
    }
  };
}

test('fails closed when the deployed table name is not configured', () => {
  assert.throws(
    () => createLambdaHandler({ env: {}, client: { send: async () => ({}) } }),
    /LINKS_TABLE_NAME/
  );
});

test('composes the Lambda handler with a DynamoDB client and configured table', async () => {
  const commands = [];
  const handler = createLambdaHandler({
    env: { LINKS_TABLE_NAME: 'project-02-links' },
    client: {
      send: async (command) => {
        commands.push(command);
        return {};
      }
    },
    logger: { error: () => assert.fail('unexpected logger call') }
  });

  const response = await handler(event({
    method: 'POST',
    path: '/urls',
    ownerSub: 'cognito-subject',
    body: JSON.stringify({ url: 'https://example.com/article' })
  }));

  assert.equal(response.statusCode, 201);
  assert.equal(commands.length, 1);
  assert.equal(commands[0] instanceof PutItemCommand, true);
  assert.equal(commands[0].input.TableName, 'project-02-links');
});
