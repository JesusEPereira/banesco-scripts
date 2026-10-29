---
name: skill-presentaciones-banesco
description: >-
  Disenar, formatear, redactar y validar presentaciones PowerPoint (.pptx), documentos ejecutivos y piezas graficas bajo la linea visual oficial de Banesco Banco 2026.
  USE CUANDO el usuario solicite crear o formatear 'presentacion', 'diapositivas', 'PowerPoint', 'pptx', 'documento ejecutivo', 'punto de cuenta', 'grafico corporativo', 'colores banesco', 'linea visual 2026', 'Alida Ribbi', '16 laminas' o 'formato de tablas'.
  NO USE PARA desarrollo de scripts de backend en PowerShell (use skill-devops-code), ni para consultas SQL a bases de datos Oracle o AS400, ni para depuracion de matrices de roles (use skill-matriz-roles-perfiles).
---

# Skill: Identidad Visual y Contenido Corporativo Banesco 2026 (`skill-presentaciones-banesco`)

Este Skill estandariza el diseño, la redacción técnica/estratégica, la arquitectura visual y la validación de **Documentos Corporativos**, **Presentaciones Ejecutivas** y **Piezas Gráficas / Visualización de Datos** para Banesco Banco, garantizando el estricto cumplimiento del Manual de Marca 2026 y los preceptos de comunicación estratégica orientados a Comités de Dirección y Órganos de Gobierno.

---

## 1. Ámbito de Aplicación (Documentos, Presentaciones y Gráficos)

Este skill debe activarse siempre que se genere, estructure o valide cualquiera de los siguientes entregables:

1. **Presentaciones Corporativas (.pptx):**
   * Diapositivas para Comités de Dirección, Juntas Directivas y Comités de Auditoría/Seguridad.
   * Plantilla base de referencia: `D:\Cerebro Digital\09_Scripts_y_Herramientas\Plantillas\Plantilla Corporativa Banesco Banco 2026_V2.pptx`.
2. **Documentos Ejecutivos e Informes (Word, PDF, Markdown, HTML):**
   * Puntos de cuenta, memorandos, informes técnicos de auditoría, minutas ejecutivas, propuestas de proyectos y manuales de procedimientos.
3. **Piezas Gráficas y Visualización de Datos:**
   * Gráficos estadísticos (Excel, Power BI, Python/Matplotlib, Seaborn).
   * Tablas institucionales y matrices comparativas.
   * Diagramas de flujo y arquitectura (Mermaid, Visio).
   * Banners informativos, infografías y cuadros de mando (Dashboards).

---

## 2. Paleta Cromática Oficial y Carga Visual (Proporción de Protagonismo)

El universo visual de Banesco 2026 se rige por un **equilibrio cromático estricto**. Tanto en diapositivas como en documentos y gráficos, se deben aplicar las siguientes proporciones:

| Color | HEX | RGB | % Carga Visual | Aplicación en Presentaciones | Aplicación en Documentos y Gráficos |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **Verde Principal** | `#08543C` | `8, 84, 60` | **30% – 50%** | Fondos de portada, bloques principales, barras maestras. | Encabezados principales, títulos H1, bordes de tablas institucionales, Serie 1 en gráficos. |
| **Blanco** | `#FFFFFF` | `255, 255, 255` | **30% – 50%** | Espacio negativo, lienzos limpios, legibilidad. | Fondo principal de página, espacios de respiro, fondo de celdas de lectura. |
| **Verde Oscuro** | `#00382B` | `0, 56, 43` | **20% – 30%** | Soporte de contraste, fondos alternos, solapas. | Encabezados de pie de página, tarjetas de resumen institucional, Serie 2 en gráficos. |
| **Azul Claro** | `#4F76BD` | `79, 118, 189` | **10% – 30%** | Gráficos de barras, líneas secundarias, chips. | Cajas de notas técnicas, llamadas de atención (*callouts*), Serie 3 en gráficos. |
| **Azul Principal** | `#143B64` | `20, 59, 100` | **10% – 20%** | Subtítulos, marcos de resumen, jerarquía visual. | Subtítulos H2, separadores temáticos, marcos de cajas ejecutivas. |
| **Verde Neón** | `#67E048` | `103, 224, 72` | **5% – 10%** | Indicadores KPI positivos, viñetas activas. | Puntos destacados (bullet points), insignias de estado aprobado/exitoso, líneas de tendencia positiva. |
| **Azul Cadmio** | `#3F29AB` | `63, 41, 171` | **5% – 10%** | Acento en gráficos complejos o diferenciadores. | Categorización secundaria, barras de comparación analítica. |
| **Rojo Secundario** | `#C90000` | `201, 0, 0` | **< 5% (Puntual)**| Franja delgada inferior, avisos de riesgo. | Alertas críticas, desviaciones de SLA, métricas en riesgo, advertencias normativas. |

