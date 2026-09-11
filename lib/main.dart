import 'package:flutter/material.dart';

import 'src/app/app.dart';
import 'src/shared/di/di_config.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const PortfolioApp());
}
