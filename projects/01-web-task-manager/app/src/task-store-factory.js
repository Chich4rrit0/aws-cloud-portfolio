const { readFileSync } = require('node:fs');

const { createPostgresTaskStore } = require('./postgres-task-store');
const { createTaskStore } = require('./task-store');

function createMemoryTaskStore() {
  return {
    ...createTaskStore(),
    async initialize() {},
    async close() {}
  };
}

function requiredValue(environment, name) {
  const value = environment[name];
  if (!value) {
    throw new Error(`${name} is required when TASK_STORE=postgres.`);
  }
  return value;
}

function createPostgresSslConfiguration(environment) {
  if (environment.DB_SSL === 'false') {
    return false;
  }

  const certificatePath = requiredValue(environment, 'DB_SSL_CA_PATH');
  return {
    rejectUnauthorized: true,
    ca: readFileSync(certificatePath, 'utf8')
  };
}

function createTaskStoreFromEnvironment(environment = process.env) {
  const storeType = environment.TASK_STORE || 'memory';

  if (storeType === 'memory') {
    return createMemoryTaskStore();
  }

  if (storeType !== 'postgres') {
    throw new Error('TASK_STORE must be memory or postgres.');
  }

  const port = Number(environment.DB_PORT || 5432);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('DB_PORT must be a valid TCP port.');
  }

  return createPostgresTaskStore({
    host: requiredValue(environment, 'DB_HOST'),
    port,
    database: requiredValue(environment, 'DB_NAME'),
    user: requiredValue(environment, 'DB_USER'),
    password: requiredValue(environment, 'DB_PASSWORD'),
    ssl: createPostgresSslConfiguration(environment)
  });
}

module.exports = {
  createTaskStoreFromEnvironment
};
