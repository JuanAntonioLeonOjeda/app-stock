# stock_app

App Flutter (iOS y Android) para aprender a invertir en bolsa. Buscas una acción y
recibe un diagnóstico (veredicto, nota por bloques, confianza y avisos) calculado por un
motor programático y determinista, sin IA en tiempo de ejecución. Cada métrica lleva su
explicación didáctica. La app explica; no recomienda comprar ni vender.

Todo el código vive en [`app/`](app/). Arquitectura hexagonal por features y desarrollo
guiado por specs (`specs/`); las convenciones están en [`AGENTS.md`](AGENTS.md).

## MAIN DEPENDENCIES
![Flutter](https://img.shields.io/badge/FLUTTER-3.47.5-02569B?style=for-the-badge&logo=flutter&logoColor=02569B)
![Dart](https://img.shields.io/badge/DART-3.13.4-0175C2?style=for-the-badge&logo=dart&logoColor=0175C2)
![HTTP](https://img.shields.io/badge/HTTP-1.6.0-0175C2?style=for-the-badge&logo=dart&logoColor=0175C2)
![FL Chart](https://img.shields.io/badge/FL%20CHART-1.2.0-0175C2?style=for-the-badge&logo=dart&logoColor=0175C2)
![Intl](https://img.shields.io/badge/INTL-0.20.3-0175C2?style=for-the-badge&logo=dart&logoColor=0175C2)
![Path Provider](https://img.shields.io/badge/PATH%20PROVIDER-2.1.6-0175C2?style=for-the-badge&logo=dart&logoColor=0175C2)
![URL Launcher](https://img.shields.io/badge/URL%20LAUNCHER-6.3.3-0175C2?style=for-the-badge&logo=dart&logoColor=0175C2)
![Cupertino Icons](https://img.shields.io/badge/CUPERTINO%20ICONS-1.0.9-0175C2?style=for-the-badge&logo=apple&logoColor=0175C2)
![Plus Jakarta Sans](https://img.shields.io/badge/PLUS%20JAKARTA%20SANS-FONT-4338CA?style=for-the-badge&logo=googlefonts&logoColor=4338CA)

## DEV DEPENDENCIES
![Flutter Test](https://img.shields.io/badge/FLUTTER%20TEST-SDK-02569B?style=for-the-badge&logo=flutter&logoColor=02569B)
![Flutter Lints](https://img.shields.io/badge/FLUTTER%20LINTS-6.0.0-0175C2?style=for-the-badge&logo=dart&logoColor=0175C2)

## COMMANDS

Desde `app/`:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run
flutter build apk --release
```
