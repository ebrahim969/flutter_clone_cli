import 'dart:io';
import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:flutter_clone_cli/flutter_clone_cli.dart';

void main(List<String> arguments) async {
  final logger = Logger();
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addOption(
      'template',
      abbr: 't',
      help: 'Path to the template Flutter project',
      mandatory: false,
    )
    ..addOption(
      'org',
      abbr: 'o',
      help: 'Organization identifier (e.g., com.example)',
      defaultsTo: 'com.example',
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printUsage(parser);
      return;
    }

    if (results.rest.isEmpty) {
      logger.err('Please provide a project name');
      _printUsage(parser);
      exit(1);
    }

    final projectName = results.rest.first;
    final templatePath = results['template'] as String?;
    final orgId = results['org'] as String;

    if (templatePath == null) {
      logger.err('Please provide a template path using --template or -t');
      exit(1);
    }

    final creator = FlutterTemplateCreator(logger: logger);

    final progress = logger.progress('Creating project from template');

    await creator.createProject(
      projectName: projectName,
      templatePath: templatePath,
      orgId: orgId,
      targetPath: Directory.current.path,
    );

    progress.complete('Project created successfully!');

    logger.info('');
    logger.success(
      '✓ Project "$projectName" created at: ${Directory.current.path}/$projectName',
    );
    logger.info('');
    logger.info('Next steps:');
    logger.info('  cd $projectName');
    logger.info('  flutter pub get');
    logger.info('  flutter run');
  } catch (e) {
    logger.err('Error: $e');
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('Usage: ftcreate <project_name> [options]');
  print('');
  print('Create a new Flutter project from a custom template');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Example:');
  print('  ftcreate my_app -t /path/to/template -o com.mycompany');
}
