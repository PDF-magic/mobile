// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_magic_mobile/models/pdf_source.dart';

void main() {
  group('PdfSource.pageReference', () {
    test('adds the current page to the original web reference', () {
      final source = FilePdfSource(
        path: '/tmp/document.pdf',
        displayName: 'document.pdf',
        referenceUri: Uri.parse('https://example.com/document.pdf'),
      );

      expect(
        source.pageReference(42),
        'https://example.com/document.pdf#page=42',
      );
    });

    test('replaces an existing fragment with the current page', () {
      final source = FilePdfSource(
        path: '/tmp/document.pdf',
        displayName: 'document.pdf',
        referenceUri: Uri.parse(
          'https://example.com/document.pdf#old-fragment',
        ),
      );

      expect(
        source.pageReference(7),
        'https://example.com/document.pdf#page=7',
      );
    });

    test('falls back to a local document label without a web reference', () {
      final source = FilePdfSource(
        path: '/tmp/document.pdf',
        displayName: 'document.pdf',
      );

      expect(source.pageReference(3), 'document.pdf#page=3');
    });
  });
}
