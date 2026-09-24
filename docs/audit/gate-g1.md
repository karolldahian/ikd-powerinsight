# P0.8 — Gate G1: aprobación normativa y de alcance

## Estado

APPROVED

## Objetivo

Confirmar que IKD PowerInsight cuenta con una base suficiente de alcance, fuentes y control de riesgos para continuar el desarrollo sin trasladar automáticamente reglas normativas del proyecto base.

## Checklist de aprobación

### Alcance

- [x] Se inventariaron las funcionalidades y limitaciones del proyecto base.
- [x] Se definió el alcance del MVP.
- [x] Se definió explícitamente el no-alcance.
- [x] Se establecieron límites para el uso de IA.
- [x] Se mantuvo el carácter de evaluación eléctrica preliminar.

### Fuentes normativas

- [x] Se verificó la referencia RETIE vigente utilizada por el proyecto.
- [x] Se identificaron los documentos oficiales asociados al RETIE.
- [x] Se verificó el acceso oficial a la NTC 2050 Segunda Actualización.
- [x] Se identificó la necesidad de considerar sus fe de erratas.
- [x] Se definieron restricciones para almacenar y reutilizar contenido sujeto a licencia.
- [x] Se creó un registro central de normas, fuentes y licencias.

### Auditoría del proyecto base

- [x] Se identificaron referencias normativas heredadas.
- [x] Se clasificaron mediante KEEP, CHANGE, REMOVE o UNKNOWN.
- [x] Se determinó que ninguna referencia heredada será considerada vigente automáticamente.
- [x] Se identificaron simplificaciones que no deberán trasladarse al nuevo motor.
- [x] Se estableció que las referencias UNKNOWN no podrán convertirse en reglas de producción.

### Riesgos

- [x] Se creó el risk register inicial.
- [x] Se identificaron riesgos técnicos.
- [x] Se identificaron riesgos normativos.
- [x] Se identificaron riesgos legales.
- [x] Se identificaron riesgos relacionados con datos.
- [x] Se identificaron riesgos de OCR e IA.
- [x] Se definieron riesgos bloqueantes.

## Decisiones de G1

A partir de este gate:

1. El desarrollo puede continuar con arquitectura, dominio, persistencia, interfaces y demás infraestructura del sistema.

2. Los cálculos eléctricos deberán implementarse como lógica determinística, reproducible y testeable.

3. El motor de cálculo eléctrico y el motor normativo permanecerán separados.

4. Ninguna referencia normativa heredada será implementada automáticamente.

5. Una regla normativa solo podrá formalizarse cuando disponga de fuente autorizada, versión, ubicación, condiciones de aplicación, pruebas y revisión.

6. Cuando los datos necesarios no estén disponibles, el sistema deberá poder responder con estados como `NOT_EVALUABLE`, `OUT_OF_SCOPE` o `CONFLICT` en lugar de inventar resultados.

7. La IA no podrá sustituir cálculos eléctricos, reglas normativas ni revisión profesional.

8. El OCR no podrá convertir automáticamente datos críticos extraídos en datos confirmados.

9. La NTC 2050 completa no se almacenará ni distribuirá en el repositorio público.

10. Los resultados deberán conservar trazabilidad suficiente para reconstruir datos, método, reglas, versiones y resultado.

## Restricciones que continúan abiertas

La aprobación de G1 no significa que todas las reglas eléctricas o normativas estén validadas.

Continúan pendientes para sus fases correspondientes:

- verificación individual de requisitos antes de crear reglas normativas;
- construcción y validación del motor eléctrico;
- golden cases independientes;
- pruebas de propiedades e invariantes;
- revisión de reglas por fuente y versión;
- validación eléctrica independiente antes de producción;
- revisión de nuevas versiones o modificaciones normativas.

## Evidencia de P0

La aprobación se sustenta en:

- `docs/audit/legacy-inventory.md`
- `docs/audit/mvp-scope.md`
- `docs/audit/retie-2026-verification.md`
- `docs/audit/ntc2050-access.md`
- `docs/audit/source-registry.md`
- `docs/audit/legacy-normative-audit.md`
- `docs/audit/risk-register.md`

## Resultado

**Gate G1: APPROVED**

P0 — Auditoría y congelamiento de alcance queda listo para cierre.

IKD PowerInsight puede continuar con las siguientes fases respetando las restricciones y controles definidos durante P0.
