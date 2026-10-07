// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

sealed class PdfSource {
  const PdfSource({
    required this.displayName,
    this.referenceUri,
  });

  final String displayName;
  final Uri? referenceUri;

  PdfDocumentRef createDocumentRef();

  String pageReference(int pageNumber) {
    final reference = referenceUri;
    if (reference == null) {
      return '$displayName#page=$pageNumber';
    }
    return reference.replace(fragment: 'page=$pageNumber').toString();
  }
}

final class FilePdfSource extends PdfSource {
  const FilePdfSource({
    required this.path,
    required super.displayName,
    super.referenceUri,
  });

  final String path;

  @override
  PdfDocumentRef createDocumentRef() => PdfDocumentRefFile(path);
}

final class DataPdfSource extends PdfSource {
  const DataPdfSource({
    required this.data,
    required super.displayName,
    super.referenceUri,
  });

  final Uint8List data;

  @override
  PdfDocumentRef createDocumentRef() => PdfDocumentRefData(
        data,
        sourceName: displayName,
      );
}

final class UriPdfSource extends PdfSource {
  const UriPdfSource({
    required this.uri,
    required super.displayName,
  }) : super(referenceUri: uri);

  final Uri uri;

  @override
  PdfDocumentRef createDocumentRef() => PdfDocumentRefUri(uri);
}
