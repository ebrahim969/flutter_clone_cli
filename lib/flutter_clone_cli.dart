library;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mason_logger/mason_logger.dart';

/// Exports the main project creation logic.
export 'src/flutter_template_creator.dart';

/// A utility class that creates a new Flutter project
/// by copying an existing template directory and
/// updating names, package identifiers, and configurations.
///
/// Example:
/// ```dart
/// final creator = FlutterTemplateCreator(logger: Logger());
/// await creator.createProject(
///   projectName: 'my_app',
///   templatePath: '/Users/me/Templates/base_app',
///   orgId: 'com.example',
///   targetPath: Directory.current.path,
/// );
/// ```
class FlutterTemplateCreator {
  /// The logger used to display progress and messages.
  final Logger logger;

  /// Creates a new [FlutterTemplateCreator] instance.
  FlutterTemplateCreator({required this.logger});

  /// Creates a new Flutter project based on the given [templatePath].
  ///
  /// Copies all files, updates the project name, and modifies Android/iOS
  /// identifiers using [orgId].
  ///
  /// Throws an [Exception] if:
  /// * The project name is invalid.
  /// * The template directory does not exist.
  /// * The pubspec.yaml file is missing.
  Future<void> createProject({
    required String projectName,
    required String templatePath,
    required String orgId,
    required String targetPath,
  }) async {
    if (!_isValidProjectName(projectName)) {
      throw Exception(
        'Invalid project name. Use lowercase letters, numbers, and underscores only.',
      );
    }

    final templateDir = Directory(templatePath);
    if (!await templateDir.exists()) {
      throw Exception('Template path does not exist: $templatePath');
    }

    final templatePubspec = File(path.join(templatePath, 'pubspec.yaml'));
    if (!await templatePubspec.exists()) {
      throw Exception(
        'Template is not a valid Flutter project (no pubspec.yaml)',
      );
    }

    final projectDir = Directory(path.join(targetPath, projectName));
    if (await projectDir.exists()) {
      throw Exception('Directory $projectName already exists');
    }

    await projectDir.create(recursive: true);
    await _copyDirectory(templateDir, projectDir);

    final originalName = await _getProjectNameFromPubspec(templatePubspec);

    await _updateProjectName(projectDir, originalName, projectName);
    await _updatePackageId(projectDir, orgId, projectName);
  }

  /// Validates if the given [name] is a valid Flutter project name.
  bool _isValidProjectName(String name) {
    final pattern = RegExp(r'^[a-z][a-z0-9_]*$');
    return pattern.hasMatch(name);
  }

  /// Extracts the project name from the pubspec.yaml file.
  Future<String> _getProjectNameFromPubspec(File pubspecFile) async {
    final content = await pubspecFile.readAsString();
    final nameMatch = RegExp(
      r'^name:\s*(.+)$',
      multiLine: true,
    ).firstMatch(content);
    return nameMatch?.group(1)?.trim() ?? 'template_project';
  }

