import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_listings.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/search/group_listings.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/company_listings_tile.dart';

import '../../search_samples.dart';

CompanyListings _company(List<SymbolMatch> matches) =>
    groupListings(matches).first;

Future<List<String>> _pump(WidgetTester tester, CompanyListings company) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final selected = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CompanyListingsTile(company: company, onSelect: selected.add),
        ),
      ),
    ),
  );
  return selected;
}

void main() {
  group('CompanyListingsTile', () {
    testWidgets(
      'muestra el nombre, la etiqueta Principal, el ISIN y la bolsa (criterio 72)',
      (tester) async {
        await _pump(tester, _company([tescoLondon, tescoFrankfurt]));

        expect(find.text('Tesco PLC'), findsOneWidget);
        expect(find.text(primaryListingLabel), findsOneWidget);
        expect(find.text('London Stock Exchange · GB · GBX'), findsOneWidget);
        expect(find.text('ISIN GB0008847096'), findsOneWidget);
      },
    );

    testWidgets(
      'las otras cotizaciones están plegadas con su número (criterio 73)',
      (tester) async {
        await _pump(tester, _company([tescoLondon, tescoFrankfurt]));

        expect(find.text('Otras cotizaciones (1)'), findsOneWidget);
        expect(find.text('GETTEX:TCO'), findsNothing);
      },
    );

    testWidgets(
      'al desplegar se ven la bolsa, la divisa y el símbolo de cada una',
      (tester) async {
        await _pump(tester, _company([tescoLondon, tescoFrankfurt]));

        await tester.tap(find.text('Otras cotizaciones (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Gettex · DE · EUR'), findsOneWidget);
        expect(find.text('GETTEX:TCO'), findsOneWidget);
      },
    );

    testWidgets(
      'pulsar la empresa elige su cotización principal (criterio 74)',
      (tester) async {
        final selected = await _pump(
          tester,
          _company([tescoFrankfurt, tescoLondon]),
        );

        await tester.tap(find.text('Tesco PLC'));

        expect(selected, ['LSE:TSCO']);
      },
    );

    testWidgets('pulsar otra cotización elige esa', (tester) async {
      final selected = await _pump(
        tester,
        _company([tescoLondon, tescoFrankfurt]),
      );
      await tester.tap(find.text('Otras cotizaciones (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gettex · DE · EUR'));

      expect(selected, ['GETTEX:TCO']);
    });

    testWidgets('sin otras cotizaciones no hay desplegable', (tester) async {
      await _pump(tester, _company([tescoLondon]));

      expect(find.textContaining('Otras cotizaciones'), findsNothing);
    });

    testWidgets(
      'sin cotización principal confirmada no se etiqueta Principal',
      (tester) async {
        await _pump(tester, _company([tescoFrankfurt]));

        expect(find.text(primaryListingLabel), findsNothing);
        expect(find.text('Tesco PLC'), findsOneWidget);
      },
    );

    testWidgets('un certificado se etiqueta ADR y no Principal (criterio 75)', (
      tester,
    ) async {
      await _pump(tester, _company([tescoReceipt]));

      expect(find.text(depositaryReceiptLabel), findsOneWidget);
      expect(find.text(primaryListingLabel), findsNothing);
    });

    testWidgets('sin nombre de bolsa muestra el código', (tester) async {
      await _pump(
        tester,
        _company([
          const SymbolMatch(
            symbol: 'XYZ:ABC',
            name: 'Sin nombre de bolsa',
            region: 'US',
            currency: 'USD',
            matchScore: 1,
            isin: 'US0000000001',
            exchange: 'XYZ',
            isPrimaryListing: true,
          ),
        ]),
      );

      expect(find.text('XYZ · US · USD'), findsOneWidget);
    });
  });
}
