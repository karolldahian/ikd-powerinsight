# Método de desbalance de carga

## Alcance

Este método calcula un fact descriptivo de desbalance entre las cargas de las fases L1, L2 y L3.

No representa por sí mismo cumplimiento o incumplimiento normativo y no aplica umbrales de aceptación.

## Entradas

Se requieren exactamente tres PhaseLoadFact:

- uno para L1;
- uno para L2;
- uno para L3.

Las cargas deben provenir de contribuciones explícitas por fase. El método no distribuye automáticamente cargas multifásicas.

## Método

1. Se normalizan las tres potencias a la unidad canónica de potencia.
2. Se calcula la potencia promedio de fase.
3. Se calcula la desviación absoluta de cada fase respecto al promedio.
4. Se toma la mayor desviación.
5. El porcentaje de desbalance se calcula como:

   maximum_deviation / average_phase_power * 100

Si las tres cargas son cero, el desbalance se define como 0 % para evitar una división por cero.

## Salidas

LoadUnbalanceFact contiene:

- average_phase_power;
- maximum_deviation;
- unbalance_percent.

## Limitaciones

- No infiere fases faltantes.
- No redistribuye carga.
- No aplica criterios normativos.
- No clasifica el resultado como aceptable o no aceptable.
