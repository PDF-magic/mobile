// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/pdf_source.dart';
import 'enhancement_models.dart';

typedef EnhancementProgressCallback = void Function(EnhancementProgress value);

abstract interface class EnhancementBackend {
  bool get available;
  String? get unavailableReason;

  Future<EnhancementResult> enhance(
    PdfSource source, {
    required EnhancementProgressCallback onProgress,
  });
}

EnhancementBackend createEnhancementBackend() {
  if (Platform.isLinux || Platform.isMacOS) {
    return const LocalCliEnhancementBackend();
  }

  return UnavailableEnhancementBackend(
    'The imported enhancer currently depends on OCRmyPDF, qpdf, Python, and '
    'pikepdf. Android and iOS need a native on-device OCR/tagging backend '
    'before this workflow can run there without sending the PDF elsewhere.',
  );
}

final class UnavailableEnhancementBackend implements EnhancementBackend {
  const UnavailableEnhancementBackend(this.reason);

  final String reason;

  @override
  bool get available => false;

  @override
  String get unavailableReason => reason;

  @override
  Future<EnhancementResult> enhance(
    PdfSource source, {
    required EnhancementProgressCallback onProgress,
  }) {
    throw UnsupportedError(reason);
  }
}

final class LocalCliEnhancementBackend implements EnhancementBackend {
  const LocalCliEnhancementBackend();

  static const _toolAssets = [
    'ocr-scanned-pdf.sh',
    'tag-ocr-pdf.py',
  ];

  @override
  bool get available => true;

  @override
  String? get unavailableReason => null;

  @override
  Future<EnhancementResult> enhance(
    PdfSource source, {
    required EnhancementProgressCallback onProgress,
  }) async {
    if (source is! FilePdfSource) {
      throw const EnhancementException(
        'The local enhancer currently requires a PDF backed by a local file.',
      );
    }

    onProgress(
      const EnhancementProgress(
        stage: EnhancementStage.preparing,
        message: 'Preparing local enhancement…',
      ),
    );

    final workspace =
        await Directory.systemTemp.createTemp('pdf-magic-enhancer-');
    await _extractTools(workspace);

    onProgress(
      const EnhancementProgress(
        stage: EnhancementStage.checkingDependencies,
        message: 'Checking OCR dependencies…',
      ),
    );
    await _requireCommand('ocrmypdf');
    await _requireCommand('qpdf');
    await _requirePikePdf();

    final stem = _safeStem(source.displayName);
    final output = File('${workspace.path}/$stem-enhanced-ocr.pdf');
    final sidecar = '${workspace.path}/$stem-enhanced-ocr.txt';
    final report = '${workspace.path}/$stem-enhanced-ocr.tagging.json';

    onProgress(
      const EnhancementProgress(
        stage: EnhancementStage.ocr,
        message: 'Running OCR and preserving existing text…',
      ),
    );

    final script = '${workspace.path}/ocr-scanned-pdf.sh';
    final process = await Process.start(
      'bash',
      [
        script,
        source.path,
        output.path,
        '--skip-text',
      ],
      workingDirectory: workspace.path,
    );

    final stdout = StringBuffer();
    final stderr = StringBuffer();
    final stdoutDone =
        process.stdout.transform(utf8.decoder).forEach(stdout.write);
    final stderrDone =
        process.stderr.transform(utf8.decoder).forEach(stderr.write);
    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);

    if (exitCode != 0) {
      final details = stderr.toString().trim();
      throw EnhancementException(
        details.isEmpty
            ? 'PDF enhancer exited with status $exitCode.'
            : details,
      );
    }

    onProgress(
      const EnhancementProgress(
        stage: EnhancementStage.tagging,
        message: 'Verifying tagged document structure…',
      ),
    );

    if (!await output.exists() ||
        !await File(sidecar).exists() ||
        !await File(report).exists()) {
      throw const EnhancementException(
        'The enhancer finished without producing its expected PDF, text, and tagging artifacts.',
      );
    }

    onProgress(
      const EnhancementProgress(
        stage: EnhancementStage.finalizing,
        message: 'Opening enhanced copy…',
      ),
    );

    final enhancedSource = FilePdfSource(
      path: output.path,
      displayName: output.uri.pathSegments.last,
      referenceUri: source.referenceUri,
    );

    onProgress(
      const EnhancementProgress(
        stage: EnhancementStage.complete,
        message: 'Enhanced PDF ready',
      ),
    );

    return EnhancementResult(
      source: enhancedSource,
      outputPath: output.path,
      sidecarPath: sidecar,
      taggingReportPath: report,
    );
  }

  static Future<void> _extractTools(Directory directory) async {
    for (final name in _toolAssets) {
      final contents = await rootBundle.loadString('tool/enhancer/$name');
      final file = File('${directory.path}/$name');
      await file.writeAsString(contents, flush: true);
    }
  }

  static Future<void> _requireCommand(String command) async {
    final result = await Process.run(
      'sh',
      ['-lc', 'command -v $command >/dev/null 2>&1'],
    );
    if (result.exitCode != 0) {
      throw EnhancementException(
        'Required enhancer command not found: $command',
      );
    }
  }

  static Future<void> _requirePikePdf() async {
    final result = await Process.run(
      'python3',
      ['-c', 'import pikepdf'],
    );
    if (result.exitCode != 0) {
      throw const EnhancementException(
        'Python package pikepdf is required by the PDF structure tagger.',
      );
    }
  }

  static String _safeStem(String displayName) {
    final withoutExtension = displayName.toLowerCase().endsWith('.pdf')
        ? displayName.substring(0, displayName.length - 4)
        : displayName;
    final cleaned =
        withoutExtension.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
    return cleaned.isEmpty ? 'document' : cleaned;
  }
}
