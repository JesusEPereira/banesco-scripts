/**
 * Business Working Hours Calculation Engine
 * Reglas de negocio:
 * - 8 horas laborales diarias (Jornada: 08:00 a 17:00 con 1h de descanso de 12:00 a 13:00 = 8h netas).
 * - Días hábiles: Lunes a Viernes. Sábados y Domingos no contabilizan horas.
 * - Se calcula desde el momento exacto en que la tarea pasa al estado "En Proceso".
 */

import { Task } from '../types';

/**
 * Calcula las horas laborales netas transcurridas entre dos fechas respetando la jornada de 8h lun-vie.
 */
export function calculateWorkingHoursBetween(
  startDateInput: Date | string,
  endDateInput: Date | string = new Date()
): number {
  const start = typeof startDateInput === 'string' ? new Date(startDateInput) : new Date(startDateInput.getTime());
  const end = typeof endDateInput === 'string' ? new Date(endDateInput) : new Date(endDateInput.getTime());

  if (isNaN(start.getTime()) || isNaN(end.getTime()) || end <= start) {
    return 0;
  }

  let totalMinutes = 0;

  // Normalizamos el iterador al inicio del día de inicio
  const currentDay = new Date(start.getFullYear(), start.getMonth(), start.getDate());
  const endDay = new Date(end.getFullYear(), end.getMonth(), end.getDate());

  while (currentDay <= endDay) {
    const dayOfWeek = currentDay.getDay(); // 0 = Domingo, 6 = Sábado

    // Solo contabilizar de lunes (1) a viernes (5)
    if (dayOfWeek >= 1 && dayOfWeek <= 5) {
      const year = currentDay.getFullYear();
      const month = currentDay.getMonth();
      const date = currentDay.getDate();

      // Franja de la mañana: 08:00 a 12:00 (4 horas = 240 minutos)
      const morningStart = new Date(year, month, date, 8, 0, 0, 0).getTime();
      const morningEnd = new Date(year, month, date, 12, 0, 0, 0).getTime();

      // Franja de la tarde: 13:00 a 17:00 (4 horas = 240 minutos)
      const afternoonStart = new Date(year, month, date, 13, 0, 0, 0).getTime();
      const afternoonEnd = new Date(year, month, date, 17, 0, 0, 0).getTime();

      const dayEffectiveStart = currentDay.getTime() === new Date(start.getFullYear(), start.getMonth(), start.getDate()).getTime()
        ? start.getTime()
        : morningStart;

      const dayEffectiveEnd = currentDay.getTime() === endDay.getTime()
        ? end.getTime()
        : afternoonEnd;

      // Calcular minutos en la mañana
      const mStart = Math.max(morningStart, dayEffectiveStart);
      const mEnd = Math.min(morningEnd, dayEffectiveEnd);
      if (mEnd > mStart) {
        totalMinutes += (mEnd - mStart) / (1000 * 60);
      }

      // Calcular minutos en la tarde
      const aStart = Math.max(afternoonStart, dayEffectiveStart);
      const aEnd = Math.min(afternoonEnd, dayEffectiveEnd);
      if (aEnd > aStart) {
        totalMinutes += (aEnd - aStart) / (1000 * 60);
      }
    }

    // Avanzar un día
    currentDay.setDate(currentDay.getDate() + 1);
  }

  const hours = totalMinutes / 60;
  // Redondear a 1 decimal
  return Math.round(hours * 10) / 10;
}

/**
 * Obtiene las horas invertidas actuales de una tarea.
 * Si está en "En Proceso", calcula dinámicamente las horas laborales transcurridas
 * sumadas a las acumuladas previas.
 */
export function getTaskInvestedHours(task: Task, referenceDate: Date = new Date()): number {
  if (task.status === 'En Proceso') {
    const startedAt = task.inProgressStartedAt || task.creationDate || referenceDate.toISOString();
    const liveHours = calculateWorkingHoursBetween(startedAt, referenceDate);
    const accumulated = task.accumulatedWorkHours || 0;
    const total = accumulated + liveHours;
    return Math.max(total, task.hoursInvested || 0);
  }

  return task.hoursInvested || 0;
}

/**
 * Calcula el porcentaje de progreso de horas de la tarea.
 */
export function getTaskProgressPercentage(task: Task, referenceDate: Date = new Date()): number {
  const invested = getTaskInvestedHours(task, referenceDate);
  const estimated = task.hoursEstimated > 0 ? task.hoursEstimated : 1;
  const pct = Math.round((invested / estimated) * 100);
  return Math.min(pct, 100);
}

/**
 * Actualiza la tarea cuando cambia de estado, gestionando los timestamps
 * de "En Proceso" y acumulando las horas de jornada laboral efectivamente laboradas.
 */
export function updateTaskStatusWithHours(
  task: Task,
  newStatus: Task['status'],
  modifiedByInitials: string,
  now: Date = new Date()
): Task {
  const nowIso = now.toISOString();
  const todayStr = nowIso.split('T')[0];

  let inProgressStartedAt = task.inProgressStartedAt;
  let accumulatedWorkHours = task.accumulatedWorkHours || 0;
  let hoursInvested = task.hoursInvested || 0;

  if (task.status === 'En Proceso' && newStatus !== 'En Proceso') {
    // Saliendo de "En Proceso": congelar las horas laborales devengadas
    if (inProgressStartedAt) {
      const elapsedWorkingHours = calculateWorkingHoursBetween(inProgressStartedAt, now);
      accumulatedWorkHours += elapsedWorkingHours;
      accumulatedWorkHours = Math.round(accumulatedWorkHours * 10) / 10;
      hoursInvested = accumulatedWorkHours;
    }
    inProgressStartedAt = undefined;
  } else if (task.status !== 'En Proceso' && newStatus === 'En Proceso') {
    // Entrando a "En Proceso": marcar inicio del reloj laboral
    inProgressStartedAt = nowIso;
  } else if (task.status === 'En Proceso' && newStatus === 'En Proceso') {
    // Permanece en "En Proceso": actualizar hoursInvested en vivo
    if (!inProgressStartedAt) {
      inProgressStartedAt = nowIso;
    }
    const elapsed = calculateWorkingHoursBetween(inProgressStartedAt, now);
    hoursInvested = Math.round((accumulatedWorkHours + elapsed) * 10) / 10;
  }

  return {
    ...task,
    status: newStatus,
    inProgressStartedAt,
    accumulatedWorkHours,
    hoursInvested,
    lastModifiedBy: modifiedByInitials,
    lastModifiedDate: todayStr,
  };
}
