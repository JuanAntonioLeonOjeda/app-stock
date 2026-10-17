---
description: Comprueba formato, análisis y tests y compila la app (por defecto, APK release de Android)
argument-hint: "[apk|appbundle|ios]"
allowed-tools: Bash, Read, Edit
---

# Build

Todo se ejecuta desde `app/` (paquete `stock_app`). El argumento elige el destino;
sin argumento, `apk`.

## 1. Comprobaciones previas (obligatorias)

```bash
cd app
dart format .
flutter analyze
flutter test
```

- Si `dart format` cambia archivos, es correcto: se dejan formateados.
- Si `flutter analyze` o `flutter test` fallan, **no compilar**: arreglar la causa
  (en el código, o en el test si el fallo es del propio test) y repetir. Si el arreglo no
  es obvio, parar y avisar al usuario con el error.

## 2. Compilación según el argumento

| Argumento | Comando | Salida |
|---|---|---|
| `apk` (por defecto) | `flutter build apk --release` | `app/build/app/outputs/flutter-apk/app-release.apk` |
| `appbundle` | `flutter build appbundle --release` | `app/build/app/outputs/bundle/release/app-release.aab` |
| `ios` | `flutter build ios --release` | requiere macOS + Xcode |

## 3. Informe final

Indicar la ruta completa del artefacto y su tamaño, y qué se arregló en el paso 1, si algo.
No hacer commit ni push: solo si el usuario lo pide.
