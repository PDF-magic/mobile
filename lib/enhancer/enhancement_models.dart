// SPDX-License-Identifier: AGPL-3.0-or-later

import '../models/pdf_source.dart';

enum EnhancementStage {
  preparing,
  checkingDependencies,
  ocr,
  tagging,
  finalizing,
  complete,
}

class EnhancementProgress {
  const EnhancementProgress({
    required this.stage,
    required this.message,
  });

  final EnhancementStage stage;
  final String message;
}

class EnhancementResult {
  const EnhancementResult({
    required this.source,
    required this.outputPath,
    required this.sidecarPath,
    required this.taggingReportPath,
  });

  final FilePdfSource source;
  final String outputPath;
  final String sidecarPath;
  final String taggingReportPath;
}

class EnhancementException implements Exception {
  const EnhancementException(this.message);

  final String message;

  @override
  String toString() => message;
}
