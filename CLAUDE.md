# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**bbr_scanner** is a Flutter application currently in its initial scaffolding stage. The project contains the default Flutter counter app template and is set up for iOS and Android development.

## Common Commands

### Running the App
```bash
# Run on connected device/emulator
flutter run

# Run with hot reload enabled (default)
flutter run

# Run in release mode
flutter run --release

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format all Dart files
dart format .

# Fix auto-fixable lint issues
dart fix --apply
```

### Building
```bash
# Build APK for Android
flutter build apk

# Build iOS (requires macOS)
flutter build ios

# Build App Bundle for Google Play
flutter build appbundle
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Show outdated dependencies
flutter pub outdated
```

## Project Structure

This is a newly created Flutter project with minimal structure:

```
lib/
  main.dart          # Entry point with default counter app
test/
  widget_test.dart   # Basic widget test example
```

## Current State

- **SDK Version**: Dart ^3.10.1
- **Dependencies**: Only core Flutter and cupertino_icons
- **Linting**: Uses flutter_lints package (activated in analysis_options.yaml)
- **No custom architecture**: Project contains only the default Flutter template

## Development Notes

- The project uses standard Flutter lints (package:flutter_lints/flutter.yaml)
- Material Design is enabled in pubspec.yaml
- No assets, fonts, or custom configurations are currently defined
