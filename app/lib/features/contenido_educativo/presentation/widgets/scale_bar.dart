import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/scale_bands.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/presentation/scale_formatting.dart';
import 'package:stock_app/features/contenido_educativo/presentation/tone_style.dart';

/// Barra con los tramos de la escala del motor coloreados (criterios 77-78).
///
/// Es orientativa: dice cómo puntúa el motor, no si una empresa es buena. Con
/// [markerValue] pinta una flecha donde cae ese valor (el del simulador).
class ScaleBar extends StatelessWidget {
  const ScaleBar({super.key, required this.scale, this.markerValue});

  final ReadingScale scale;
  final double? markerValue;

  static const _barHeight = 18.0;
  static const _markerHeight = 18.0;
  static const _labelWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final bands = bandsFor(scale);
    final min = bands.first.from;
    final max = bands.last.to;
    return Semantics(
      label: _description(bands),
      container: true,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            double xOf(double value) =>
                width * ((value.clamp(min, max) - min) / (max - min));
            return SizedBox(
              height: _markerHeight + _barHeight + 24,
              child: Stack(
                children: [
                  _bar(context, bands, xOf),
                  ..._boundaryLabels(context, bands, xOf, width),
                  if (markerValue case final value?)
                    _marker(context, xOf(value)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _bar(
    BuildContext context,
    List<ScaleBand> bands,
    double Function(double) xOf,
  ) => Positioned(
    top: _markerHeight,
    left: 0,
    right: 0,
    height: _barHeight,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(_barHeight / 2),
      child: Stack(
        children: [
          for (final band in bands)
            Positioned(
              left: xOf(band.from),
              width: xOf(band.to) - xOf(band.from),
              top: 0,
              bottom: 0,
              child: _BandSwatch(
                tone: band.tone,
                width: xOf(band.to) - xOf(band.from),
              ),
            ),
        ],
      ),
    ),
  );

  List<Widget> _boundaryLabels(
    BuildContext context,
    List<ScaleBand> bands,
    double Function(double) xOf,
    double width,
  ) {
    final values = _visibleBoundaries(
      [bands.first.from, for (final band in bands) band.to],
      xOf,
      width,
    );
    final style = Theme.of(context).textTheme.labelSmall;
    return [
      for (final value in values)
        Positioned(
          top: _markerHeight + _barHeight + 4,
          left: _labelLeft(value, xOf, width),
          width: _labelWidth,
          child: Text(
            formatScaleValue(value, scale.unit),
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
    ];
  }

  /// Posición izquierda de la etiqueta de [value], sin salirse de la barra.
  double _labelLeft(double value, double Function(double) xOf, double width) =>
      (xOf(value) - _labelWidth / 2).clamp(0, width - _labelWidth);

  /// Fronteras cuyas etiquetas no se pisan: se mantiene siempre la primera y
  /// la última, y se descartan las intermedias que chocarían con ellas.
  List<double> _visibleBoundaries(
    List<double> values,
    double Function(double) xOf,
    double width,
  ) {
    double left(double value) => _labelLeft(value, xOf, width);
    bool fitsAfter(double previous, double value) =>
        left(value) - left(previous) >= _labelWidth;
    final kept = <double>[values.first];
    for (final value in values.skip(1)) {
      final isLast = identical(value, values.last);
      if (isLast) {
        while (kept.length > 1 && !fitsAfter(kept.last, value)) {
          kept.removeLast();
        }
        kept.add(value);
      } else if (fitsAfter(kept.last, value)) {
        kept.add(value);
      }
    }
    return kept;
  }

  Widget _marker(BuildContext context, double x) => Positioned(
    top: 0,
    left: x - _markerHeight / 2,
    child: Icon(
      Icons.arrow_drop_down,
      size: _markerHeight * 1.4,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );

  /// Lo que lee un lector de pantalla en lugar de la barra.
  String _description(List<ScaleBand> bands) {
    final parts = [
      for (final band in bands)
        '${toneLabel(band.tone).toLowerCase()} de '
            '${formatScaleValue(band.from, scale.unit)} a '
            '${formatScaleValue(band.to, scale.unit)}',
    ];
    final marker = markerValue;
    final here = marker == null
        ? ''
        : '. Valor actual: ${formatScaleValue(marker, scale.unit)}, '
              '${toneLabel(toneAt(scale, marker)).toLowerCase()}';
    return 'Escala del motor: ${parts.join('; ')}$here';
  }
}

/// Un tramo coloreado con su icono, para que el color no sea la única pista.
class _BandSwatch extends StatelessWidget {
  const _BandSwatch({required this.tone, required this.width});

  final Tone tone;
  final double width;

  /// Ancho mínimo para que quepa el icono sin tocar los bordes.
  static const _minWidthForIcon = 28.0;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: toneColor(context, tone),
    child: width < _minWidthForIcon
        ? null
        : Center(
            child: Icon(
              toneIcon(tone),
              size: 14,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
  );
}
