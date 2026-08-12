import 'package:ferret/ferret.dart';
import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Ferret.install();

  runApp(const FerretExampleApp());
}
