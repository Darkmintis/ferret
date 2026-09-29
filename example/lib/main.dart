import 'package:ferret/ferret.dart';
import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Demo only: shows the red release border. Keep `false` in real apps.
  Ferret.install(config: const FerretConfig(enableInRelease: true));

  runApp(const FerretExampleApp());
}
