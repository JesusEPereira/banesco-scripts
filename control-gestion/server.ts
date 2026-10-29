import express from 'express';
import { createServer as createViteServer } from 'vite';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = 3000;

app.use(express.json({ limit: '10mb' }));

// Persistent directory for multi-user shared data
const DATA_DIR = path.join(__dirname, 'data_store');
const TASKS_FILE = path.join(DATA_DIR, 'shared_tasks.json');

if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Helper to safely read tasks
function readTasks(): any[] {
  try {
    if (fs.existsSync(TASKS_FILE)) {
      const content = fs.readFileSync(TASKS_FILE, 'utf-8');
      if (content.trim()) {
        return JSON.parse(content);
      }
    }
  } catch (err) {
    console.error('Error reading shared tasks file:', err);
  }
  return [];
}

// Helper to safely write tasks (skipping redundant writes to prevent file change triggers)
function writeTasks(tasks: any[]): void {
  try {
    const newContent = JSON.stringify(tasks, null, 2);
    if (fs.existsSync(TASKS_FILE)) {
      const currentContent = fs.readFileSync(TASKS_FILE, 'utf-8');
      if (currentContent.trim() === newContent.trim()) {
        return;
      }
    }
    fs.writeFileSync(TASKS_FILE, newContent, 'utf-8');
  } catch (err) {
    console.error('Error writing shared tasks file:', err);
  }
}

async function startServer() {
  // --- API Routes for Multi-user Shared Task Management ---

  // 1. Get all shared tasks
  app.get('/api/tasks', (req, res) => {
    const tasks = readTasks();
    res.json({ success: true, tasks, count: tasks.length });
  });

  // 2. Create or upsert task
  app.post('/api/tasks', (req, res) => {
    const task = req.body;
    if (!task || !task.id) {
      return res.status(400).json({ error: 'Task must have an id' });
    }

    const tasks = readTasks();
    const index = tasks.findIndex((t: any) => t.id === task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.unshift(task);
    }
    writeTasks(tasks);
    res.json({ success: true, task, total: tasks.length });
  });

  // 3. Update task
  app.put('/api/tasks/:id', (req, res) => {
    const { id } = req.params;
    const updates = req.body;
    const tasks = readTasks();
    const index = tasks.findIndex((t: any) => t.id === id);

    if (index >= 0) {
      tasks[index] = { ...tasks[index], ...updates };
      writeTasks(tasks);
      res.json({ success: true, task: tasks[index] });
    } else {
      res.status(404).json({ error: 'Task not found' });
    }
  });

  // 4. Delete task
  app.delete('/api/tasks/:id', (req, res) => {
    const { id } = req.params;
    let tasks = readTasks();
    const initialCount = tasks.length;
    tasks = tasks.filter((t: any) => t.id !== id);
    writeTasks(tasks);
    res.json({ success: true, deleted: initialCount !== tasks.length });
  });

  // 5. Bulk sync / merge for multi-device & multi-user clients
  app.post('/api/tasks/bulk-sync', (req, res) => {
    const { clientTasks } = req.body;
    let serverTasks = readTasks();

    if (!Array.isArray(clientTasks)) {
      return res.status(400).json({ error: 'clientTasks must be an array' });
    }

    if (serverTasks.length === 0 && clientTasks.length > 0) {
      serverTasks = clientTasks;
      writeTasks(serverTasks);
    } else if (clientTasks.length > 0) {
      // Merge tasks, keeping the most recently updated versions
      const map = new Map<string, any>();
      serverTasks.forEach((t: any) => map.set(t.id, t));
      clientTasks.forEach((t: any) => {
        if (!map.has(t.id)) {
          map.set(t.id, t);
        } else {
          const current = map.get(t.id);
          // If client has higher or equal version, merge
          map.set(t.id, { ...current, ...t });
        }
      });
      serverTasks = Array.from(map.values());
      writeTasks(serverTasks);
    }

    res.json({ success: true, tasks: serverTasks, count: serverTasks.length });
  });

  // 6. Reset all shared tasks
  app.post('/api/tasks/reset', (req, res) => {
    writeTasks([]);
    res.json({ success: true, count: 0 });
  });

  // --- Vite / Static Frontend Mounting ---
  const isProduction = process.env.NODE_ENV === 'production';

  if (!isProduction) {
    const vite = await createViteServer({
      server: {
        middlewareMode: true,
        watch: {
          ignored: ['**/data_store/**', '**/shared_tasks.json'],
        },
      },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(__dirname, 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(port, '0.0.0.0', () => {
    console.log(`Banesco Control de Gestión Server running at http://0.0.0.0:${port}`);
  });
}

startServer();
