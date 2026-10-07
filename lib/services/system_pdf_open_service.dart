// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:io';

import 'package:open_file_handler/open_file_handler.dart';
import 'package:open_file_handler/open_file_handler_platform_interface.dart';

import '../models/pdf_source.dart';

typedef OpenPdfCallback = Future<void> Function(PdfSource source);
typedef OpenPdfErrorCallback = void Function(Object error);

class SystemPdfOpenService {
  SystemPdfOpenService({
    OpenFileHandler? handler,
  }) : _handler = handler ?? OpenFileHandler();

  final OpenFileHandler _handler;

  bool get supported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  StreamSubscription<dynamic>? listen({
    required OpenPdfCallback onPdf,
    required OpenPdfErrorCallback onError,
  }) {
    if (!supported) {
      return null;
    }

    return _handler.listen(
      (file) async {
        try {
          final source = await _toPdfSource(file);
          await onPdf(source);
        } on Object catch (error) {
          onError(error);
        } finally {
          if (Platform.isIOS) {
            await _handler.releaseIosURIs();
          }
        }
      },
      onError: (Object error) => onError(error),
    );
  }

  Future<PdfSource> _toPdfSource(OpenFileHandlerFile opened) async {
    final path = opened.path;
    if (path == null || path.isEmpty) {
      throw const FileSystemException(
        'The operating system did not provide a readable local PDF path.',
      );
    }

    final original = File(path);
    if (!await original.exists()) {
      throw FileSystemException('Opened PDF does not exist.', path);
    }

    await _verifyPdfSignature(original);

    var retained = original;
    if (Platform.isIOS) {
      final directory = await Directory.systemTemp.createTemp(
        'pdf-magic-open-',
      );
      final name = _displayName(opened, path);
      retained = await original.copy('${directory.path}/$name');
    }

    return FilePdfSource(
      path: retained.path,
      displayName: _displayName(opened, retained.path),
      referenceUri: _shareableReference(opened.uri),
    );
  }

  static Future<void> _verifyPdfSignature(File file) async {
    final handle = await file.open();
    try {
      final signature = await handle.read(5);
      if (signature.length < 5 ||
          signature[0] != 0x25 ||
          signature[1] != 0x50 ||
          signature[2] != 0x44 ||
          signature[3] != 0x46 ||
          signature[4] != 0x2d) {
        throw const FormatException('Opened file is not a PDF.');
      }
    } finally {
      await handle.close();
    }
  }

  static String _displayName(OpenFileHandlerFile opened, String path) {
    final supplied = opened.name?.trim();
    if (supplied != null && supplied.isNotEmpty) {
      return supplied;
    }

    final segments = File(path).uri.pathSegments;
    return segments.isEmpty ? 'document.pdf' : segments.last;
  }

  static Uri? _shareableReference(String rawUri) {
    final uri = Uri.tryParse(rawUri);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return uri;
  }
}
