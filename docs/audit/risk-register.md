# P0.7 — Risk Register

## Objetivo

Registrar los principales riesgos técnicos, normativos, legales y de datos de IKD PowerInsight, junto con sus medidas de prevención y mitigación.

## Escala

### Probabilidad

- Baja
- Media
- Alta

### Impacto

- Bajo
- Medio
- Alto
- Crítico

## Registro de riesgos

| ID | Categoría | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|---|
| R-001 | Técnico | Error en una fórmula eléctrica produce resultados incorrectos | Media | Crítico | Motor determinístico, golden cases, property tests y revisión eléctrica independiente |
| R-002 | Técnico | Aplicar una fórmula fuera de sus condiciones válidas | Media | Crítico | Modelar prerrequisitos explícitos y devolver NOT_EVALUABLE cuando falten datos |
| R-003 | Técnico | Mezclar lógica normativa con cálculos eléctricos | Media | Alto | Mantener Electrical Engine y Rules Engine separados |
| R-004 | Técnico | Errores de unidades o conversiones | Media | Alto | Utilizar Pint, tipos explícitos y pruebas de unidades |
| R-005 | Técnico | Dependencias entre módulos rompen la arquitectura | Media | Medio | Ports & Adapters, Import Linter y ADR |
| R-006 | Técnico | Cambios de software alteran resultados previamente emitidos | Media | Alto | Snapshots, versionado de reglas, versión de software y pruebas de regresión |
| R-007 | Normativo | Utilizar una referencia RETIE desactualizada | Media | Crítico | Registro de fuentes, versionado y revisión antes de formalizar reglas |
| R-008 | Normativo | Interpretar incorrectamente un requisito normativo | Media | Crítico | Fuente primaria, interpretación documentada, pruebas y revisión humana |
| R-009 | Normativo | Reutilizar reglas del proyecto base sin validación | Alta | Crítico | Auditoría KEEP/CHANGE/REMOVE/UNKNOWN y bloqueo de UNKNOWN en producción |
| R-010 | Normativo | Cambio futuro del RETIE afecta reglas implementadas | Media | Alto | Versionar RuleSet, conservar effective_from y monitorear cambios |
| R-011 | Normativo | Aplicar una regla sin suficiente información de la instalación | Media | Crítico | Prerrequisitos y estados NOT_EVALUABLE / OUT_OF_SCOPE / CONFLICT |
| R-012 | Legal | Distribuir contenido protegido de la NTC 2050 | Media | Alto | No almacenar ni distribuir la norma completa; utilizar acceso autorizado |
| R-013 | Legal | Incorporar contenido restringido al RAG sin autorización | Media | Alto | Indexar únicamente fuentes con permisos compatibles |
| R-014 | Legal | Presentar el resultado como certificación o dictamen oficial | Baja | Crítico | Alcance explícito, disclaimers y lenguaje de evaluación preliminar |
| R-015 | Datos | Datos ingresados por el usuario son incorrectos o incompletos | Alta | Alto | Validación, provenance, DataStatus, Confidence y bloqueo de cálculos críticos |
| R-016 | Datos | Confundir datos nominales con mediciones reales | Media | Alto | Modelarlos como conceptos distintos y conservar origen del dato |
| R-017 | Datos | Inferir fase o circuito sin evidencia suficiente | Media | Alto | Exigir evidencia y permitir estados no confirmados |
| R-018 | Datos | Dataset externo tiene licencia incompatible | Media | Alto | Revisar licencia y documentar origen antes de utilizarlo |
| R-019 | Datos | Dataset externo no representa instalaciones reales del dominio | Alta | Medio | Utilizarlo solo para la tarea para la cual sea técnicamente válido |
| R-020 | OCR | OCR interpreta incorrectamente valores críticos de una placa | Alta | Alto | Confidence, validación de rangos y confirmación humana |
| R-021 | OCR | Confusión de unidades, decimales o símbolos | Alta | Alto | Normalización controlada y revisión antes de promover datos a CONFIRMED |
| R-022 | IA | Un LLM inventa una referencia normativa | Media | Crítico | RAG con citas, abstención y prohibición de usar LLM como motor normativo |
| R-023 | IA | Una explicación generativa contradice el resultado determinístico | Media | Alto | Los resultados del motor tienen prioridad y la IA solo explica evidencia existente |
| R-024 | IA | El sistema depende de un proveedor o modelo externo | Media | Medio | Ports, modelos intercambiables y funcionamiento del core sin IA |
| R-025 | Seguridad | Secretos o credenciales llegan al repositorio | Media | Alto | Variables de entorno, secret scanning y revisión de CI |
| R-026 | Seguridad | API expone información sensible de proyectos | Media | Alto | AuthPort, autorización, mínimos privilegios y pruebas de seguridad |
| R-027 | Persistencia | Migración de base de datos provoca pérdida o corrupción | Baja | Alto | Alembic, pruebas up/down y estrategia de backup/restore |
| R-028 | Operación | Fallo de infraestructura impide acceder a información histórica | Baja | Alto | Backups, almacenamiento persistente y procedimiento de recuperación |
| R-029 | UX | Usuario interpreta una recomendación preliminar como autorización para intervenir | Media | Crítico | Lenguaje explícito, evidencia visible y revisión profesional para acciones críticas |
| R-030 | Proyecto | Incorporar tecnologías innecesarias aumenta complejidad sin aportar valor | Media | Medio | Justificación de dependencias, ADR y mantener arquitectura mínima suficiente |
| R-031 | Proyecto | Scope creep impide terminar el MVP | Alta | Alto | Alcance congelado en P0.2 y nuevas funcionalidades sujetas a criterios de incorporación |
| R-032 | Auditoría | No poder reconstruir cómo se obtuvo un resultado histórico | Media | Crítico | Lineage completo: datos → método → regla → versión → resultado |

## Riesgos bloqueantes

Los siguientes riesgos pueden bloquear una funcionalidad o release cuando no estén controlados:

- resultados eléctricos no reproducibles;
- reglas normativas sin fuente vigente;
- referencias `UNKNOWN` utilizadas como reglas;
- datos críticos sin validación suficiente;
- contenido restringido utilizado sin autorización;
- OCR promoviendo automáticamente datos críticos;
- resultados generativos utilizados como decisión normativa;
- pérdida de trazabilidad entre entradas y resultados.

## Tratamiento

Cada riesgo podrá encontrarse en uno de estos estados:

- `OPEN`
- `MITIGATING`
- `ACCEPTED`
- `CLOSED`

Un riesgo crítico no deberá marcarse `ACCEPTED` únicamente para evitar implementar su mitigación.

## Revisión

El registro deberá revisarse cuando:

- se agregue una fuente normativa;
- cambie una norma;
- se incorpore un dataset;
- se agregue un modelo de IA;
- se modifique el motor eléctrico;
- se modifique el motor normativo;
- se agregue infraestructura relevante;
- se prepare una release.

## Resultado

IKD PowerInsight dispone de un registro inicial de riesgos que permite controlar decisiones técnicas, normativas, legales y de datos durante el desarrollo.

Los riesgos deberán convertirse en restricciones, pruebas, controles o decisiones explícitas cuando corresponda.
