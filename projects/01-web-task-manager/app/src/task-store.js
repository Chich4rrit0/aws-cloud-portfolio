const { randomUUID } = require('node:crypto');

const validStatuses = new Set(['todo', 'in_progress', 'done']);

function createTaskStore() {
  const tasks = new Map();

  function copyTask(task) {
    return { ...task };
  }

  return {
    create({ title, description = '', status = 'todo' }) {
      const now = new Date().toISOString();
      const task = {
        id: randomUUID(),
        title,
        description,
        status,
        createdAt: now,
        updatedAt: now
      };

      tasks.set(task.id, task);
      return copyTask(task);
    },

    list() {
      return Array.from(tasks.values(), copyTask);
    },

    findById(id) {
      const task = tasks.get(id);
      return task ? copyTask(task) : null;
    },

    update(id, changes) {
      const task = tasks.get(id);

      if (!task) {
        return null;
      }

      Object.assign(task, changes, { updatedAt: new Date().toISOString() });
      return copyTask(task);
    },

    remove(id) {
      return tasks.delete(id);
    }
  };
}

module.exports = {
  createTaskStore,
  validStatuses
};
