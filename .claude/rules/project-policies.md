---
description: Descripción del proyecto (app Flutter sin backend por ahora), arquitectura hexagonal + SDD, comandos, secretos y qué no hacer.
---

# Política y contexto del proyecto

## Qué es esto

**stock_app** es una app Flutter (iOS + Android) para aprender a invertir en bolsa. El
usuario busca una acción y recibe un diagnóstico (veredicto, nota por bloques, confianza y
avisos) que calcula un motor programático y determinista, sin IA en tiempo de ejecución.
Cada métrica va acompañada de contenido educativo que explica qué mide y cómo leerla. La
app explica; no recomienda comprar ni vender.

Todo el código vive en `app/` (paquete `stock_app`). **De momento no hay backend**: el
motor de análisis, el proveedor de datos (TradingView) y la caché se ejecutan dentro de
la app, en Dart. Como el proveedor está detrás de un port, pasar más adelante a un backend
propio solo requiere cambiar el adapter, sin tocar el motor.

Skills del dominio: `motor-analisis` (lógica de análisis), `datos-mercado` (proveedor y
caché) y `contenido-educativo` (textos didácticos).

## Arquitectura: hexagonal (ports & adapters) + Spec-Driven Development

Cada feature en `app/lib/features/<nombre>/` se organiza en 4 capas (domain,
application, infrastructure y presentation). La regla de dependencia y el naming están en
`.claude/rules/hexagonal-architecture.md`; el estilo de código, en
`.claude/rules/code-style.md`.

**Ninguna feature se implementa directamente desde una petición.** Primero pasa por
`specs/<feature>/` (spec → plan → tasks), siguiendo
`.claude/workflows/spec-driven-feature.md`. El código es la consecuencia del spec, no al
revés.

**Regla de dependencia entre features:** una feature puede depender de `app/lib/core/`,
nunca de otra feature directamente.

## Cuándo usar cada mecanismo de `.claude/` (para no crear ruido)

- **Skill** (`.claude/skills/`): patrón de dominio que no es obvio. Hay tres:
  `motor-analisis`, `datos-mercado` y `contenido-educativo`.
- **Agent** (`.claude/agents/`): tarea repetitiva que conviene delegar en un contexto
  aislado. Hay dos: `flutter-reviewer` (específico del proyecto) y `code-reviewer`
  (genérico: seguridad y corrección).
- **Command** (`.claude/commands/`): secuencia corta que se invoca a mano y siempre es igual.
- **Rule** (`.claude/rules/`): convenciones que se aplican siempre y en todas las features
  (este archivo es un ejemplo).
- **Workflow** (`.claude/workflows/`): secuencia de varios pasos que puede delegar en
  varios subagentes. Hay una: `spec-driven-feature`.

## Comandos

Desde `app/`:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run
```

## Despliegue

```bash
flutter build appbundle --release   # Android, formato Google Play
flutter build apk --release         # Android, APK suelto
flutter build ios --release         # iOS, requiere macOS + Xcode
```

## Secretos

- De momento no hay clave de API: TradingView no la necesita. Si un proveedor futuro la
  necesita, se inyecta al compilar con `--dart-define-from-file` (archivo no versionado) y
  se lee con `String.fromEnvironment`.
- Nunca se escribe una clave en el código ni en archivos versionados.
- **Limitación asumida:** TradingView se consulta por sus endpoints no oficiales (sin
  garantías ni licencia para un producto público). Solo es aceptable mientras la app sea
  de uso personal. **Antes de publicarla en una tienda hace falta un proveedor con licencia
  y un backend propio** (ver skill `datos-mercado`).

## Qué NO hacer

- No implementar una feature sin haber escrito antes `specs/<feature>/spec.md` y `plan.md`
  (ver el workflow `spec-driven-feature`).
- No violar la regla de dependencia hexagonal: `domain/` nunca importa Flutter, `http` ni
  paquetes externos. Ver `.claude/rules/hexagonal-architecture.md`.
- No llamar a la API de datos fuera de su adapter en `infrastructure/`.
- No publicar la app en tiendas mientras consulte fuentes no oficiales.
- No generar textos con IA en tiempo de ejecución: el contenido educativo es estático.
- No afirmar en la app que una acción concreta sea buena compra.
- No importar código de una feature desde otra: pasar por `app/lib/core/` o plantearse si
  de verdad son la misma responsabilidad.
- No mover nada a `app/lib/core/` por adelantado: solo cuando una segunda feature lo
  necesite de verdad.
- No crear contenido en `.claude/agents/`, `commands/` o `rules/` solo para llenar la
  carpeta: cada una se llena cuando aparece la necesidad real.
