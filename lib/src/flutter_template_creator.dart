import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mason_logger/mason_logger.dart';

class FlutterTemplateCreator {
  final Logger logger;

  FlutterTemplateCreator({required this.logger});

  Future<void> createProject({
    required String projectName,
    required String templatePath,
    required String orgId,
    required String targetPath,
  }) async {
    //! Validate project name
    if (!_isValidProjectName(projectName)) {
      throw Exception(
        'Invalid project name. Use lowercase letters, numbers, and underscores only.',
      );
    }

    //! Validate template exists
    final templateDir = Directory(templatePath);
    if (!await templateDir.exists()) {
      throw Exception('Template path does not exist: $templatePath');
    }

    //! Check if pubspec.yaml exists in template
    final templatePubspec = File(path.join(templatePath, 'pubspec.yaml'));
    if (!await templatePubspec.exists()) {
      throw Exception(
        'Template is not a valid Flutter project (no pubspec.yaml)',
      );
    }

    //! Create target directory
    final projectDir = Directory(path.join(targetPath, projectName));
    if (await projectDir.exists()) {
      throw Exception('Directory $projectName already exists');
    }

    await projectDir.create(recursive: true);

    //! Copy template to new project
    await _copyDirectory(templateDir, projectDir);

    //! Get original project name from template
    final originalName = await _getProjectNameFromPubspec(templatePubspec);

    //! Update project configuration
    await _updateProjectName(projectDir, originalName, projectName);
    await _updatePackageId(projectDir, orgId, projectName);
  }

  bool _isValidProjectName(String name) {
    final pattern = RegExp(r'^[a-z][a-z0-9_]*$');
    return pattern.hasMatch(name);
  }

  Future<String> _getProjectNameFromPubspec(File pubspecFile) async {
    final content = await pubspecFile.readAsString();
    final nameMatch = RegExp(
      r'^name:\s*(.+)$',
      multiLine: true,
    ).firstMatch(content);
    return nameMatch?.group(1)?.trim() ?? 'template_project';
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false)) {
      final name = path.basename(entity.path);

      //! Skip hidden files/folders and build artifacts
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

  Future<void> _updateProjectName(
    Directory projectDir,
    String oldName,
    String newName,
  ) async {
    //! Update pubspec.yaml
    await _replaceInFile(
      path.join(projectDir.path, 'pubspec.yaml'),
      oldName,
      newName,
    );

    //! Update lib files
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    if (await libDir.exists()) {
      await _replaceInDirectory(libDir, oldName, newName);
    }

    //! Update test files
    final testDir = Directory(path.join(projectDir.path, 'test'));
    if (await testDir.exists()) {
      await _replaceInDirectory(testDir, oldName, newName);
    }

    //! Update README.md if exists
    final readmeFile = File(path.join(projectDir.path, 'README.md'));
    if (await readmeFile.exists()) {
      await _replaceInFile(readmeFile.path, oldName, newName);
    }
  }

  Future<void> _updatePackageId(
    Directory projectDir,
    String orgId,
    String projectName,
  ) async {
    final packageId = '$orgId.$projectName';

    //! Update Android
    await _updateAndroidPackageId(projectDir, packageId);

    //! Update iOS
    await _updateIosPackageId(projectDir, packageId);
  }

  Future<void> _updateAndroidPackageId(
    Directory projectDir,
    String packageId,
  ) async {
    //! Update build.gradle
    final buildGradleFile = File(
      path.join(projectDir.path, 'android', 'app', 'build.gradle'),
    );

    if (await buildGradleFile.exists()) {
      var content = await buildGradleFile.readAsString();
      content = content.replaceAll(
        RegExp(r'applicationId\s+"[^"]*"'),
        'applicationId "$packageId"',
      );
      await buildGradleFile.writeAsString(content);
    }

    //! Update AndroidManifest.xml
    final manifestFile = File(
      path.join(
        projectDir.path,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      ),
    );

    if (await manifestFile.exists()) {
      var content = await manifestFile.readAsString();
      content = content.replaceAll(
        RegExp(r'package="[^"]*"'),
        'package="$packageId"',
      );
      await manifestFile.writeAsString(content);
    }

    //! Update MainActivity path
    final mainActivityKt = File(
      path.join(
        projectDir.path,
        'android',
        'app',
        'src',
        'main',
        'kotlin',
        'MainActivity.kt',
      ),
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

  Future<void> _updateIosPackageId(
    Directory projectDir,
    String packageId,
  ) async {
    //! Update Info.plist
    final infoPlistFile = File(
      path.join(projectDir.path, 'ios', 'Runner', 'Info.plist'),
    );

    if (await infoPlistFile.exists()) {
      var content = await infoPlistFile.readAsString();
      content = content.replaceAll(
        RegExp(r'<key>CFBundleIdentifier</key>\s*<string>[^<]*</string>'),
        '<key>CFBundleIdentifier</key>\n\t<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>',
      );
      await infoPlistFile.writeAsString(content);
    }

    //! Update project.pbxproj
    final pbxprojFile = File(
      path.join(projectDir.path, 'ios', 'Runner.xcodeproj', 'project.pbxproj'),
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
