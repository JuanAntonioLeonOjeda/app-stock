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
              child: ColoredBox(color: toneColor(context, band.tone)),
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
    final values = [bands.first.from, for (final band in bands) band.to];
    final style = Theme.of(context).textTheme.labelSmall;
    return [
      for (final value in values)
        Positioned(
          top: _markerHeight + _barHeight + 4,
          left: (xOf(value) - _labelWidth / 2).clamp(0, width - _labelWidth),
          width: _labelWidth,
          child: Text(
            formatScaleValue(value, scale.unit),
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
    ];
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
    return 'Escala del motor: ${parts.join('; ')}';
  }
}
