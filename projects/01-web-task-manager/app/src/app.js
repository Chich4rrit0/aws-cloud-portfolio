const express = require('express');
const path = require('node:path');
const { createTaskStore, validStatuses } = require('./task-store');

function createApp({ taskStore = createTaskStore() } = {}) {
  const app = express();

  app.disable('x-powered-by');
  app.use(express.json({ limit: '16kb' }));
  app.use(express.static(path.join(__dirname, '..', '..', 'frontend')));

  app.get('/health', (_request, response) => {
    response.status(200).json({
      status: 'ok',
      service: 'task-manager-api',
      timestamp: new Date().toISOString()
    });
  });

  app.get('/api/tasks', (_request, response) => {
    response.status(200).json({ tasks: taskStore.list() });
  });

  app.post('/api/tasks', (request, response) => {
    const { errors, value } = validateTaskPayload(request.body);

    if (errors.length > 0) {
      return response.status(400).json({ errors });
    }

    const task = taskStore.create(value);
    return response.status(201).location(`/api/tasks/${task.id}`).json({ task });
  });

  app.get('/api/tasks/:taskId', (request, response) => {
    const task = taskStore.findById(request.params.taskId);

    if (!task) {
      return response.status(404).json({ error: 'Task not found' });
    }

    return response.status(200).json({ task });
  });

  app.patch('/api/tasks/:taskId', (request, response) => {
    const { errors, value } = validateTaskPayload(request.body, { partial: true });

    if (errors.length > 0) {
      return response.status(400).json({ errors });
    }

    const task = taskStore.update(request.params.taskId, value);

    if (!task) {
      return response.status(404).json({ error: 'Task not found' });
    }

    return response.status(200).json({ task });
  });

  app.delete('/api/tasks/:taskId', (request, response) => {
    const removed = taskStore.remove(request.params.taskId);

    if (!removed) {
      return response.status(404).json({ error: 'Task not found' });
    }

    return response.status(204).send();
  });

  app.use((_request, response) => {
    response.status(404).json({
      error: 'Not found'
    });
  });

  app.use((error, _request, response, _next) => {
    console.error(error);
    response.status(500).json({
      error: 'Internal server error'
    });
  });

  return app;
}

function validateTaskPayload(payload, { partial = false } = {}) {
  const errors = [];
  const value = {};

  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    return {
      errors: ['Request body must be a JSON object.'],
      value
    };
  }

  const allowedFields = new Set(['title', 'description', 'status']);
  const fields = Object.keys(payload);

  for (const field of fields) {
    if (!allowedFields.has(field)) {
      errors.push(`Unsupported field: ${field}.`);
    }
  }

  if (!partial || Object.hasOwn(payload, 'title')) {
    if (typeof payload.title !== 'string' || payload.title.trim().length === 0) {
      errors.push('title must be a non-empty string.');
    } else if (payload.title.trim().length > 200) {
      errors.push('title must not exceed 200 characters.');
    } else {
      value.title = payload.title.trim();
    }
  }

  if (Object.hasOwn(payload, 'description')) {
    if (typeof payload.description !== 'string') {
      errors.push('description must be a string.');
    } else if (payload.description.length > 1000) {
      errors.push('description must not exceed 1000 characters.');
    } else {
      value.description = payload.description.trim();
    }
  }

  if (Object.hasOwn(payload, 'status')) {
    if (typeof payload.status !== 'string' || !validStatuses.has(payload.status)) {
      errors.push('status must be todo, in_progress, or done.');
    } else {
      value.status = payload.status;
    }
  }

  if (partial && fields.length === 0) {
    errors.push('At least one supported field is required.');
  }

  return { errors, value };
}

module.exports = {
  createApp
};
