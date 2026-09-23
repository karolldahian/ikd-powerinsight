# Registro de normas, fuentes y licencias

Este registro centraliza las fuentes normativas y técnicas controladas utilizadas por IKD PowerInsight.

## Estados

- `CURRENT`: fuente vigente verificada.
- `HISTORICAL`: fuente conservada únicamente para trazabilidad.
- `PENDING`: fuente pendiente de verificación.
- `RESTRICTED`: acceso o reutilización sujetos a licencia o autorización.

## Registro

| ID | Fuente | Emisor | Estado | Acceso | Uso en el proyecto |
|---|---|---|---|---|---|
| RETIE-2026 | RETIE — Resolución 40284 del 23 de junio de 2026 | Ministerio de Minas y Energía | CURRENT | Público oficial | Fuente normativa primaria |
| RETIE-2026-L1 | Libro 1 — Aspectos Generales | Ministerio de Minas y Energía | CURRENT | Público oficial | Referencia normativa |
| RETIE-2026-L2 | Libro 2 — Productos objeto del RETIE | Ministerio de Minas y Energía | CURRENT | Público oficial | Referencia normativa |
| RETIE-2026-L3 | Libro 3 — Instalaciones objeto del RETIE | Ministerio de Minas y Energía | CURRENT | Público oficial | Referencia normativa |
| RETIE-2026-L4 | Libro 4 — Evaluación de la conformidad | Ministerio de Minas y Energía | CURRENT | Público oficial | Referencia normativa |
| RETIE-2026-ANNEX | Anexos de la Resolución 40284 de 2026 | Ministerio de Minas y Energía | CURRENT | Público oficial | Referencia normativa |
| RETIE-2024 | Resolución 40117 de 2024 | Ministerio de Minas y Energía | HISTORICAL | Público oficial | Trazabilidad y comparación |
| NTC2050-2 | NTC 2050 — Código Eléctrico Colombiano, Segunda Actualización | ICONTEC | CURRENT / RESTRICTED | Licencia oficial | Fuente técnica controlada |
| NTC2050-ERRATA | Fe de erratas de la NTC 2050 Segunda Actualización | ICONTEC | CURRENT | Público oficial | Correcciones aplicables |

## Reglas de uso

1. Toda regla normativa implementada debe apuntar a una fuente registrada.
2. La fuente debe indicar versión y estado.
3. Una fuente histórica no puede utilizarse como vigente sin nueva verificación.
4. Las fuentes restringidas no se copiarán ni distribuirán sin autorización.
5. Ninguna referencia heredada se considerará válida automáticamente.
6. Las fe de erratas aplicables deben revisarse antes de formalizar reglas.
7. Los cambios de fuente o versión deberán quedar trazados.
8. Las reglas normativas deberán mantenerse separadas del motor de cálculo.

## Control de contenido

Los documentos públicos oficiales podrán utilizarse respetando sus condiciones de publicación y reutilización.

Los documentos sujetos a licencia, como la NTC 2050, no se almacenarán completos en el repositorio público ni se incorporarán íntegramente al RAG sin autorización suficiente.

## Trazabilidad

Este registro será utilizado como referencia para:

- auditoría de referencias heredadas;
- formalización de reglas;
- control de versiones normativas;
- RAG normativo;
- monitoreo de cambios normativos;
- evidencia de auditoría.

## Mantenimiento

Cuando una fuente cambie:

1. no se sobrescribirá silenciosamente su versión anterior;
2. se registrará la nueva versión;
3. se identificará la fuente anterior como histórica cuando corresponda;
4. se analizará el impacto sobre reglas existentes;
5. cualquier cambio de reglas deberá pasar por revisión y pruebas.
