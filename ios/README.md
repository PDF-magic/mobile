# iOS host overlay

These files register PDF Magic as a viewer for `com.adobe.pdf` and adopt Flutter's scene-based lifecycle required by `open_file_handler`.

`SceneDelegate` handles both cold-start and warm-start document URLs and asks the plugin to copy the incoming PDF into app-local storage before the Dart layer opens it. The Dart service then releases the iOS security-scoped URLs after retaining the file it needs.

If the remaining generated Xcode project files are absent, run from the repository root on a Flutter development machine:

```sh
flutter create --platforms=ios --org org.pdfmagic .
```

Review the generated diff and keep this `Info.plist`, `AppDelegate.swift`, and `SceneDelegate.swift` integration.
