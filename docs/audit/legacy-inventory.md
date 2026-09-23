# P0.1 — Inventario de funcionalidades heredadas y problemas conocidos

## 1. Propósito

Este documento registra las funcionalidades, limitaciones y problemas conocidos del proyecto base anterior que deben considerarse durante el desarrollo de IKD PowerInsight.

El inventario permite determinar qué conceptos pueden conservarse, cuáles deben rediseñarse y cuáles requieren validación técnica o normativa antes de incorporarse a la nueva plataforma.

## 2. Alcance del sistema heredado

El proyecto base consistía en una herramienta de evaluación eléctrica preliminar para establecimientos del sector alimentos.

Permitía recopilar información básica de la instalación y los equipos, realizar cálculos eléctricos, comparar la demanda estimada con la capacidad del interruptor principal, clasificar el resultado y generar recomendaciones para el usuario.

Su alcance era preliminar y no sustituía una inspección profesional, un diseño eléctrico detallado ni una certificación de la instalación.

## 3. Funcionalidades heredadas

| ID | Funcionalidad | Descripción | Decisión |
|---|---|---|---|
| LEG-01 | Captura de datos de la instalación | Registro del tipo de sistema, tensión, breaker principal y factor de potencia. | REDESIGN |
| LEG-02 | Inventario de equipos | Registro de nombre, cantidad, tensión, potencia, factor de potencia y clasificación de carga. | KEEP / REDESIGN |
| LEG-03 | Clasificación por tipo de carga | Clasificación de equipos en categorías como resistiva, motor, iluminación, electrónica, refrigeración y climatización. | REVIEW |
| LEG-04 | Factores de potencia predefinidos | Asignación de valores de factor de potencia según el tipo de carga. | REVIEW |
| LEG-05 | Clasificación de carga continua | Clasificación de equipos como continuos, no continuos o dependientes de sus condiciones de operación. | REVIEW |
| LEG-06 | Cálculo de potencia instalada | Cálculo a partir de las potencias nominales y cantidades de los equipos registrados. | KEEP / REDESIGN |
| LEG-07 | Factor de simultaneidad | Aplicación de un factor de simultaneidad para estimar la operación de cargas no continuas. | REVIEW |
| LEG-08 | Cálculo de potencia demandada | Estimación de la potencia de operación considerando cargas continuas y no continuas. | REDESIGN |
| LEG-09 | Cálculo de corriente | Cálculos diferenciados para sistemas monofásicos y trifásicos utilizando potencia, tensión y factor de potencia. | KEEP / REDESIGN |
| LEG-10 | Tratamiento de cargas continuas | Aplicación de un ajuste específico para cargas clasificadas como continuas. | REVIEW |
| LEG-11 | Evaluación del breaker principal | Comparación entre la corriente calculada y la capacidad nominal del interruptor principal. | KEEP / REDESIGN |
| LEG-12 | Margen disponible | Estimación de capacidad restante en amperios y potencia. | REDESIGN |
| LEG-13 | Escenarios de riesgo | Clasificación del resultado mediante rangos porcentuales y niveles de riesgo. | REVIEW |
| LEG-14 | Alerta para sistema monofásico | Generación de una alerta específica para determinadas condiciones de carga en sistemas monofásicos. | REVIEW |
| LEG-15 | Validación del breaker | Comparación del interruptor registrado con valores considerados estándar. | REVIEW |
| LEG-16 | Recomendación de conductor | Selección preliminar de calibre de conductor a partir de la corriente calculada. | REVIEW |
| LEG-17 | Recomendación de breaker | Selección preliminar de capacidad del interruptor a partir de la corriente calculada. | REVIEW |
| LEG-18 | Recomendaciones automáticas | Generación de recomendaciones técnicas según los resultados obtenidos. | REDESIGN |
| LEG-19 | Evaluación normativa | Asociación de cálculos, advertencias y recomendaciones con referencias normativas. | REVIEW |
| LEG-20 | Indicadores visuales | Uso de niveles e indicadores visuales para comunicar el resultado al usuario. | KEEP / REDESIGN |
| LEG-21 | Reporte PDF | Generación de un reporte con resultados, advertencias y recomendaciones. | KEEP / REDESIGN |
| LEG-22 | Evaluación de ampliaciones | Estimación preliminar de capacidad disponible antes de incorporar nuevas cargas. | KEEP / REDESIGN |

## 4. Problemas y limitaciones identificados

### LEG-BUG-01 — Acoplamiento entre cálculos y reglas normativas

El proyecto base relacionaba directamente determinados cálculos, umbrales y resultados con referencias normativas.

**Problema:** dificulta modificar o versionar las reglas sin afectar el motor de cálculo.

**Nuevo enfoque:** separar el motor de cálculo eléctrico del motor de reglas normativas.

### LEG-BUG-02 — Valores eléctricos predefinidos

Se utilizaban valores predeterminados de factor de potencia según categorías generales de equipos.

**Problema:** estos valores pueden no representar las características reales de un equipo específico.

**Nuevo enfoque:** priorizar datos de placa o mediciones y registrar la procedencia y confiabilidad de cada dato.