  /// Recursively copies a directory and its contents.
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false)) {
      final name = path.basename(entity.path);
      if (name.startsWith('.') ||
          name == 'build' ||
          name == '.dart_tool' ||
          name == '.flutter-plugins' ||
          name == '.flutter-plugins-dependencies') {
        continue;
      }

      if (entity is Directory) {
        final newDirectory = Directory(path.join(destination.path, name));
        await newDirectory.create();
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File(path.join(destination.path, name));
        await entity.copy(newFile.path);
      }
    }
  }

  /// Updates the Flutter project name in all key files (pubspec, lib, test, README).
  Future<void> _updateProjectName(
    Directory projectDir,
    String oldName,
    String newName,
  ) async {
    await _replaceInFile(
      path.join(projectDir.path, 'pubspec.yaml'),
      oldName,
      newName,
    );

    final libDir = Directory(path.join(projectDir.path, 'lib'));
    if (await libDir.exists()) {
      await _replaceInDirectory(libDir, oldName, newName);
    }

    final testDir = Directory(path.join(projectDir.path, 'test'));
    if (await testDir.exists()) {
      await _replaceInDirectory(testDir, oldName, newName);
    }

    final readmeFile = File(path.join(projectDir.path, 'README.md'));
    if (await readmeFile.exists()) {
      await _replaceInFile(readmeFile.path, oldName, newName);
    }
  }

  /// Updates the Android and iOS package identifiers.
  Future<void> _updatePackageId(
    Directory projectDir,
    String orgId,
    String projectName,
  ) async {
    final packageId = '$orgId.$projectName';
    await _updateAndroidPackageId(projectDir, packageId);
    await _updateIosPackageId(projectDir, packageId);
  }

  /// Updates Android build.gradle, manifest, and main activity files.
  Future<void> _updateAndroidPackageId(
    Directory projectDir,
    String packageId,
  ) async {
    final buildGradleFile = File(
      path.join(projectDir.path, 'android/app/build.gradle'),
    );
    if (await buildGradleFile.exists()) {
      var content = await buildGradleFile.readAsString();
      content = content.replaceAll(
        RegExp(r'applicationId\s+"[^"]*"'),
        'applicationId "$packageId"',
      );
      await buildGradleFile.writeAsString(content);
    }

    final manifestFile = File(
      path.join(projectDir.path, 'android/app/src/main/AndroidManifest.xml'),
    );
    if (await manifestFile.exists()) {
      var content = await manifestFile.readAsString();
      content = content.replaceAll(
        RegExp(r'package="[^"]*"'),
        'package="$packageId"',
      );
      await manifestFile.writeAsString(content);
    }

    final mainActivityKt = File(
      path.join(projectDir.path, 'android/app/src/main/kotlin/MainActivity.kt'),
    );
    if (await mainActivityKt.exists()) {
      var content = await mainActivityKt.readAsString();
      content = content.replaceAll(
        RegExp(r'package\s+[^\s]+'),
        'package $packageId',
      );
      await mainActivityKt.writeAsString(content);
    }
  }

  /// Updates iOS Info.plist and project.pbxproj with the new bundle ID.
  Future<void> _updateIosPackageId(
    Directory projectDir,
    String packageId,
  ) async {
    final infoPlistFile = File(
      path.join(projectDir.path, 'ios/Runner/Info.plist'),
    );
    if (await infoPlistFile.exists()) {
      var content = await infoPlistFile.readAsString();
      content = content.replaceAll(
        RegExp(r'<key>CFBundleIdentifier</key>\s*<string>[^<]*</string>'),
        '<key>CFBundleIdentifier</key>\n\t<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>',
      );
      await infoPlistFile.writeAsString(content);
    }

    final pbxprojFile = File(
      path.join(projectDir.path, 'ios/Runner.xcodeproj/project.pbxproj'),
    );
    if (await pbxprojFile.exists()) {
      var content = await pbxprojFile.readAsString();
      content = content.replaceAll(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;'),
        'PRODUCT_BUNDLE_IDENTIFIER = $packageId;',
      );
      await pbxprojFile.writeAsString(content);
    }
  }

  /// Replaces [oldValue] with [newValue] in a single file.
  Future<void> _replaceInFile(
    String filePath,
    String oldValue,
    String newValue,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    var content = await file.readAsString();
    content = content.replaceAll(oldValue, newValue);
    await file.writeAsString(content);
  }

  /// Recursively replaces text in all `.dart`, `.yaml`, and `.md` files.
  Future<void> _replaceInDirectory(
    Directory dir,
    String oldValue,
    String newValue,
  ) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File &&
          (entity.path.endsWith('.dart') ||
              entity.path.endsWith('.yaml') ||
              entity.path.endsWith('.md'))) {
        await _replaceInFile(entity.path, oldValue, newValue);
      }
    }
  }
}
