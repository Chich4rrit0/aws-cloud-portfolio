import {
  DeleteItemCommand,
  GetItemCommand,
  PutItemCommand
} from '@aws-sdk/client-dynamodb';

export function createDynamoDbLinkRepository({ client, tableName }) {
  if (!client || typeof client.send !== 'function') {
    throw new TypeError('DynamoDB client with send(command) is required');
  }
  if (typeof tableName !== 'string' || tableName.length === 0) {
    throw new TypeError('tableName is required');
  }

  return {
    async putIfAbsent(link) {
      try {
        await client.send(new PutItemCommand({
          TableName: tableName,
          Item: toItem(link),
          ConditionExpression: 'attribute_not_exists(shortCode)'
        }));
        return true;
      } catch (error) {
        if (isConditionalCheckFailure(error)) {
          return false;
        }
        throw error;
      }
    },

    async getByShortCode(shortCode) {
      const response = await client.send(new GetItemCommand({
        TableName: tableName,
        Key: { shortCode: { S: shortCode } }
      }));
      return response.Item ? fromItem(response.Item) : undefined;
    },

    async deleteIfOwned(shortCode, ownerSub) {
      try {
        await client.send(new DeleteItemCommand({
          TableName: tableName,
          Key: { shortCode: { S: shortCode } },
          ConditionExpression: 'ownerSub = :ownerSub',
          ExpressionAttributeValues: {
            ':ownerSub': { S: ownerSub }
          }
        }));
        return 'deleted';
      } catch (error) {
        if (isConditionalCheckFailure(error)) {
          return 'not_found';
        }
        throw error;
      }
    }
  };
}

function toItem(link) {
  return {
    shortCode: { S: link.shortCode },
    originalUrl: { S: link.originalUrl },
    ownerSub: { S: link.ownerSub },
    createdAt: { S: link.createdAt },
    ...(link.expiresAt === undefined ? {} : { expiresAt: { N: String(link.expiresAt) } })
  };
}

function fromItem(item) {
  return {
    shortCode: item.shortCode.S,
    originalUrl: item.originalUrl.S,
    ownerSub: item.ownerSub.S,
    createdAt: item.createdAt.S,
    ...(item.expiresAt === undefined ? {} : { expiresAt: Number(item.expiresAt.N) })
  };
}

function isConditionalCheckFailure(error) {
  return error?.name === 'ConditionalCheckFailedException';
}