### Colores Neutros y de Texto
* **Texto de Cuerpo (General):** `#3A3A3A` (Gris carbón oscuro. Evita el negro `#000000` absoluto para una lectura más cómoda).
* **Textos Secundarios / Bordes Tenues:** `#707372` / `#595959`.
* **Fondo de Cajas / Callouts:** `#F4F7F5` (Gris verdoso muy tenue) o `#F8FAFC`.
* **Acento Cálido / Alerta Media:** `#FBAE40` (Ámbar corporativo para advertencias o tercera categoría gráfica).

---

## 3. Normativa Tipográfica Oficial

La familia tipográfica institucional es **Poppins** (con fallback a Arial/Helvetica):

### A. Para Presentaciones (PPTX)
* **Portada:** Título en *Poppins Light 48 pt*, Subtítulo en *Poppins SemiBold 28 pt*, metadatos en *12 pt*.
* **Láminas Internas:** Titular en *Poppins Light 24 pt*, Bajada/Subtítulo en *Poppins SemiBold 20 pt*, cuerpo en *12–14 pt*.

### B. Para Documentos Escritos (Word / Markdown / PDF / Reportes)
* **Título del Documento (H1):** *Poppins SemiBold* en **22–24 pt** (Color `#08543C` o `#143B64`).
* **Secciones Principales (H2):** *Poppins SemiBold* en **16–18 pt** (Color `#143B64`).
* **Subsecciones (H3):** *Poppins Medium* en **13–14 pt** (Color `#08543C`).
* **Cuerpo de Texto:** *Poppins Regular* o *Arial* en **10–11 pt**, interlineado 1.15 a 1.25, color `#3A3A3A`.
* **Clasificación del Documento Obligatoria:** Colocar en la parte superior o pie de página:
  * `[CONFIDENCIAL]` / `[USO INTERNO]` / `[PÚBLICO/EXTERNO]`.

---

## 4. Guía de Diseño para Piezas Gráficas y Visualización de Datos

Al elaborar gráficos, diagramas, tablas o infografías, se deben aplicar las siguientes directrices:

### 1. Gráficos de Datos (Barras, Líneas, Donas, Dispersión)
* **Estilo 2D Minimalista:** Sin efectos 3D, sin biseles ni sombras pesadas.
* **Sin Bordes Exteriores:** El contenedor del gráfico no debe llevar recuadro exterior delimitador.
* **Ubicación de Leyendas:** Siempre en la **esquina superior derecha** (respetando el flujo visual natural de izquierda a derecha y arriba hacia abajo).
* **Escalas y Cuadrículas:** Líneas de cuadrícula muy tenues (`#E0E0E0`) y números de escala solo si aportan valor interpretativo; priorizar etiquetas directas sobre los puntos o barras clave.
* **Orden de Colores para Series:**
  1. Serie 1: `#08543C` (Verde Principal)
  2. Serie 2: `#4F76BD` (Azul Claro)
  3. Serie 3: `#143B64` (Azul Principal)
  4. Serie 4: `#67E048` (Verde Neón)
  5. Serie 5: `#FBAE40` (Ámbar)

