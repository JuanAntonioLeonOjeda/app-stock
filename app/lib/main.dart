import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stock_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageDirectory = await getApplicationSupportDirectory();
  runApp(StockApp(storageDirectory: storageDirectory));
}
