# Spec: ajustes

> Estado: cerrada (2026-10-20).

## Qué resuelve

Quiero elegir si la app se ve clara u oscura sin depender del ajuste del móvil. Hoy sigue
siempre el modo del sistema (`ThemeMode.system`). Esta feature añade un interruptor de
tema con tres opciones —Sistema, Claro y Oscuro— que se recuerda entre sesiones. Por
defecto es **Sistema**, así que quien no lo toque no nota ningún cambio.

## Fuera de alcance

- Otros ajustes (idioma, moneda por defecto, notificaciones...): cada uno tendrá su spec.
- Una pantalla de ajustes: por ahora es un solo control en la barra de la portada.
- Elegir colores o fuentes.
- Sincronizar la preferencia entre dispositivos.

## Criterios de aceptación

1. **Dado** que nunca he elegido tema, **cuando** abro la app, **entonces** sigue el modo
   claro u oscuro del sistema.
2. **Dado** la portada, **cuando** pulso el icono de tema, **entonces** veo tres opciones
   (Sistema, Claro, Oscuro) y la elegida aparece marcada.
3. **Dado** el menú de tema, **cuando** elijo Claro u Oscuro, **entonces** toda la app
   cambia al instante y se queda así aunque el sistema use el otro modo.
4. **Dado** que elegí Sistema, **cuando** cambia el modo del sistema, **entonces** la app
   lo sigue.
5. **Dado** que elegí un tema, **cuando** cierro y vuelvo a abrir la app, **entonces**
   conserva mi elección.
6. **Dado** un archivo de ajustes ausente, corrupto, de otra versión o con un valor
   desconocido, **cuando** abro la app, **entonces** se usa Sistema, sin error.
7. **Dado** que no se puede escribir el archivo (disco lleno), **cuando** elijo un tema,
   **entonces** cambia igualmente en esta sesión y la app no falla.
8. **Dado** el icono de tema, **entonces** refleja la opción activa y tiene etiqueta de
   accesibilidad.
