// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'home_screen.dart';
import 'settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();

  final settings = AppSettingsController();
  await settings.load();

  runApp(PdfMagicMobileApp(settings: settings));
}

class PdfMagicMobileApp extends StatelessWidget {
  const PdfMagicMobileApp({
    required this.settings,
    super.key,
  });

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PDF Magic',
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xff43af49),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xff43af49),
            useMaterial3: true,
          ),
          themeMode: settings.themeMode,
          home: HomeScreen(settings: settings),
        );
      },
    );
  }
}
