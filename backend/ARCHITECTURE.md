# Backend architecture

IKD PowerInsight utiliza un monolito modular inspirado en Ports & Adapters.

## Layers

### domain

Contiene el modelo y la lógica de negocio y de ingeniería eléctrica.

Debe permanecer independiente de frameworks, bases de datos, APIs, OCR,
servicios cloud y demás infraestructura externa.

### ports

Define contratos y abstracciones necesarios para comunicarse con capacidades
externas.

Las implementaciones concretas de estos contratos viven fuera del núcleo.

### application

Contiene los casos de uso y la orquestación de la aplicación.

Puede depender de domain y ports, pero no debe depender de
infrastructure.

### infrastructure

Contiene implementaciones concretas de los Ports, como persistencia,
integraciones externas, almacenamiento, OCR y servicios de infraestructura.

Puede depender de domain y ports.

### interfaces

Contiene los puntos de entrada al sistema, como la API HTTP o futuras
interfaces de ejecución.

Debe delegar la lógica de negocio en pplication.

## Dependency direction

La dirección principal de dependencias es:

interfaces -> application -> ports/domain

infrastructure -> ports/domain

El núcleo no depende de infraestructura.

## Architectural principles

- Los cálculos eléctricos deben permanecer en Python puro.
- domain no debe importar FastAPI, SQLAlchemy, OCR, cloud ni frontend.
- pplication no debe importar implementaciones concretas de infraestructura.
- Los servicios externos se acceden mediante Ports.
- La infraestructura implementa Ports definidos por el núcleo.
- Las dependencias se conectarán posteriormente en el composition root.
- Las restricciones entre capas serán verificadas automáticamente con Import Linter.