### 2. Tablas Institucionales y Matrices
* **Fila de Encabezado:** Fondo `#08543C` con texto en `#FFFFFF` (Poppins SemiBold).
* **Filas de Datos:** Fondo alterno blanco (`#FFFFFF`) y gris verdoso tenue (`#F9FBF9`) para facilitar la lectura por renglón.
* **Alineación:** Textos a la izquierda, fechas y estados centrados, valores numéricos y montos monetarios a la derecha.

### 3. Diagramas de Arquitectura y Flujo (Mermaid / Visio)
* Nodos principales: Fondo blanco con borde `#08543C` y texto `#143B64`.
* Nodos de decisión o aprobaciones: Borde `#FBAE40` o `#4F76BD`.
* Nodos de éxito/producción: Fondo con acento `#67E048`.
* Nodos de alertas/rechazo: Borde `#C90000`.

---

## 5. Metodología de Comunicación Estratégica (Álida Ribbi) para Presentaciones

Toda presentación orientada a Comités u Órganos de Gobierno debe ceñirse a las siguientes normas:

### A. Estructura Estricta de 16 Láminas Máximo
1. **1 Lámina:** Portada institucional (Logo Banesco visible, sin eslogan, título, fecha y clasificación).
2. **1 Lámina:** Resumen Ejecutivo (obligatorio después de la portada).
3. **≤ 10 Láminas:** Contenido principal (desarrollo sintetizado de ideas de respaldo).
4. **1 Lámina:** Portadilla de Anexos.
5. **≤ 2 Láminas:** Anexos (si son estrictamente indispensables; sin hipervínculos cruzados).
6. **1 Lámina:** Cierre institucional ("¡Gracias!").

### B. Resumen Ejecutivo Formal para Comités (Lámina 2)
Debe responder directamente a la interrogante: **"¿A qué vamos al Comité?"**:
* **Tipo de Punto:** *Informativo* (para conocimiento) o *Decisorio* (para discusión y aprobación).
* **Clase de Punto:** *Estratégico*, *Regulatorio* u *Operativo*.
* **Objetivo:** Acción clara que se persigue con la presentación.
* **Punto de Cuenta / Gran Mensaje:** Síntesis ejecutiva de la tesis, argumentos, opciones, costos e implicaciones.
* **Decisiones:** Listado explícito de las aprobaciones requeridas a la instancia.

### C. La Regla de los Titulares Activos
* **Máximo 15 palabras:** Frase completa editada con Sujeto, Verbo y Predicado.
* **Noticia y Conclusión:** El titular debe ser una afirmación activa que justifique la lámina (ej. *"La optimización del Core AZ7 redujo los tiempos de autorización en un 35%"* en lugar de *"Tiempos de autorización"*).
* Si ocupa dos renglones, el segundo debe comenzar en **minúscula**.
* Leer únicamente los titulares debe permitir comprender la historia completa de inicio a fin.

---

## 6. Scripts y Herramientas Incluidas en el Skill

### 1. `scripts/new_presentation.ps1`
Duplica la plantilla oficial [Plantilla Corporativa Banesco Banco 2026_V2.pptx](file:///D:/Cerebro%20Digital/Plantilla%20Corporativa%20Banesco%20Banco%202026_V2.pptx) a una carpeta destino para comenzar un nuevo entregable:
```powershell
powershell -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\skills\skill-presentaciones-banesco\scripts\new_presentation.ps1" `
  -ProjectName "Informe_Mensual_Seguridad" `
  -DestinationFolder "D:\Cerebro Digital\08_Certificados_y_Seguridad"
```

### 2. `scripts/validate_presentation.ps1`
Audita un archivo PowerPoint existente contra las reglas del manual (límite de 16 láminas, presencia de Resumen Ejecutivo y titulares ≤ 15 palabras):
```powershell
powershell -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\skills\skill-presentaciones-banesco\scripts\validate_presentation.ps1" `
  -PptxPath "D:\Presentacion_Comite.pptx"
```
