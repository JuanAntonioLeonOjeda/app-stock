---
description: Usar imports absolutos (package:stock_app/...) en vez de rutas relativas ../../ dentro de app/lib/.
---

# Imports: `package:` absoluto, nunca `../../`

Dentro de `app/lib/`, **siempre** `import 'package:stock_app/...'` y nunca `import '../../...'`.

```dart
// MAL: se rompe, o hay que reescribirlo, en cuanto se mueve el archivo
import '../../../domain/entities/analysis_result.dart';

// BIEN: la misma ruta desde cualquier archivo
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
```

No hay excepciones, tampoco dentro del mismo directorio. Lo comprueba la regla
`always_use_package_imports` en `app/analysis_options.yaml` (ver `code-style.md`). Fuera de
`lib/` (p. ej. en los helpers compartidos de `test/`) el import relativo sigue siendo
válido.

## Por qué

- **Refactors seguros**: mover un archivo no rompe los imports de quien lo usa.
- **Encaja con la arquitectura hexagonal**: `.../domain/...` o `.../infrastructure/...` en el
  import dejan claro de un vistazo qué capa se importa (ver
  `.claude/rules/hexagonal-architecture.md`).
- **Evita un bug real de mezclar estilos**: un mismo archivo importado una vez de forma
  relativa y otra con `package:` puede tratarse como dos símbolos distintos.

## Qué NO hacer

- No mezclar estilos dentro del mismo archivo.
- No inventar un sistema de alias propio (constantes de ruta, etc.).
