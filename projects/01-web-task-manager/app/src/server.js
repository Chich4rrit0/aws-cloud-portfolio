const { createApp } = require('./app');
const { createTaskStoreFromEnvironment } = require('./task-store-factory');

const port = process.env.PORT || 3000;

async function start() {
  const taskStore = createTaskStoreFromEnvironment();
  await taskStore.initialize();

  const app = createApp({ taskStore });
  app.listen(port, () => {
    console.log(`Task Manager API listening on port ${port}`);
  });
}

start().catch((error) => {
  console.error(`Task Manager API failed to start: ${error.message}`);
  process.exitCode = 1;
});
