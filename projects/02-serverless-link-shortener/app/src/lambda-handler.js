import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { createDynamoDbLinkRepository } from './dynamodb-link-repository.js';
import { createHttpHandler } from './http-handler.js';
import { createShortLinkService } from './short-link-service.js';

let deployedHandler;

export async function handler(event) {
  if (!deployedHandler) {
    deployedHandler = createLambdaHandler();
  }
  return deployedHandler(event);
}

export function createLambdaHandler({ env = process.env, client = new DynamoDBClient({}), logger = console } = {}) {
  const tableName = requiredEnvironmentValue(env, 'LINKS_TABLE_NAME');
  const repository = createDynamoDbLinkRepository({ client, tableName });
  const service = createShortLinkService({ repository });

  return createHttpHandler({ service, logger });
}

function requiredEnvironmentValue(env, name) {
  const value = env?.[name];
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`Missing required Lambda environment variable: ${name}`);
  }
  return value;
}
