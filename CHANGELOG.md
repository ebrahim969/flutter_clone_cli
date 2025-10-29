# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-10-29

### Added
- Example project in `example/` directory to demonstrate usage.
- Inline documentation comments for public APIs to meet pub.dev score requirements.
- `analysis_options.yaml` with `public_member_api_docs` rule.
- Minor improvements to CLI output and validation messages.

### Fixed
- Missing CHANGELOG entry warning on `dart pub publish --dry-run`.
- Improved error handling when template path or pubspec.yaml is missing.

---

## [1.0.2] - 2025-10-29

### Updated
- Improved README formatting and clarified usage examples.
- No functional or API changes.

---

## [0.1.0] - 2025-10-29

### Added
- Initial release of Flutter Template CLI
- Create Flutter projects from custom templates with a single command
- Automatic project name replacement across all project files
- Automatic package ID updates for Android and iOS
- Smart file copying that excludes build artifacts and hidden files
- Support for custom organization identifiers
- Command-line interface with `ftcreate` command
- Validation for project names (lowercase, underscores, numbers only)
- Progress indicators for better user experience
- Comprehensive error handling and user feedback

### Features
- **Template Copying**: Complete project duplication from custom templates
- **Android Updates**: Automatically updates `build.gradle`, `AndroidManifest.xml`, and `MainActivity.kt`
- **iOS Updates**: Automatically updates `Info.plist` and `project.pbxproj` files
- **File Exclusions**: Skips `.git`, `build/`, `.dart_tool/`, and other temporary files
- **Project Validation**: Ensures template is a valid Flutter project before copying

### Documentation
- Comprehensive README with installation and usage instructions
- Inline code documentation
- Usage examples and best practices
