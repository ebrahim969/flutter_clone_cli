import 'package:flutter_clone_cli/flutter_clone_cli.dart';
import 'package:mason_logger/mason_logger.dart';
import 'dart:io';

/// Example usage of the Flutter Clone CLI.
void main() async {
  final logger = Logger();
  final creator = FlutterTemplateCreator(logger: logger);

  await creator.createProject(
    projectName: 'demo_app',
    templatePath: '/Users/ibrahim/Templates/base_project',
    orgId: 'com.example',
    targetPath: Directory.current.path,
  );

  logger.success('✅ Flutter project created successfully!');
}
