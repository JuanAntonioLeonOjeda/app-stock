import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pantalla alta para que las listas largas se construyan enteras y los
/// `find.text` no dependan de cuánto se haya desplazado.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
