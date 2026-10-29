import { Collaborator, Task } from '../types';

export const INITIAL_COLLABORATORS: Collaborator[] = [
  {
    id: 'collab-jp',
    name: 'Jesus Pereira',
    initials: 'JP',
    role: 'Colaborador',
    avatarColor: 'bg-indigo-900 text-white',
    weeklyCapacityHours: 40,
    email: 'jespereira@banesco.com',
  },
  {
    id: 'collab-pg',
    name: 'Pamela Gamez',
    initials: 'PG',
    role: 'Colaborador',
    avatarColor: 'bg-purple-800 text-white',
    weeklyCapacityHours: 40,
    email: 'pgamez@banesco.com',
  },
  {
    id: 'collab-am',
    name: 'Alejandro Murgano',
    initials: 'AM',
    role: 'Colaborador',
    avatarColor: 'bg-blue-800 text-white',
    weeklyCapacityHours: 40,
    email: 'amurgano@banesco.com',
  },
  {
    id: 'collab-rm',
    name: 'Ramses Meza',
    initials: 'RM',
    role: 'Colaborador',
    avatarColor: 'bg-emerald-800 text-white',
    weeklyCapacityHours: 40,
    email: 'rmeza@banesco.com',
  },
  {
    id: 'collab-js',
    name: 'Jhon Silva',
    initials: 'JS',
    role: 'Colaborador',
    avatarColor: 'bg-sky-800 text-white',
    weeklyCapacityHours: 40,
    email: 'jsilva@banesco.com',
  },
  {
    id: 'collab-rf',
    name: 'Ronald Fory',
    initials: 'RF',
    role: 'Colaborador',
    avatarColor: 'bg-teal-800 text-white',
    weeklyCapacityHours: 40,
    email: 'rfory@banesco.com',
  },
  {
    id: 'collab-dr',
    name: 'Delia Rodriguez',
    initials: 'DR',
    role: 'Colaborador',
    avatarColor: 'bg-amber-800 text-white',
    weeklyCapacityHours: 40,
    email: 'drodriguez@banesco.com',
  },
  {
    id: 'collab-yz',
    name: 'Yoly Zerpa',
    initials: 'YZ',
    role: 'Colaborador',
    avatarColor: 'bg-rose-800 text-white',
    weeklyCapacityHours: 40,
    email: 'yzerpa@banesco.com',
  },
  {
    id: 'collab-ag',
    name: 'Alexis Guevara',
    initials: 'AG',
    role: 'Supervisión y Control',
    avatarColor: 'bg-rose-900 text-white',
    weeklyCapacityHours: 40,
    email: 'aguevara@banesco.com',
  },
];

// Base de datos limpia de 0 tareas (Dashboard nuevo)
export const INITIAL_TASKS: Task[] = [];

export const REFERENCE_CUTOFF_DATE = new Date().toISOString().split('T')[0];
