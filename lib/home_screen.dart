// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import 'services/document_picker.dart';
import 'settings/app_settings.dart';
import 'viewer/pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.settings,
    super.key,
  });

  final AppSettingsController settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DocumentPicker _picker = const DocumentPicker();
  bool _opening = false;

  Future<void> _openPdf() async {
    if (_opening) {
      return;
    }

    setState(() => _opening = true);
    try {
      final source = await _picker.pickPdf();
      if (source == null || !mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => PdfViewerScreen(
            source: source,
            settings: widget.settings,
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => widget.settings.toggleTheme(
              Theme.of(context).brightness,
            ),
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 76,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'PDF Magic',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Open a PDF locally. Rendering, text selection, links, search, and pinch zoom stay on your device.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _opening ? null : _openPdf,
                    icon: _opening
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open_rounded),
                    label: const Text('Open PDF'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
