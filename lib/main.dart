// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

void main() {
  runApp(const PdfMagicMobileApp());
}

class PdfMagicMobileApp extends StatelessWidget {
  const PdfMagicMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      themeMode: ThemeMode.system,
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'PDF Magic Mobile',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Flutter foundation ready for the viewer and enhancer ports.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
