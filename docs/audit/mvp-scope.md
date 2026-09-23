# P0.2 — Alcance del MVP y no-alcance

## 1. Objetivo del MVP

IKD PowerInsight será una plataforma profesional y auditable para la evaluación eléctrica preliminar y el apoyo a decisiones en establecimientos comerciales del sector alimentos.

El MVP deberá permitir representar una instalación eléctrica de baja tensión, incorporar información técnica con trazabilidad, ejecutar cálculos eléctricos verificables, aplicar reglas normativas versionadas, analizar escenarios y generar resultados y reportes reproducibles.

La plataforma apoyará el análisis del profesional sin sustituir su criterio, una inspección técnica, un diseño eléctrico completo ni los procesos oficiales de certificación.

## 2. Alcance funcional del MVP

El MVP incluirá:

### Modelado de la instalación

- organizaciones y establecimientos;
- suministro eléctrico;
- tableros;
- circuitos;
- fases;
- protecciones;
- conductores;
- equipos eléctricos;
- datos de placa;
- mediciones.

### Datos y trazabilidad

- ingreso manual de información;
- importación estructurada de mediciones;
- procedencia de los datos;
- estado de validación;
- nivel de confianza cuando corresponda;
- historial de cambios;
- trazabilidad entre entradas, cálculos, reglas y resultados.

### Cálculo eléctrico

- potencia activa, reactiva y aparente;
- corriente según topología eléctrica;
- tratamiento explícito de cargas y equipos;
- agregación por circuito, tablero y fase;
- análisis de carga;
- desbalance cuando existan datos suficientes;
- caída de tensión cuando existan los parámetros necesarios;
- verificaciones relacionadas con carga, conductor y protección;
- manejo explícito de condiciones no evaluables o fuera de alcance.

El motor de cálculo será determinístico, probado e independiente de la interfaz, la base de datos y los componentes de IA.

### Evaluación normativa

- reglas separadas del motor de cálculo;
- reglas identificadas y versionadas;
- asociación de cada regla con su fuente;
- registro de versión y vigencia;
- resultados reproducibles según el conjunto de reglas utilizado;
- posibilidad de determinar que una condición no puede evaluarse por falta de información.

Ninguna regla heredada se incorporará automáticamente sin revisión.

### Ingesta y OCR

- carga de imágenes de placas;
- preprocesamiento de imágenes;
- extracción asistida de información;
- normalización de campos;
- nivel de confianza;
- revisión humana;
- edición y confirmación antes de utilizar datos críticos.

La información extraída automáticamente no se considerará confirmada sin validación cuando pueda afectar una evaluación técnica.

### Mediciones

- registro de mediciones puntuales;
- importación de archivos estructurados;
- validación de unidades y rangos;
- diferenciación entre valores nominales, calculados y medidos;
- detección de inconsistencias entre información disponible.

### Escenarios y apoyo a decisiones

- creación de escenarios;
- incorporación o retiro de equipos;
- modificación de condiciones de carga;
- redistribución de circuitos cuando el modelo lo permita;
- comparación antes/después;
- optimización únicamente bajo restricciones explícitas;
- validación eléctrica y normativa posterior de cualquier escenario generado;
- explicación de recomendaciones.

### Consulta normativa asistida

- búsqueda sobre fuentes autorizadas;
- recuperación semántica de información;
- referencias a la fuente utilizada;
- respuesta con abstención cuando no exista evidencia suficiente.

La IA podrá recuperar, organizar y explicar información, pero no determinará por sí sola el cumplimiento normativo.

### API y persistencia

- API versionada;
- persistencia en PostgreSQL;
- migraciones controladas;
- auditoría de cambios;
- snapshots reproducibles de evaluaciones;
- separación entre dominio, aplicación e infraestructura.

### Interfaz

- flujo guiado para creación y evaluación de establecimientos;
- gestión del inventario eléctrico;
- revisión de datos extraídos;
- visualización de calidad de datos;
- visualización de resultados eléctricos;
- representación de la estructura de la instalación;
- análisis de escenarios;
- acceso a evidencia y trazabilidad;
- diseño responsive y accesible.

### Reportes

- generación de reportes técnicos;
- identificación de datos utilizados;
- resultados de cálculos;
- calidad y procedencia de información;
- reglas y versiones aplicadas;
- condiciones no evaluables;
- escenarios analizados;
- advertencias y limitaciones;
- identificación de la versión del software.

### Calidad y operación

- pruebas automatizadas;
- análisis estático;
- control de arquitectura;
- CI/CD;
- contenedores;
- gestión segura de secretos;
- despliegue reproducible;
- observabilidad básica;
- estrategia de backup y recuperación.

## 3. Uso de inteligencia artificial

La IA se utilizará únicamente cuando aporte valor verificable.

Usos previstos:

- OCR de placas;
- normalización asistida de información;
- recuperación semántica de documentación;
- explicación de resultados y evidencia;
- apoyo a la consulta de información normativa.

Los cálculos eléctricos, las reglas normativas y las restricciones críticas permanecerán fuera del control de modelos generativos.

El funcionamiento esencial de la plataforma no dependerá de la disponibilidad de un LLM, OCR o servicio externo de IA.

## 4. No-alcance del MVP

Quedan fuera del MVP:

- certificación RETIE;
- emisión de dictámenes oficiales;
- sustitución de inspecciones presenciales;
- diseño eléctrico detallado completo;
- firma o aprobación automática de diseños;
- ejecución automática de modificaciones sobre instalaciones;
- control automático de equipos;
- operación en tiempo real de instalaciones;
- protección o control industrial;
- estudios de arco eléctrico;
- estudios completos de cortocircuito sin información suficiente;
- coordinación completa de protecciones sin los datos requeridos;
- inferencia automática de circuitos o fases únicamente por posición física;
- confirmación automática de datos críticos extraídos mediante OCR;
- recomendaciones de intervención ejecutables sin revisión humana;
- predicción mediante ML del riesgo eléctrico sin un conjunto de datos representativo y un objetivo científicamente válido;
- entrenamiento de modelos complejos sin necesidad demostrada;
- microservicios como arquitectura inicial;
- Kafka, Spark, Kubernetes o gRPC sin una necesidad técnica demostrada.

## 5. Límites de responsabilidad

IKD PowerInsight proporcionará evaluación preliminar y apoyo técnico a decisiones.

Un resultado favorable no demostrará por sí mismo que una instalación cumple integralmente con la normativa ni que sea segura para una modificación.

Cuando falten datos críticos, existan contradicciones o el análisis exceda las capacidades implementadas, el sistema deberá indicarlo explícitamente en lugar de completar información mediante supuestos no justificados.

## 6. Criterios para incorporar nuevas funcionalidades

Una funcionalidad adicional podrá incorporarse cuando:

1. resuelva una necesidad real del producto;
2. esté dentro del dominio definido;
3. disponga de información suficiente para implementarse correctamente;
4. pueda probarse;
5. mantenga la trazabilidad requerida;
6. no comprometa los límites de responsabilidad del sistema;
7. su complejidad esté justificada por el valor que aporta.

Las funcionalidades que no cumplan estos criterios permanecerán fuera del MVP o pasarán al backlog de versiones posteriores.

## 7. Resultado de P0.2

El alcance funcional y técnico del MVP de IKD PowerInsight queda delimitado.

Las siguientes fases deberán respetar estas fronteras. Cualquier cambio significativo de alcance deberá documentarse y justificarse antes de modificar la arquitectura o incorporar nuevas dependencias.
