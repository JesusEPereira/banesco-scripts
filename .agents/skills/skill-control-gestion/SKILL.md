---
name: skill-control-gestion
description: >-
  Administrar, supervisar y orquestar el Dashboard Web corporativo de Control de Gestion y Rendimiento de Equipo (React 19 + Express en localhost:3000), auditoria de SLA y persistencia dual de tareas.
  USE CUANDO el usuario mencione 'control de gestion', 'dashboard web', 'SLA', 'kanban', 'matriz de tareas', 'horas invertidas', 'start_dashboard.ps1', 'rendimiento de equipo', 'desviacion de horas' o 'tareas de seguridad'.
  NO USE PARA auditoria de matrices de roles y perfiles en Excel (use skill-matriz-roles-perfiles), ni para administracion directa de AS400 via terminal (use skill-as400-infra o skill-tlmst-as400), ni para diseno de laminas PowerPoint (use skill-presentaciones-banesco).
---

# Skill: Control de Gestión y Rendimiento de Equipo (`skill-control-gestion`)

Este Skill provee la plataforma integral de supervisión operativa, trazabilidad de requerimientos y auditoría de tiempos para el equipo de **Administración de Seguridad (Banesco)**, abarcando los dominios de **Windows** e **IBM i / AS400**.

---

## 1. Arquitectura y Componentes del Sistema

### 🖥️ 1.1 Frontend (SPA React 19 + TypeScript + Vite)
- **Ruta del Proyecto**: `D:\WKESPEREIRA\D\Scripts\control-gestion\`
- **Tecnologías**: React 19, TypeScript, TailwindCSS v4, Framer Motion, Lucide Icons.
- **Vistas Principales**:
  1. **Dashboard General (`DashboardView.tsx`)**: KPIs ejecutivos, total de tareas activas, vencidas, distribución por dominio y gráfico de horas.
  2. **Matriz Completa de Tareas (`TaskMatrixView.tsx`)**: Vista tabular con filtros avanzados por Dominio (`Windows`, `IBMi`), Responsable (`Jesús Pereira`, `Alexis Guevara`), Prioridad (`Crítica`, `Alta`, `Media`, `Baja`) y Estado.
  3. **Tablero Kanban (`KanbanView.tsx`)**: Gestión visual de flujo de trabajo (`Pendiente`, `En Proceso`, `Completado`).
  4. **Progreso de Equipo (`TeamProgressView.tsx`)**: Rendimiento por colaborador, cálculo de horas estimadas vs invertidas.
  5. **Módulo de Mantenimiento (`MaintenanceView.tsx`)**: Gestión de catálogos y limpieza de datos.
  6. **Gobernanza de SLA y Notificaciones (`EmailDispatchModal.tsx`, `automatedEmailNotifier.ts`)**: Despacho formal de correos desde buzón corporativo (`administracion_de_informacion_ve@banesco.com`).

### ⚙️ 1.2 Backend y API REST (`server.ts`)
El backend corre en Node.js/Express sobre el puerto **3000** y sirve tanto la API de tareas como la interfaz Vite:

| Método | Endpoint | Descripción |
| :---: | :--- | :--- |
| **GET** | `/api/tasks` | Obtiene el listado completo de tareas compartidas en formato JSON. |
| **POST** | `/api/tasks` | Crea o actualiza (upsert) una tarea por su `id`. |
| **PUT** | `/api/tasks/:id` | Modifica campos específicos de una tarea existente. |
| **DELETE** | `/api/tasks/:id` | Elimina una tarea por su identificador. |
| **POST** | `/api/tasks/bulk-sync` | Sincroniza y fusiona tareas entre múltiples clientes/dispositivos. |
| **POST** | `/api/tasks/reset` | Reinicia el almacén de tareas a vacío. |

### 💾 1.3 Persistencia de Datos
- **Persistencia Local**: `D:\WKESPEREIRA\D\Scripts\control-gestion\data_store\shared_tasks.json`
- **Nube**: Conexión con **Firebase Firestore** para sincronización multiusuario en tiempo real.

---

## 2. Puesta en Marcha y Ejecución

### 🚀 Método 1: Script Rápido de PowerShell (Recomendado)
Ejecutar desde cualquier terminal de PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File "D:\WKESPEREIRA\D\Scripts\.agents\skills\skill-control-gestion\scripts\start_dashboard.ps1"
```

### 💻 Método 2: Manual desde Terminal
```powershell
cd D:\WKESPEREIRA\D\Scripts\control-gestion
$env:Path = "C:\Program Files\nodejs;" + $env:Path
npm run dev
```

Una vez iniciado, abrir en el navegador web:
👉 **`http://localhost:3000`**

---

## 3. Estructura del Modelo de Datos de Tareas (`Task`)

Cada actividad en `shared_tasks.json` maneja la siguiente estructura técnica:

```json
{
  "id": "task-1790255097366",
  "code": "ACT-259",
  "title": "Zookeeper SAPL1892 Pentest",
  "description": "Detalle técnico del requerimiento o hallazgo...",
  "type": "Actividad",
  "domain": "Windows",
  "collaboratorId": "collab-jp",
  "priority": "Alta",
  "status": "En Proceso",
  "nextFollowUpDate": "2026-09-29",
  "creationDate": "2026-09-24",
  "lastModifiedBy": "JP",
  "lastModifiedDate": "2026-09-28",
  "hoursEstimated": 25,
  "hoursInvested": 12,
  "companyUnit": "Banesco",
  "subtasks": [
    { "id": "st-1", "title": "Informar a proveedor", "completed": true }
  ],
  "notifyOnOverdue": true,
  "notificationEmail": "jespereira@banesco.com",
  "notificationCc": "aguevara@banesco.com",
  "notificationFrom": "administracion_de_informacion_ve@banesco.com"
}
```

---

## 4. Gobernanza y Colaboradores Registrados

- **Colaborador JP (`collab-jp`)**: Jesús Pereira (`jespereira@banesco.com`)
- **Colaborador AG (`collab-ag`)**: Alexis Guevara (`aguevara@banesco.com`)
- **Buzón Oficial Emisor**: `administracion_de_informacion_ve@banesco.com`
- **Dominios Operativos**: `Windows`, `IBMi` (IBM i / AS400).
