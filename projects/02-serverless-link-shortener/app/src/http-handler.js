import { ValidationError } from './short-link-service.js';

const MAX_BODY_BYTES = 4 * 1024;

export function createHttpHandler({ service, logger = console }) {
  if (!service) {
    throw new TypeError('service is required');
  }

  return async function handler(event) {
    const method = event?.requestContext?.http?.method;
    const path = event?.rawPath;

    try {
      if (method === 'GET' && /^\/r\/[^/]+$/.test(path ?? '')) {
        return await resolveRedirect(service, decodeURIComponent(path.slice(3)));
      }

      if (method === 'POST' && path === '/urls') {
        const ownerSub = requireOwnerSub(event);
        const input = parseJsonBody(event);
        const link = await service.create(input, ownerSub);
        return json(201, {
          shortCode: link.shortCode,
          shortUrlPath: `/r/${link.shortCode}`,
          createdAt: link.createdAt,
          ...(link.expiresAt === undefined ? {} : { expiresAt: link.expiresAt })
        });
      }

      if (method === 'DELETE' && /^\/urls\/[^/]+$/.test(path ?? '')) {
        const ownerSub = requireOwnerSub(event);
        const result = await service.remove(decodeURIComponent(path.slice('/urls/'.length)), ownerSub);
        return result.status === 'deleted' ? empty(204) : error(404, 'NOT_FOUND');
      }

      return error(404, 'NOT_FOUND');
    } catch (caught) {
      if (caught instanceof ValidationError) {
        return error(400, 'VALIDATION_ERROR');
      }
      if (caught instanceof UnauthorizedError) {
        return error(401, 'UNAUTHORIZED');
      }
      if (caught instanceof SyntaxError || caught instanceof BodyTooLargeError) {
        return error(400, 'VALIDATION_ERROR');
      }

      logger.error({
        event: 'unhandled_http_handler_error',
        method: typeof method === 'string' ? method : 'unknown',
        pathCategory: classifyPath(path)
      });
      return error(500, 'INTERNAL_ERROR');
    }
  };
}

async function resolveRedirect(service, shortCode) {
  const result = await service.resolve(shortCode);
  if (result.status === 'redirect') {
    return {
      statusCode: 302,
      headers: {
        location: result.location,
        'cache-control': 'no-store'
      },
      body: ''
    };
  }
  return result.status === 'expired' ? error(410, 'EXPIRED') : error(404, 'NOT_FOUND');
}

function requireOwnerSub(event) {
  const ownerSub = event?.requestContext?.authorizer?.jwt?.claims?.sub;
  if (typeof ownerSub !== 'string' || ownerSub.length === 0) {
    throw new UnauthorizedError();
  }
  return ownerSub;
}

function parseJsonBody(event) {
  if (typeof event?.body !== 'string' || event.body.length === 0) {
    throw new SyntaxError('request body is required');
  }

  const body = event.isBase64Encoded ? Buffer.from(event.body, 'base64').toString('utf8') : event.body;
  if (Buffer.byteLength(body, 'utf8') > MAX_BODY_BYTES) {
    throw new BodyTooLargeError();
  }

  const parsed = JSON.parse(body);
  if (!parsed || Array.isArray(parsed) || typeof parsed !== 'object') {
    throw new ValidationError('body must be a JSON object');
  }
  return parsed;
}

function json(statusCode, value) {
  return {
    statusCode,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify(value)
  };
}

function empty(statusCode) {
  return { statusCode, headers: {}, body: '' };
}

function error(statusCode, code) {
  return json(statusCode, { code });
}

function classifyPath(path) {
  if (typeof path !== 'string') {
    return 'unknown';
  }
  if (path.startsWith('/r/')) {
    return 'redirect';
  }
  if (path.startsWith('/urls')) {
    return 'administration';
  }
  return 'other';
}

class UnauthorizedError extends Error {}
class BodyTooLargeError extends Error {}
