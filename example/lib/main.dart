import 'package:ferret/ferret.dart';
import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Ferret.install(
    config: const FerretConfig(
      showNotification: true,
    ),
  );

  runApp(const FerretExampleApp());
}
