# Bundled enhancer pipeline

This directory carries the core OCR, structure-tagging, and lossless-compression pipeline used by PDF Magic enhancement.

Source repository: https://github.com/PDF-magic/enhancer
Imported from commit: 6eb36a4f4f2bd961075136b45f86f79518ac48ab

The files stay close to upstream so behavior can be compared and later updates can be ported deliberately. Linux-style targets can invoke this local toolchain when its native dependencies are installed. Android and iOS require a native on-device backend before the same workflow can run there without an external service.

The repository-level GNU Affero GPL v3-or-later license applies to this imported code.

## Optional local review

The pinned enhancer revision also includes its optional Ollama OCR-review helper, model definition, setup script, and structure-tagging regression test under this directory. These remain local-only tools; the Flutter Android/iOS backend does not upload PDFs or silently substitute a remote model service.

