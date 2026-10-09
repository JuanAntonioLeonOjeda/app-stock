---
description: Funciones/métodos atómicos y aplicación práctica de SOLID en este proyecto Flutter/Dart.
---

# Funciones atómicas y SOLID

## Funciones atómicas

- Una función hace **una** cosa. Si hace falta una "y" para describirla
  (`validateAndSave()`), son dos funciones.
- Sin efectos secundarios ocultos: una función que calcula algo no debería, de paso, mutar
  estado externo ni hacer I/O. Si necesita las dos cosas, se separan en una función pura
  que calcula y otra que aplica el resultado. En el motor esto es obligatorio (ver skill
  `motor-analisis`, "Invariantes").
- Límite práctico: si un método pasa de unas 20-25 líneas o de 2-3 niveles de indentación,
  es candidato a dividirse en sub-funciones cuyo nombre explique cada paso. Ese nombre
  sustituye al comentario que ibas a escribir.
- Parámetros: más de 3-4 posicionales indica que conviene agruparlos en un objeto o usar
  parámetros con nombre.

## SOLID aplicado a este proyecto (no toda la teoría, solo lo accionable aquí)

**S: responsabilidad única.** Cada clase tiene un solo motivo para cambiar. Ej.: el
adapter de TradingView solo obtiene y normaliza datos; no puntúa ni decide veredictos.
Los cálculos no contienen umbrales: toda la opinión del motor vive en el módulo de reglas.

**O: abierto/cerrado.** Añadir una métrica o un proveedor no debería obligar a modificar
el código existente con `if (provider == 'tradingview')` repartidos por todo el código:
una métrica nueva es una entrada más en el módulo de reglas y un proveedor nuevo es otro
adapter del mismo port.

**L: sustitución de Liskov.** Cualquier implementación de `MarketDataPort` (TradingView,
FMP o un fake de test) debe respetar el mismo contrato: `StockData` normalizado,
`null` para lo ausente y los mismos errores tipados.

**I: segregación de interfaces.** No obligar a una clase a depender de métodos que no usa.
Si un use case solo necesita buscar símbolos, no debería recibir un port que además obtiene
estados financieros "por si acaso".

**D: inversión de dependencias.** Los ports se inyectan por constructor; no se instancian
escondidos dentro de un widget o de un use case (ver
`hexagonal-architecture.md`, "Inyección de dependencias").

## Cuándo NO aplicar esto al pie de la letra

SOLID es una guía, no un checklist que cumplir en cada archivo de 10 líneas. Para widgets
puramente de presentación y sin lógica no hace falta forzar una interfaz o una
abstracción: en un proyecto de este tamaño, la sobreingeniería sale tan cara como el
código desordenado.
