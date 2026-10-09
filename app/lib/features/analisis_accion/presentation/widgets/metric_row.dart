import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_guidance.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/guidance_tags.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/info_builder.dart';

/// Una métrica: etiqueta, valor, nota y nota explicativa (criterios 11-12), con
/// su explicación desplegable justo debajo (criterios 1-2b de
/// `contenido_educativo`): empieza oculta y cada fila se despliega por separado.
class MetricRow extends StatefulWidget {
  const MetricRow({super.key, required this.metric, this.buildInfo});

  final MetricResult metric;
  final InfoBuilder? buildInfo;

  @override
  State<MetricRow> createState() => _MetricRowState();
}

class _MetricRowState extends State<MetricRow> {
  bool _isInfoVisible = false;

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    final buildInfo = widget.buildInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          leading: buildInfo == null ? null : _infoButton(metric),
          title: Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(metric.label),
              if (isEssential(metric.id))
                const GuidanceTag(text: essentialTagText, icon: Icons.star),
              if (isInTradeRepublic(metric.id))
                const GuidanceTag(text: tradeRepublicTagText),
            ],
          ),
          subtitle: Text(
            [
              formatMetricValue(metric.value, metric.format),
              ?metric.note,
            ].join(' · '),
          ),
          trailing: Text(
            formatScore(metric.score),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (buildInfo != null)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _isInfoVisible
                ? buildInfo(context, metric.id)
                : const SizedBox(width: double.infinity),
          ),
      ],
    );
  }

  Widget _infoButton(MetricResult metric) => IconButton(
    tooltip: _isInfoVisible
        ? 'Ocultar qué es ${metric.label}'
        : 'Qué es ${metric.label}',
    isSelected: _isInfoVisible,
    icon: const Icon(Icons.info_outline),
    selectedIcon: const Icon(Icons.info),
    onPressed: () => setState(() => _isInfoVisible = !_isInfoVisible),
  );
}
