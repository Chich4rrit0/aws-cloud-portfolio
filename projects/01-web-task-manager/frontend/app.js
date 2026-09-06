const taskForm = document.querySelector('#task-form');
const titleInput = document.querySelector('#title');
const descriptionInput = document.querySelector('#description');
const statusInput = document.querySelector('#status');
const taskList = document.querySelector('#task-list');
const taskCount = document.querySelector('#task-count');
const feedback = document.querySelector('#feedback');
const formMode = document.querySelector('#form-mode');
const submitTask = document.querySelector('#submit-task');
const cancelEdit = document.querySelector('#cancel-edit');

const state = {
  editingTaskId: null,
  tasks: []
};

function setFeedback(message = '', isError = false) {
  feedback.textContent = message;
  feedback.classList.toggle('error', isError);
}

async function apiRequest(path, options = {}) {
  const response = await fetch(path, options);
  const contentType = response.headers.get('content-type') || '';
  const body = contentType.includes('application/json') ? await response.json() : null;

  if (!response.ok) {
    const message = body?.errors?.join(' ') || body?.error || 'The request could not be completed.';
    throw new Error(message);
  }

  return body;
}

function createButton(label, className, handler) {
  const button = document.createElement('button');
  button.type = 'button';
  button.textContent = label;
  button.className = className;
  button.addEventListener('click', handler);
  return button;
}

function statusLabel(status) {
  return {
    todo: 'To do',
    in_progress: 'In progress',
    done: 'Done'
  }[status] || status;
}

function renderTasks() {
  taskList.replaceChildren();
  taskCount.textContent = `${state.tasks.length} ${state.tasks.length === 1 ? 'task' : 'tasks'}`;

  if (state.tasks.length === 0) {
    const emptyState = document.createElement('li');
    emptyState.className = 'empty-state';
    emptyState.textContent = 'No tasks yet. Create one to begin.';
    taskList.append(emptyState);
    return;
  }

  for (const task of state.tasks) {
    const item = document.createElement('li');
    item.className = 'task-card';

    const heading = document.createElement('h3');
    heading.textContent = task.title;
    item.append(heading);

    if (task.description) {
      const description = document.createElement('p');
      description.textContent = task.description;
      item.append(description);
    }

    const meta = document.createElement('div');
    meta.className = 'task-meta';

    const statusSelect = document.createElement('select');
    statusSelect.setAttribute('aria-label', `Update status for ${task.title}`);
    for (const status of ['todo', 'in_progress', 'done']) {
      const option = document.createElement('option');
      option.value = status;
      option.textContent = statusLabel(status);
      option.selected = task.status === status;
      statusSelect.append(option);
    }
    statusSelect.addEventListener('change', () => updateTaskStatus(task.id, statusSelect.value));

    const updatedAt = document.createElement('span');
    updatedAt.textContent = `Updated ${new Date(task.updatedAt).toLocaleString()}`;
    meta.append(statusSelect, updatedAt);

    const actions = document.createElement('div');
    actions.className = 'task-actions';
    actions.append(
      createButton('Edit', 'secondary', () => beginEdit(task)),
      createButton('Delete', 'danger', () => deleteTask(task))
    );

    item.append(meta, actions);
    taskList.append(item);
  }
}

async function loadTasks() {
  try {
    const { tasks } = await apiRequest('/api/tasks');
    state.tasks = tasks;
    renderTasks();
    setFeedback();
  } catch (error) {
    setFeedback(error.message, true);
  }
}

function resetForm() {
  state.editingTaskId = null;
  taskForm.reset();
  statusInput.value = 'todo';
  formMode.textContent = 'Tasks are stored in memory in this local version.';
  submitTask.textContent = 'Create task';
  cancelEdit.classList.add('hidden');
}

function beginEdit(task) {
  state.editingTaskId = task.id;
  titleInput.value = task.title;
  descriptionInput.value = task.description;
  statusInput.value = task.status;
  formMode.textContent = `Editing “${task.title}”.`;
  submitTask.textContent = 'Save changes';
  cancelEdit.classList.remove('hidden');
  titleInput.focus();
}

async function updateTaskStatus(taskId, status) {
  try {
    await apiRequest(`/api/tasks/${taskId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status })
    });
    await loadTasks();
    setFeedback('Task status updated.');
  } catch (error) {
    setFeedback(error.message, true);
    await loadTasks();
  }
}

async function deleteTask(task) {
  if (!window.confirm(`Delete “${task.title}”?`)) {
    return;
  }

  try {
    await apiRequest(`/api/tasks/${task.id}`, { method: 'DELETE' });
    if (state.editingTaskId === task.id) {
      resetForm();
    }
    await loadTasks();
    setFeedback('Task deleted.');
  } catch (error) {
    setFeedback(error.message, true);
  }
}

taskForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  const payload = {
    title: titleInput.value,
    description: descriptionInput.value,
    status: statusInput.value
  };

  try {
    if (state.editingTaskId) {
      await apiRequest(`/api/tasks/${state.editingTaskId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      setFeedback('Task updated.');
    } else {
      await apiRequest('/api/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      setFeedback('Task created.');
    }

    resetForm();
    await loadTasks();
  } catch (error) {
    setFeedback(error.message, true);
  }
});

cancelEdit.addEventListener('click', resetForm);
document.querySelector('#refresh-tasks').addEventListener('click', loadTasks);

loadTasks();
