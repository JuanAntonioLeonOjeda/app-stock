import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/display_currency_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/currency_switch.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/verdict_badge.dart';

/// Cabecera del resultado (criterio 9): empresa, precio, veredicto, nota,
/// confianza, perfil y versión del motor.
class VerdictHeader extends StatelessWidget {
  const VerdictHeader({super.key, required this.result, this.display});

  final AnalysisResult result;

  /// Moneda en la que se ve el precio; sin ella, la original.
  final DisplayCurrencyController? display;

  /// El precio en la moneda que se ve, al tipo del día del cierre.
  String _priceText() {
    final price = result.price;
    final controller = display;
    if (price == null || controller == null || !controller.isInEuros) {
      return formatPrice(price, result.currency);
    }
    final day = result.lastCloseDate ?? controller.latestRate?.date;
    final converted = day == null ? null : controller.toDisplay(price, day);
    // Sin tipo para ese día, se enseña el precio original antes que "sin dato".
    if (converted == null) return formatPrice(price, result.currency);
    return formatPrice(converted, 'EUR');
  }

  /// Bolsa, ISIN y si es la cotización principal u otra (criterio 80). No sale
  /// en los análisis guardados antes de que se registrara (criterio 81).
  List<Widget> _listingLines(TextTheme text) {
    final isin = result.isin;
    final exchange = result.exchange;
    final isPrimary = result.isPrimaryListing;
    final identity = [?exchange, if (isin != null) 'ISIN $isin'].join(' · ');
    return [
      if (identity.isNotEmpty) Text(identity, style: text.bodySmall),
      if (isPrimary != null)
        Text(
          isPrimary ? primaryListingText : otherListingText,
          style: text.bodySmall,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = display;
    if (controller == null) return _card(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _card(context),
    );
  }

  Widget _card(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lastClose = result.lastCloseDate;
    final score = result.globalScore;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.name, style: text.titleLarge),
            Text(result.symbol, style: text.bodyMedium),
            ..._listingLines(text),
            const SizedBox(height: 8),
            Text(
              [
                _priceText(),
                if (lastClose != null) 'cierre del ${formatDate(lastClose)}',
              ].join(' · '),
            ),
            if (display case final controller?)
              CurrencySwitch(
                controller: controller,
                originalPrice: result.price,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                VerdictBadge(verdict: result.verdict),
                const Spacer(),
                if (score != null)
                  Text('${formatScore(score)} / 10', style: text.headlineSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text('Confianza: ${confidenceLabel(result.confidence)}'),
            Text('Perfil: ${profileLabel(result.profile)}'),
            const SizedBox(height: 8),
            Text('Motor v${result.motorVersion}', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
