# My First Project

A small Flutter counter app for Android.

## Local checks

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
GitHub Actions runs these checks on pushes to `main` and can also be started
manually. Its `app-release-apk` artifact is retained for 14 days. The APK uses
the generated debug signing key; configure a private release key before
publishing through an app store.
