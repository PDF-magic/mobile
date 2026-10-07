# PDF Magic Mobile

PDF Magic Mobile is the Flutter/Dart port of the PDF Magic viewer and enhancement workflow for phones, tablets, and mobile-oriented Linux systems.

The repository is being ported in small, reviewable commits from:

- [PDF-magic/viewer](https://github.com/PDF-magic/viewer) for reading, search, navigation, sharing, themes, and document metadata behavior.
- [PDF-magic/enhancer](https://github.com/PDF-magic/enhancer) for OCR, structure tagging, enhancement progress, and source-preserving derivative behavior.

## Targets

The shared Flutter UI is intended for Android, iOS, Linux, and Ubuntu Touch-oriented Linux builds. Platform-specific document opening, sharing, and enhancement runners live behind small adapters so the viewer itself stays portable.

## Development

This project targets Flutter 3.47 or newer and Dart 3.13 or newer.

Generate the standard Flutter Android, iOS, and Linux host projects while preserving PDF Magic's native PDF-open integrations:

```sh
./tool/bootstrap-platforms.sh
flutter pub get
flutter run
```

The bootstrap script generates the hosts from the installed Flutter SDK in a temporary directory, copies only the platform scaffolds into this checkout, and then restores PDF Magic's Android and iOS overlays. It deliberately uses the native application identifier `org.pdfmagic.mobile` while leaving the Dart package name `pdf_magic_mobile` unchanged.

## License

PDF Magic Mobile is free software licensed under the GNU Affero General Public License, version 3 or any later version (AGPL-3.0-or-later). See [LICENSE](LICENSE).
