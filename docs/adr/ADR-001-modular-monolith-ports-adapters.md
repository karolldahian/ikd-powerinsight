# ADR-001: Modular Monolith with Ports & Adapters

- Status: Accepted
- Date: 2026-09-23
- Decision owners: IKD PowerInsight maintainers

## Context

IKD PowerInsight necesita una arquitectura que permita mantener separadas:

- la lógica de ingeniería eléctrica;
- los casos de uso;
- las integraciones externas;
- la persistencia;
- la API;
- OCR, IA y servicios cloud;
- la evolución futura del producto.

El núcleo eléctrico debe permanecer determinístico, auditable, testeable e independiente de frameworks.

El proyecto también necesita evitar complejidad innecesaria durante el MVP, por lo que una arquitectura distribuida basada en microservicios no está justificada en esta etapa.

## Decision

Se adopta un monolito modular siguiendo principios de arquitectura hexagonal y Ports & Adapters.

La estructura principal del backend será:

- domain: modelo de dominio y lógica eléctrica pura.
- ports: contratos abstractos para capacidades externas.
- pplication: casos de uso y orquestación.
- infrastructure: implementaciones concretas de persistencia, OCR, almacenamiento, IA y otros servicios externos.
- interfaces: adaptadores de entrada como FastAPI y futuras interfaces.

## Dependency direction

La dirección de dependencias debe mantenerse hacia el núcleo:

interfaces -> application -> domain

pplication -> ports

infrastructure -> ports/domain

El núcleo no debe depender de infraestructura.

En particular:

- domain no debe importar FastAPI, SQLAlchemy, OCR, servicios cloud ni frontend;
- pplication no debe depender de implementaciones concretas de infrastructure;
- los servicios externos deben accederse mediante Ports;
- los cálculos eléctricos deben permanecer en Python puro cuando sea posible.

## Rationale

Esta arquitectura permite:

- proteger la lógica eléctrica de dependencias externas;
- sustituir tecnologías de infraestructura sin reescribir el dominio;
- probar el núcleo de forma aislada;
- mantener trazabilidad entre entradas, reglas, cálculos y resultados;
- integrar OCR, RAG, base de datos, API y cloud de forma controlada;
- evolucionar el sistema sin introducir microservicios prematuramente.

## Enforcement

Las fronteras arquitectónicas se verifican mediante:

- Import Linter;
- Ruff;
- basedpyright;
- Pytest;
- pre-commit;
- revisión de cambios y GGA.

Las reglas específicas de Import Linter se mantienen en ackend/.importlinter.

## Consequences

### Positive

- Mayor separación de responsabilidades.
- Menor acoplamiento con frameworks.
- Mejor testabilidad.
- Mayor auditabilidad.
- Evolución gradual del sistema.
- Menor complejidad operativa que una arquitectura de microservicios.

### Trade-offs

- Requiere disciplina para mantener las fronteras entre capas.
- Puede añadir abstracciones adicionales mediante Ports.
- Algunas integraciones necesitarán adaptadores explícitos.
- El monolito crecerá y deberá mantenerse modular internamente.

## Rejected alternatives

### Monolithic framework-driven architecture

Se rechaza porque podría acoplar la lógica eléctrica a FastAPI, SQLAlchemy u otras tecnologías externas.

### Microservices

Se rechazan para el MVP porque aumentarían complejidad de despliegue, observabilidad, comunicación, seguridad y operación sin una necesidad demostrada.

### Direct infrastructure access from domain/application

Se rechaza porque reduciría testabilidad, auditabilidad y capacidad de sustitución tecnológica.

## Future review

Esta decisión deberá revisarse únicamente si aparecen necesidades reales como:

- escalado independiente de módulos;
- límites organizacionales claros entre equipos;
- requisitos de disponibilidad diferentes;
- cargas operativas que justifiquen separación física;
- evidencia de que el monolito modular ya no satisface los requisitos.

Hasta entonces, la arquitectura oficial de IKD PowerInsight será un modular monolith con Ports & Adapters.
