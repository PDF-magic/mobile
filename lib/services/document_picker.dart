// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/pdf_source.dart';

class DocumentPicker {
  const DocumentPicker();

  Future<PdfSource?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      allowedExtensions: const ['pdf'],
      type: FileType.custom,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) {
      throw const FileSystemException(
        'The selected PDF did not expose a local readable path.',
      );
    }

    return FilePdfSource(
      path: path,
      displayName: file.name,
    );
  }
}
