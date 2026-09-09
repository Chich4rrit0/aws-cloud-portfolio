import { randomBytes } from 'node:crypto';

const BASE62 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
const CODE_LENGTH = 8;
const MAX_CREATE_ATTEMPTS = 5;
const MAX_URL_LENGTH = 2048;
const MIN_EXPIRY_SECONDS = 60;
const MAX_EXPIRY_SECONDS = 365 * 24 * 60 * 60;

export class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ValidationError';
  }
}

export function createShortLinkService({ repository, generateCode = randomShortCode, now = () => new Date() }) {
  if (!repository) {
    throw new TypeError('repository is required');
  }

  return {
    async create({ url, expiresAt }, ownerSub) {
      const originalUrl = validateUrl(url);
      const normalizedExpiry = validateExpiry(expiresAt, now);
      validateOwner(ownerSub);

      for (let attempt = 0; attempt < MAX_CREATE_ATTEMPTS; attempt += 1) {
        const shortCode = generateCode();
        validateShortCode(shortCode);

        const link = {
          shortCode,
          originalUrl,
          ownerSub,
          createdAt: now().toISOString(),
          ...(normalizedExpiry === undefined ? {} : { expiresAt: normalizedExpiry })
        };

        if (await repository.putIfAbsent(link)) {
          return link;
        }
      }

      throw new Error('Could not allocate a unique short code');
    },

    async resolve(shortCode) {
      if (!isValidShortCode(shortCode)) {
        return { status: 'not_found' };
      }

      const link = await repository.getByShortCode(shortCode);
      if (!link) {
        return { status: 'not_found' };
      }

      if (link.expiresAt !== undefined && link.expiresAt <= epochSeconds(now())) {
        return { status: 'expired' };
      }

      return { status: 'redirect', location: link.originalUrl };
    },

    async remove(shortCode, ownerSub) {
      validateShortCode(shortCode);
      validateOwner(ownerSub);

      const result = await repository.deleteIfOwned(shortCode, ownerSub);
      return result === 'deleted' ? { status: 'deleted' } : { status: 'not_found' };
    }
  };
}

export function randomShortCode() {
  let code = '';
  while (code.length < CODE_LENGTH) {
    const byte = randomBytes(1)[0];
    const limit = Math.floor(256 / BASE62.length) * BASE62.length;
    if (byte < limit) {
      code += BASE62[byte % BASE62.length];
    }
  }
  return code;
}

function validateUrl(value) {
  if (typeof value !== 'string' || value.length === 0 || value.length > MAX_URL_LENGTH) {
    throw new ValidationError('url must be a non-empty HTTPS URL up to 2048 characters');
  }

  let parsed;
  try {
    parsed = new URL(value);
  } catch {
    throw new ValidationError('url must be a valid HTTPS URL');
  }

  if (parsed.protocol !== 'https:' || parsed.username || parsed.password) {
    throw new ValidationError('url must use HTTPS and must not include credentials');
  }

  return parsed.toString();
}

function validateExpiry(value, now) {
  if (value === undefined) {
    return undefined;
  }

  if (!Number.isInteger(value)) {
    throw new ValidationError('expiresAt must be an integer Epoch seconds value');
  }

  const secondsFromNow = value - epochSeconds(now());
  if (secondsFromNow < MIN_EXPIRY_SECONDS || secondsFromNow > MAX_EXPIRY_SECONDS) {
    throw new ValidationError('expiresAt must be between one minute and 365 days in the future');
  }

  return value;
}

function validateOwner(ownerSub) {
  if (typeof ownerSub !== 'string' || ownerSub.length === 0) {
    throw new ValidationError('ownerSub is required');
  }
}

function validateShortCode(value) {
  if (!isValidShortCode(value)) {
    throw new ValidationError('shortCode must contain exactly eight Base62 characters');
  }
}

function isValidShortCode(value) {
  return typeof value === 'string' && /^[A-Za-z0-9]{8}$/.test(value);
}

function epochSeconds(date) {
  return Math.floor(date.getTime() / 1000);
}