### LEG-BUG-03 — Factor de simultaneidad generalizado

Se utilizaba un único método para estimar la simultaneidad de las cargas no continuas.

**Problema:** su aplicabilidad puede variar según el tipo de instalación, equipo y condiciones reales de operación.

**Nuevo enfoque:** no incorporar este método hasta verificar su fundamento y condiciones de aplicación.

### LEG-BUG-04 — Umbrales de riesgo definidos directamente

La clasificación utilizaba rangos porcentuales predefinidos para determinar diferentes niveles de riesgo.

**Problema:** los umbrales pueden mezclar criterios técnicos, normativos y decisiones propias del proyecto.

**Nuevo enfoque:** las reglas y umbrales deberán estar identificados, justificados, versionados y asociados a evidencia verificable.

### LEG-BUG-05 — Evaluación centrada principalmente en el breaker principal

La capacidad del interruptor principal tenía un papel central en la evaluación general.

**Problema:** este dato por sí solo no representa las condiciones de conductores, circuitos, fases, protecciones, conexiones ni otros componentes de la instalación.

**Nuevo enfoque:** modelar la instalación con mayor nivel de detalle y mantener explícitas las limitaciones de cada evaluación.

### LEG-BUG-06 — Dependencia de datos nominales

Los cálculos utilizaban principalmente información nominal de los equipos.

**Problema:** los valores nominales no representan necesariamente el comportamiento real de la instalación durante su operación.

**Nuevo enfoque:** diferenciar claramente entre datos nominales, calculados y medidos.

### LEG-BUG-07 — Trazabilidad limitada

El proyecto base no contemplaba una trazabilidad completa entre los datos utilizados, cálculos ejecutados, reglas aplicadas y resultados obtenidos.

**Nuevo enfoque:** cada resultado deberá poder reconstruirse mediante una cadena de trazabilidad:

`input → source → calculation → rule → version → result → evidence`

### LEG-BUG-08 — Manejo limitado de datos faltantes o contradictorios

No existía un modelo formal para representar información desconocida, pendiente de confirmación o conflictiva.

**Nuevo enfoque:** incorporar estados explícitos para controlar la calidad y confiabilidad de los datos antes de utilizarlos en una evaluación.

### LEG-BUG-09 — Modelo eléctrico simplificado

La evaluación estaba orientada principalmente a la carga total del establecimiento y al interruptor principal.

**Problema:** limita la representación de la estructura real de una instalación.

**Nuevo enfoque:** evolucionar hacia un modelo que permita representar suministro, tableros, circuitos, fases, protecciones, conductores, equipos y mediciones.

### LEG-BUG-10 — Referencias normativas pendientes de verificación

Las referencias normativas utilizadas en el proyecto base no se asumirán como válidas para la nueva plataforma.

**Nuevo enfoque:** verificar vigencia, fuente, versión, aplicabilidad e interpretación antes de incorporar cualquier regla normativa.

## 5. Elementos que requieren validación antes de reutilizarse

No se incorporarán directamente al nuevo sistema sin revisión:

- factores de potencia predefinidos;
- factores de simultaneidad;
- tratamiento y factores aplicados a cargas continuas;
- umbrales de clasificación de riesgo;
- reglas específicas para sistemas monofásicos;
- tablas de conductores;
- valores normalizados de breakers;
- criterios de dimensionamiento;
- referencias normativas;
- recomendaciones automáticas derivadas de reglas no verificadas.

## 6. Elementos conceptuales que se conservarán

Se conserva como base conceptual:

- evaluación eléctrica preliminar;
- enfoque inicial en establecimientos del sector alimentos;
- caracterización de la instalación;
- inventario de equipos eléctricos;
- cálculo de magnitudes eléctricas;
- análisis de capacidad disponible;
- evaluación de posibles ampliaciones;
- presentación comprensible de resultados;
- generación de advertencias y recomendaciones;
- generación de reportes;
- delimitación clara entre evaluación preliminar y evaluación profesional.

Estos elementos serán rediseñados cuando sea necesario para integrarlos a la arquitectura y los requisitos de IKD PowerInsight.

## 7. Decisión de migración

El proyecto base se utilizará como referencia funcional y conceptual, pero no como implementación técnica que deba trasladarse directamente.

Los componentes eléctricos, normativos y de software serán reconstruidos progresivamente con:

- separación entre cálculos y reglas;
- datos estructurados y trazables;
- validación de unidades;
- control de procedencia y calidad de datos;
- reglas normativas versionadas;
- pruebas automatizadas;
- resultados reproducibles;
- manejo explícito de información insuficiente;
- arquitectura modular;
- auditoría de resultados.

## 8. Resultado de P0.1

Se identificaron las principales funcionalidades, limitaciones y decisiones técnicas heredadas del proyecto base.

Las funcionalidades útiles se conservarán como requisitos conceptuales, mientras que los cálculos, reglas, tablas, constantes y referencias normativas deberán ser revisados antes de su implementación.

Con este inventario, P0.1 queda preparado para cierre y se puede continuar con P0.2 — Congelar alcance MVP y no-alcance.