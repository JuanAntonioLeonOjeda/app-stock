import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/formula_evaluation.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/scale_formatting.dart';

/// La fórmula de una métrica dibujada por piezas (criterio 76): cada dato con
/// su valor y de dónde sale, y el resultado debajo.
///
/// [values] sustituye el valor de ciertas piezas (por su `key`); sin él se
/// dibuja el ejemplo inventado.
class FormulaDiagramView extends StatelessWidget {
  const FormulaDiagramView({
    super.key,
    required this.diagram,
    this.values = const {},
  });

  final FormulaDiagram diagram;
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    final body = switch (diagram) {
      RatioFormula(:final numerator, :final denominator) => _ratio(
        context,
        numerator,
        denominator,
      ),
      GrowthFormula(:final initial, :final finalValue, :final years) => _growth(
        context,
        initial,
        finalValue,
        years,
      ),
      VariationFormula(:final current, :final reference) => _variation(
        context,
        current,
        reference,
      ),
      StepsFormula(:final steps) => _steps(context, steps),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [body, const SizedBox(height: 12), _result(context)],
    );
  }

  Widget _ratio(
    BuildContext context,
    FormulaPiece numerator,
    FormulaPiece denominator,
  ) => Column(
    children: [
      _PieceCard(piece: numerator, value: _valueOf(numerator)),
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('÷', style: Theme.of(context).textTheme.titleLarge),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      _PieceCard(piece: denominator, value: _valueOf(denominator)),
    ],
  );

  Widget _growth(
    BuildContext context,
    FormulaPiece initial,
    FormulaPiece finalValue,
    FormulaPiece years,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _PieceCard(piece: initial, value: _valueOf(initial)),
      const SizedBox(height: 8),
      _PieceCard(piece: finalValue, value: _valueOf(finalValue)),
      const SizedBox(height: 8),
      _PieceCard(piece: years, value: _valueOf(years)),
      const SizedBox(height: 8),
      Text(growthFormulaCaption, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );

  Widget _variation(
    BuildContext context,
    FormulaPiece current,
    FormulaPiece reference,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _PieceCard(piece: current, value: _valueOf(current)),
      const SizedBox(height: 8),
      _PieceCard(piece: reference, value: _valueOf(reference)),
      const SizedBox(height: 8),
      Text(
        variationFormulaCaption,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );

  Widget _steps(BuildContext context, List<FormulaStep> steps) => Column(
    children: [
      for (var i = 0; i < steps.length; i++) ...[
        if (i > 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.arrow_downward, size: 20),
          ),
        _StepCard(number: i + 1, step: steps[i]),
      ],
    ],
  );

  Widget _result(BuildContext context) {
    final theme = Theme.of(context);
    final result = diagram.result;
    final value = diagram is StepsFormula
        ? result.exampleValue
        : evaluateFormula(diagram, values);
    final shown = value == null
        ? noResultText
        : formatResultValue(value, result.unit);
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.east, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Text(
            shown,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
    if (value != null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: 4),
        Text(noResultNote, style: theme.textTheme.bodySmall),
      ],
    );
  }

  double _valueOf(FormulaPiece piece) =>
      values[piece.key] ?? piece.exampleValue;
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({required this.piece, required this.value});

  final FormulaPiece piece;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(piece.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  _SourceChip(source: piece.source),
                ],
              ),
            ),
            Text(
              formatPieceValue(value, piece.unit),
              style: theme.textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final DataSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label) = switch (source) {
      DataSource.market => (Icons.show_chart, 'Mercado'),
      DataSource.incomeStatement => (
        Icons.receipt_long_outlined,
        'Cuenta de resultados',
      ),
      DataSource.balanceSheet => (Icons.balance, 'Balance'),
      DataSource.cashFlow => (Icons.payments_outlined, 'Flujo de caja'),
      DataSource.priceHistory => (Icons.timeline, 'Histórico de precios'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.step});

  final int number;
  final FormulaStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 12, child: Text('$number')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.name, style: theme.textTheme.titleSmall),
                  Text(step.description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
