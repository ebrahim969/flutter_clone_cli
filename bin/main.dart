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
    )
    ..addOption(
      'flutter-version',
      abbr: 'v',
      help:
          'Flutter version to use (e.g., 3.16.0, stable, beta). If not specified, uses current Flutter version.',
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
    final flutterVersion = results['flutter-version'] as String?;

    if (templatePath == null) {
      logger.err('Please provide a template path using --template or -t');
      exit(1);
    }

    // Check current Flutter version
    final currentVersion = await _getCurrentFlutterVersion(logger);

    if (flutterVersion != null) {
      logger.info('Requested Flutter version: $flutterVersion');
      logger.info('Current Flutter version: $currentVersion');

      // Switch Flutter version if needed
      if (flutterVersion != currentVersion) {
        await _switchFlutterVersion(logger, flutterVersion);
      } else {
        logger.info('Already using Flutter $flutterVersion');
      }
    } else {
      logger.info('Using current Flutter version: $currentVersion');
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

/// Gets the current Flutter version from the system
Future<String> _getCurrentFlutterVersion(Logger logger) async {
  try {
    final result = await Process.run('flutter', ['--version']);

    if (result.exitCode != 0) {
      throw Exception('Failed to get Flutter version');
    }

    final output = result.stdout.toString();
    final versionMatch = RegExp(r'Flutter (\S+)').firstMatch(output);

    if (versionMatch != null) {
      return versionMatch.group(1)!;
    }

    throw Exception('Could not parse Flutter version');
  } catch (e) {
    logger.warn('Could not determine current Flutter version: $e');
    return 'unknown';
  }
}

/// Switches to a specific Flutter version using FVM or flutter channel/version
Future<void> _switchFlutterVersion(Logger logger, String version) async {
  // First, try using FVM if available
  final fvmAvailable = await _isFvmAvailable();

  if (fvmAvailable) {
    await _switchWithFvm(logger, version);
  } else {
    await _switchWithFlutterSdk(logger, version);
  }
}

/// Checks if FVM is installed
Future<bool> _isFvmAvailable() async {
  try {
    final result = await Process.run('fvm', ['--version']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

/// Switches Flutter version using FVM
Future<void> _switchWithFvm(Logger logger, String version) async {
  logger.info('Using FVM to switch Flutter version...');

  final installProgress = logger.progress(
    'Installing Flutter $version with FVM',
  );

  try {
    // Install the version if not already installed
    final installResult = await Process.run('fvm', ['install', version]);

    if (installResult.exitCode != 0) {
      installProgress.fail('Failed to install Flutter $version');
      throw Exception('FVM install failed: ${installResult.stderr}');
    }

    installProgress.complete('Flutter $version installed');

    // Use the version globally
    final useProgress = logger.progress('Setting Flutter $version as global');
    final useResult = await Process.run('fvm', ['global', version]);

    if (useResult.exitCode != 0) {
      useProgress.fail('Failed to set global Flutter version');
      throw Exception('FVM global failed: ${useResult.stderr}');
    }

    useProgress.complete('Switched to Flutter $version');
  } catch (e) {
    throw Exception('Failed to switch Flutter version with FVM: $e');
  }
}

/// Switches Flutter version using Flutter SDK directly
Future<void> _switchWithFlutterSdk(Logger logger, String version) async {
  logger.info('Switching Flutter version using Flutter SDK...');

  // Check if it's a channel (stable, beta, master)
  final channels = ['stable', 'beta', 'master', 'dev'];

  if (channels.contains(version.toLowerCase())) {
    // Switch channel
    final channelProgress = logger.progress('Switching to $version channel');

    final result = await Process.run('flutter', ['channel', version]);

    if (result.exitCode != 0) {
      channelProgress.fail('Failed to switch channel');
      throw Exception('Channel switch failed: ${result.stderr}');
    }

    channelProgress.complete('Switched to $version channel');

    // Upgrade to latest on that channel
    final upgradeProgress = logger.progress('Upgrading Flutter');
    final upgradeResult = await Process.run('flutter', ['upgrade']);

    if (upgradeResult.exitCode != 0) {
      upgradeProgress.fail('Failed to upgrade Flutter');
      throw Exception('Flutter upgrade failed: ${upgradeResult.stderr}');
    }

    upgradeProgress.complete('Flutter upgraded successfully');
  } else {
    // Try to switch to a specific version
    logger.warn(
      'Switching to specific versions without FVM is not recommended.\n'
      'Please install FVM (https://fvm.app) for better version management.',
    );

    // Attempt to use git to checkout a specific version
    final flutterSdkPath = await _getFlutterSdkPath();

    if (flutterSdkPath != null) {
      final checkoutProgress = logger.progress('Checking out Flutter $version');

      final result = await Process.run('git', [
        'checkout',
        version,
      ], workingDirectory: flutterSdkPath);

      if (result.exitCode != 0) {
        checkoutProgress.fail('Failed to checkout version');
        throw Exception(
          'Git checkout failed. Consider using FVM for easier version management.',
        );
      }

      checkoutProgress.complete('Checked out Flutter $version');

      // Run flutter precache
      final precacheProgress = logger.progress('Running flutter precache');
      await Process.run('flutter', ['precache']);
      precacheProgress.complete('Precache completed');
    } else {
      throw Exception(
        'Could not find Flutter SDK path. Please install FVM for version management.',
      );
    }
  }
}

/// Gets the Flutter SDK path
Future<String?> _getFlutterSdkPath() async {
  try {
    final result = await Process.run('which', ['flutter']);

    if (result.exitCode == 0) {
      final flutterPath = result.stdout.toString().trim();
      // Remove /bin/flutter to get SDK path
      final sdkPath = flutterPath.replaceAll(RegExp(r'/bin/flutter$'), '');
      return sdkPath;
    }

    return null;
  } catch (e) {
    return null;
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
  print('Examples:');
  print('  # Create with current Flutter version');
  print('  ftcreate my_app -t /path/to/template -o com.mycompany');
  print('');
  print('  # Create with specific Flutter version');
  print('  ftcreate my_app -t /path/to/template -v 3.16.0');
  print('');
  print('  # Create with Flutter stable channel');
  print('  ftcreate my_app -t /path/to/template -v stable');
  print('');
  print('Note: For better version management, install FVM (https://fvm.app)');
}
