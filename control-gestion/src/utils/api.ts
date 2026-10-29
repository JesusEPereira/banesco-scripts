import { Task } from '../types';

/**
 * Client API for Multi-User Shared Tasks Synchronization
 * Control de Gestión - Gerencia de Administración de Seguridad (Banesco)
 */

export async function fetchSharedTasks(): Promise<Task[] | null> {
  try {
    const res = await fetch('/api/tasks');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    return Array.isArray(data.tasks) ? data.tasks : [];
  } catch (err) {
    console.warn('Could not fetch shared tasks from server:', err);
    return null;
  }
}

export async function saveSharedTask(task: Task): Promise<boolean> {
  try {
    const res = await fetch('/api/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(task),
    });
    return res.ok;
  } catch (err) {
    console.warn('Could not save task to shared server:', err);
    return false;
  }
}

export async function updateSharedTask(id: string, updates: Partial<Task>): Promise<boolean> {
  try {
    const res = await fetch(`/api/tasks/${encodeURIComponent(id)}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
    return res.ok;
  } catch (err) {
    console.warn(`Could not update task ${id} on shared server:`, err);
    return false;
  }
}

export async function deleteSharedTask(id: string): Promise<boolean> {
  try {
    const res = await fetch(`/api/tasks/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    });
    return res.ok;
  } catch (err) {
    console.warn(`Could not delete task ${id} on shared server:`, err);
    return false;
  }
}

export async function bulkSyncTasks(clientTasks: Task[]): Promise<Task[] | null> {
  try {
    const res = await fetch('/api/tasks/bulk-sync', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ clientTasks }),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    return Array.isArray(data.tasks) ? data.tasks : null;
  } catch (err) {
    console.warn('Could not bulk-sync with shared server:', err);
    return null;
  }
}

export async function resetSharedTasksOnServer(): Promise<boolean> {
  try {
    const res = await fetch('/api/tasks/reset', { method: 'POST' });
    return res.ok;
  } catch (err) {
    console.warn('Could not reset shared server tasks:', err);
    return false;
  }
}
