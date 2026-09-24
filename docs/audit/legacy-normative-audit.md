# P0.6 — Auditoría de referencias normativas heredadas

## Objetivo

Identificar las referencias y reglas normativas utilizadas en el proyecto base y determinar su tratamiento antes de incorporarlas a IKD PowerInsight.

## Estados

- `KEEP`: referencia verificada y reutilizable.
- `CHANGE`: concepto potencialmente válido, pero la referencia, formulación o implementación debe actualizarse.
- `REMOVE`: no debe trasladarse al nuevo sistema.
- `UNKNOWN`: requiere verificación antes de tomar una decisión.

## Matriz de auditoría

| Referencia o criterio heredado | Uso anterior | Estado | Acción |
|---|---|---|---|
| RETIE Resolución 40117 de 2024 | Marco normativo principal | CHANGE | Sustituir como referencia vigente por el RETIE actualmente registrado; conservar únicamente para trazabilidad histórica |
| RETIE Art. 3.27.3 | Protección, alimentadores y análisis de carga | UNKNOWN | Localizar el requisito equivalente en la versión vigente antes de implementar reglas |
| RETIE Art. 3.27.3.a | Justificación de criterios asociados a carga y riesgo | UNKNOWN | Verificar texto, alcance y aplicabilidad |
| RETIE Art. 3.27.3.d | Protección y relación con conductores | UNKNOWN | Verificar contra la versión vigente |
| RETIE Art. 3.1.1.1 | Conformidad y criterios utilizados en cálculos/recomendaciones | UNKNOWN | Verificar referencia y alcance actual |
| RETIE Art. 1.5.1.3 | Justificación del factor de simultaneidad | UNKNOWN | No reutilizar hasta demostrar que respalda realmente la fórmula aplicada |
| RETIE Tabla 1.5.1.3 | Clasificación de riesgos eléctricos | UNKNOWN | Revisar versión vigente y evitar convertir una tabla normativa en una escala propia sin justificación |
| RETIE Art. 3.2.1 | Personal competente | UNKNOWN | Verificar referencia equivalente vigente |
| NTC 2050 Art. 220-3.a | Cargas continuas y factor del 125 % | UNKNOWN | Verificar directamente en la Segunda Actualización y sus fe de erratas |
| NTC 2050 Art. 220-10.b | Cargas continuas y factor del 125 % | UNKNOWN | Verificar numeración, texto y aplicabilidad actual |
| NTC 2050 Art. 220-3.c | Potencia nominal de equipos | UNKNOWN | Verificar en fuente autorizada |
| NTC 2050 Art. 230-90 | Protección de acometida contra sobrecarga | UNKNOWN | Verificar en fuente autorizada |
| NTC 2050 Art. 240-3 | Protección contra sobrecorriente | UNKNOWN | Verificar numeración y alcance en la Segunda Actualización |
| NTC 2050 Art. 240-6 | Valores estándar de interruptores | UNKNOWN | Verificar tabla/listado vigente y excepciones antes de usarlo |
| NTC 2050 Art. 310-15 | Ampacidad de conductores | UNKNOWN | Replantear considerando material, aislamiento, temperatura, terminales y factores de corrección |
| NTC 2050 Tabla 310-16 | Selección referencial de conductor | UNKNOWN | No reutilizar como lookup simplificado hasta verificar versión y condiciones de aplicación |
| FS = 1 / sqrt(n) | Factor general de simultaneidad para cargas no continuas | REMOVE | No trasladar como regla normativa general sin una fuente y condiciones de aplicación demostrables |
| Clasificación fija de equipos como continuos/no continuos | Clasificación automática por tipo de equipo | CHANGE | Modelar continuidad según condiciones reales de operación y evidencia disponible |
| 125 % aplicado globalmente a cargas continuas | Corriente de diseño | CHANGE | Mantener el concepto sujeto a verificación, pero eliminar su aplicación global sin contexto |
| %Uso = I_diseño / I_breaker × 100 | Indicador de utilización | CHANGE | Mantener como indicador matemático cuando proceda, separado de cualquier conclusión normativa automática |
| >100 % = “Sobrecarga crítica” | Escenario de riesgo | CHANGE | Separar el hecho calculado de la clasificación normativa y validar condiciones reales |
| 81–100 % = riesgo alto | Escenario de riesgo | REMOVE | No tratar este rango como clasificación normativa general |
| 61–80 % = advertencia/moderado | Escenario de riesgo | REMOVE | No tratar este rango como clasificación normativa general |
| 41–60 % = operación normal | Escenario de riesgo | REMOVE | No inferir seguridad general únicamente del porcentaje de utilización del breaker |
| <40 % = sistema holgado/mínimo riesgo | Escenario de riesgo | REMOVE | No inferir condición segura ni capacidad de ampliación solo con este indicador |
| >5 kW o >8 kW monofásico → evaluar trifásico | Recomendación de migración | UNKNOWN | Verificar origen, operador de red, nivel de tensión y condiciones antes de formular una regla |
| Selección automática de conductor solo por corriente | Dimensionamiento preliminar | REMOVE | El nuevo motor deberá exigir las variables necesarias y declarar NOT_EVALUABLE cuando falten |
| Selección automática de breaker solo por corriente calculada | Dimensionamiento preliminar | REMOVE | No dimensionar protección ignorando conductor, carga, equipo, condiciones y reglas aplicables |
| “Capacidad adicional” en kW derivada solo del margen del breaker | Recomendación de ampliación | REMOVE | No interpretar el margen del interruptor como capacidad disponible completa de la instalación |

## Decisiones

### Se conserva

Se conserva como conocimiento conceptual:

- distinguir cargas y condiciones de operación;
- calcular magnitudes eléctricas mediante métodos determinísticos;
- comparar resultados con características de protecciones cuando existan datos suficientes;
- evaluar conductor, protección y carga de forma relacionada;
- advertir cuando faltan datos;
- mantener el carácter preliminar de la evaluación.

Esto no implica conservar automáticamente las referencias normativas ni las fórmulas heredadas.

### Se modifica

Las reglas heredadas que representen conceptos técnicamente útiles deberán reconstruirse a partir de:

1. fuentes vigentes;
2. condiciones explícitas de aplicación;
3. variables suficientes;
4. unidades controladas;
5. reglas versionadas;
6. pruebas reproducibles.

### Se elimina

No se trasladarán al nuevo sistema:

- escalas de riesgo basadas únicamente en porcentaje de utilización del breaker;
- factores generales de simultaneidad sin fundamento verificable;
- selección simplificada de conductor o protección;
- afirmaciones de seguridad derivadas de una sola variable;
- recomendaciones de ampliación basadas únicamente en margen de corriente;
- referencias heredadas asumidas como vigentes sin revisión.

## Regla para P4

Una referencia marcada `UNKNOWN` no podrá convertirse en una regla normativa de producción.

Para pasar a `KEEP` o `CHANGE` deberá existir:

- fuente autorizada;
- versión identificada;
- ubicación precisa dentro de la fuente;
- interpretación documentada;
- condiciones de aplicación;
- prueba asociada;
- revisión humana.

## Resultado

La lógica normativa del proyecto base queda desacoplada del nuevo desarrollo.

IKD PowerInsight podrá reutilizar conceptos técnicos útiles, pero las referencias, umbrales y reglas deberán reconstruirse y validarse contra las fuentes registradas antes de incorporarse al motor normativo.
