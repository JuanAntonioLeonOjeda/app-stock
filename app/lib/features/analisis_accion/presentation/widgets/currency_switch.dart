import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/display_currency_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';

/// Selector "EUR | divisa original" y la nota del tipo aplicado (criterios
/// 84-86, 96 y 97). No pinta nada si el resultado ya está en euros o no tiene
/// moneda.
class CurrencySwitch extends StatelessWidget {
  const CurrencySwitch({
    super.key,
    required this.controller,
    this.originalPrice,
  });

  final DisplayCurrencyController controller;

  /// Último precio en la divisa original, para la nota "Equivale a...".
  final double? originalPrice;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => switch (controller.status) {
      CurrencyStatus.none => const SizedBox.shrink(),
      CurrencyStatus.loading => const _Note('Convirtiendo a euros…'),
      CurrencyStatus.unsupported => _Note(
        'Sin tipo de cambio del BCE para ${controller.quoteCode}',
      ),
      CurrencyStatus.failed => _failed(),
      CurrencyStatus.ready => _ready(context),
    },
  );

  Widget _failed() => Row(
    children: [
      const Flexible(child: _Note('No se ha podido convertir a euros')),
      TextButton(onPressed: controller.reload, child: const Text('Reintentar')),
    ],
  );

  Widget _ready(BuildContext context) {
    final quote = controller.quoteCode ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            const ButtonSegment(value: false, label: Text('EUR')),
            ButtonSegment(value: true, label: Text(quote)),
          ],
          selected: {!controller.isInEuros},
          onSelectionChanged: (selection) =>
              controller.showOriginal(original: selection.first),
        ),
        if (controller.isInEuros) _rateNote(quote),
      ],
    );
  }

  Widget _rateNote(String quote) {
    final latest = controller.latestRate;
    if (latest == null) return const SizedBox.shrink();
    final price = originalPrice;
    final age = controller.latestRateAgeInDays;
    // El tipo es de la divisa mayor (GBP), no de la subunidad cotizada (GBX).
    final iso = controller.isoCode ?? quote;
    final rate = formatExchangeRate(latest.unitsPerEuro, iso);
    return _Note(
      [
        if (price != null) 'Equivale a ${formatPrice(price, quote)}',
        '1 € = $rate (BCE, ${formatDate(latest.date)})',
        if (controller.isRateStale && age != null) 'tipo de hace $age días',
      ].join(' · '),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}
