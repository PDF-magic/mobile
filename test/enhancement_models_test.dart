// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_magic_mobile/enhancer/enhancement_models.dart';

void main() {
  test('enhancement stages keep preparation and completion distinct', () {
    expect(EnhancementStage.preparing, isNot(EnhancementStage.complete));
    expect(
      EnhancementStage.values,
      containsAll(<EnhancementStage>[
        EnhancementStage.ocr,
        EnhancementStage.tagging,
        EnhancementStage.finalizing,
      ]),
    );
  });
}
