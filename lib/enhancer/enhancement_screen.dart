// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../models/pdf_source.dart';
import 'enhancement_backend.dart';
import 'enhancement_models.dart';

class EnhancementScreen extends StatefulWidget {
  const EnhancementScreen({
    required this.source,
    required this.backend,
    super.key,
  });

  final PdfSource source;
  final EnhancementBackend backend;

  @override
  State<EnhancementScreen> createState() => _EnhancementScreenState();
}

class _EnhancementScreenState extends State<EnhancementScreen> {
  EnhancementProgress _progress = const EnhancementProgress(
    stage: EnhancementStage.preparing,
    message: 'Preparing enhancement…',
  );
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      final result = await widget.backend.enhance(
        widget.source,
        onProgress: (value) {
          if (mounted) {
            setState(() => _progress = value);
          }
        },
      );
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;

    return PopScope(
      canPop: error != null,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: error != null,
          title: const Text('Enhance PDF'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: error == null
                    ? _ProgressBody(progress: _progress)
                    : _ErrorBody(
                        message: error,
                        onBack: () => Navigator.of(context).pop(),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.progress});

  final EnhancementProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 48,
          child: CircularProgressIndicator(),
        ),
        const SizedBox(height: 24),
        Text(
          progress.message,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'The source PDF is never overwritten.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 52,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 20),
        Text(
          'Enhancement unavailable',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onBack,
          child: const Text('Back to PDF'),
        ),
      ],
    );
  }
}
