import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

class BaniRasijanApp extends StatelessWidget {
  const BaniRasijanApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BANI RASIJAN',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    onGenerateRoute: AppRouter.onGenerateRoute,
    initialRoute: AppRouter.splash,
  );
}
