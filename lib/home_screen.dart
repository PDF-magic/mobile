// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';

import 'models/pdf_source.dart';
import 'services/document_picker.dart';
import 'services/system_pdf_open_service.dart';
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
  final SystemPdfOpenService _systemOpen = SystemPdfOpenService();
  StreamSubscription<dynamic>? _systemOpenSubscription;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _systemOpenSubscription = _systemOpen.listen(
      onPdf: _openSource,
      onError: _showOpenError,
    );
  }

  @override
  void dispose() {
    _systemOpenSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openPdf() async {
    if (_opening) {
      return;
    }

    setState(() => _opening = true);
    try {
      final source = await _picker.pickPdf();
      if (source == null) {
        return;
      }
      await _openSource(source);
    } on Object catch (error) {
      _showOpenError(error);
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  Future<void> _openWebPdf() async {
    final controller = TextEditingController();
    final rawUrl = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Open web PDF'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.go,
            decoration: const InputDecoration(
              labelText: 'HTTPS URL',
              hintText: 'https://example.com/document.pdf',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (rawUrl == null || rawUrl.trim().isEmpty || !mounted) {
      return;
    }

    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _showOpenError(
        const FormatException('Use a complete HTTPS PDF URL.'),
      );
      return;
    }

    final lastSegment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final displayName = lastSegment.trim().isEmpty
        ? 'document.pdf'
        : lastSegment;

    await _openSource(
      UriPdfSource(
        uri: uri,
        displayName: displayName,
      ),
    );
  }

  Future<void> _openSource(PdfSource source) async {
    if (!mounted) {
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
  }

  void _showOpenError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open PDF: $error')),
    );
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
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _openWebPdf,
                    icon: const Icon(Icons.public_rounded),
                    label: const Text('Open web PDF'),
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
