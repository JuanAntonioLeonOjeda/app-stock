import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/cash_flow_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/earnings_report.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/fundamental_ratios.dart';

CashFlowStatement _cashFlow(double? operating, double? capex) =>
    CashFlowStatement(
      fiscalDateEnding: DateTime(2025, 12, 31),
      reportedCurrency: 'USD',
      operatingCashflow: operating,
      capitalExpenditures: capex,
      dividendPayout: null,
    );

EarningsReport _earnings(double? reported, double? estimated) => EarningsReport(
  fiscalDateEnding: DateTime(2025, 12, 31),
  reportedDate: null,
  reportedEps: reported,
  estimatedEps: estimated,
);

void main() {
  group('trailingTwelveMonths', () {
    test('suma los 4 últimos trimestres', () {
      final result = trailingTwelveMonths<double?>(
        quarterly: [1, 2, 3, 4, 100],
        annual: [50],
        field: (v) => v,
      );

      expect(result, 10);
    });

    test('usa el último año si faltan trimestres', () {
      final result = trailingTwelveMonths<double?>(
        quarterly: [1, 2, 3],
        annual: [50, 40],
        field: (v) => v,
      );

      expect(result, 50);
    });

    test('usa el último año si algún trimestre no tiene dato', () {
      final result = trailingTwelveMonths<double?>(
        quarterly: [1, null, 3, 4],
        annual: [50],
        field: (v) => v,
      );

      expect(result, 50);
    });

    test('devuelve null sin trimestres completos ni años', () {
      final result = trailingTwelveMonths<double?>(
        quarterly: [],
        annual: [],
        field: (v) => v,
      );

      expect(result, isNull);
    });
  });

  group('freeCashFlow', () {
    test('es el flujo operativo menos el CAPEX', () {
      expect(freeCashFlow(_cashFlow(100, 30)), 70);
    });

    test('devuelve null si falta el CAPEX', () {
      expect(freeCashFlow(_cashFlow(100, null)), isNull);
    });
  });

  group('ratioOverPositive', () {
    test('divide si el denominador es positivo', () {
      expect(ratioOverPositive(3, 2), 1.5);
    });

    test('devuelve null con denominador cero o negativo', () {
      expect(ratioOverPositive(3, 0), isNull);
      expect(ratioOverPositive(3, -2), isNull);
    });
  });

  group('netDebtToEbitda', () {
    test('resta la caja a la deuda', () {
      expect(netDebtToEbitda(totalDebt: 100, cash: 20, ebitda: 40), 2);
    });

    test('puede ser negativo si hay más caja que deuda', () {
      expect(netDebtToEbitda(totalDebt: 10, cash: 50, ebitda: 40), -1);
    });

    test('devuelve null con EBITDA negativo', () {
      expect(netDebtToEbitda(totalDebt: 100, cash: 20, ebitda: -5), isNull);
    });
  });

  group('growthRate', () {
    test('es la variación como fracción', () {
      expect(growthRate(110, 100), closeTo(0.1, 1e-12));
    });

    test('devuelve null si el valor anterior no es positivo', () {
      expect(growthRate(110, 0), isNull);
    });
  });

  group('cagr', () {
    test('es el crecimiento anual compuesto', () {
      expect(cagr(133.1, 100, 3), closeTo(0.1, 1e-9));
    });

    test('puede ser negativo', () {
      expect(cagr(72.9, 100, 3), closeTo(-0.1, 1e-9));
    });

    test('devuelve null si algún valor no es positivo', () {
      expect(cagr(100, -5, 3), isNull);
      expect(cagr(-100, 50, 3), isNull);
    });
  });

  group('effectiveTaxRate', () {
    test('es impuestos entre beneficio antes de impuestos', () {
      expect(
        effectiveTaxRate(incomeTaxExpense: 25, incomeBeforeTax: 100),
        0.25,
      );
    });

    test('usa el 21 % si el tipo es negativo o mayor del 50 %', () {
      expect(
        effectiveTaxRate(incomeTaxExpense: -5, incomeBeforeTax: 100),
        roicFallbackTaxRate,
      );
      expect(
        effectiveTaxRate(incomeTaxExpense: 60, incomeBeforeTax: 100),
        roicFallbackTaxRate,
      );
    });

    test('usa el 21 % si falta algún dato', () {
      expect(
        effectiveTaxRate(incomeTaxExpense: null, incomeBeforeTax: 100),
        roicFallbackTaxRate,
      );
    });
  });

  group('returnOnInvestedCapital', () {
    test('es el EBIT después de impuestos sobre el capital invertido', () {
      // 100·(1 − 0,25) / (200 + 300 − 100) = 75 / 400.
      final result = returnOnInvestedCapital(
        ebit: 100,
        taxRate: 0.25,
        totalDebt: 200,
        equity: 300,
        cash: 100,
      );

      expect(result, closeTo(0.1875, 1e-12));
    });

    test('devuelve null si el capital invertido no es positivo', () {
      final result = returnOnInvestedCapital(
        ebit: 100,
        taxRate: 0.25,
        totalDebt: 0,
        equity: 50,
        cash: 80,
      );

      expect(result, isNull);
    });
  });

  group('positiveFreeCashFlowFraction', () {
    test('es la fracción de los últimos 5 años con FCF positivo', () {
      final annual = [
        _cashFlow(100, 10),
        _cashFlow(100, 150),
        _cashFlow(100, 10),
        _cashFlow(100, 10),
        _cashFlow(100, 10),
        _cashFlow(100, 500),
      ];

      expect(positiveFreeCashFlowFraction(annual), 0.8);
    });

    test('devuelve null con menos de 3 años con dato', () {
      final annual = [_cashFlow(100, 10), _cashFlow(100, null)];

      expect(positiveFreeCashFlowFraction(annual), isNull);
    });
  });

  group('earningsBeatCount', () {
    test('cuenta los trimestres con BPA real mayor que el estimado', () {
      final quarterly = [
        _earnings(1.2, 1),
        _earnings(0.9, 1),
        _earnings(1, 1),
        _earnings(1.5, 1),
        _earnings(9, 1),
      ];

      expect(earningsBeatCount(quarterly), 2);
    });

    test('devuelve null si a alguno de los 4 le falta un dato', () {
      final quarterly = [
        _earnings(1.2, 1),
        _earnings(null, 1),
        _earnings(1, 1),
        _earnings(1.5, 1),
      ];

      expect(earningsBeatCount(quarterly), isNull);
    });

    test('devuelve null con menos de 4 trimestres', () {
      expect(earningsBeatCount([_earnings(1.2, 1)]), isNull);
    });
  });
}
