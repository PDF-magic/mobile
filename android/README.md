# Android host overlay

These files contain PDF Magic's Android-specific behavior and should be kept when the remaining Flutter Android scaffold is generated.

The app registers for `application/pdf` VIEW, EDIT, and SEND intents. `MainActivity` passes the received URI to `open_file_handler` with `copyToLocal = true`, which gives the Dart viewer a stable local path even when Android supplied a `content://` URI.

From a checkout that does not yet contain the generated Gradle wrapper/build files, run from the repository root:

```sh
flutter create --platforms=android --org org.pdfmagic .
```

Review the generated diff and keep this manifest and `MainActivity.kt` integration.
