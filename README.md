# Flutter Template CLI

A command-line tool to create Flutter projects from custom templates. Similar to `flutter create`, but uses your own project as a template with automatic package ID and project name updates.

## Features

- 🚀 Create Flutter projects from custom templates
- 📦 Automatically updates project name in all files
- 🔄 Updates Android and iOS package IDs
- ✨ Clean and simple CLI interface
- 🎯 Skips build artifacts and hidden files

## Installation

### Global Installation

```bash
dart pub global activate flutter_clone_cli
```

### From Source

```bash
git clone https://github.com/yourusername/flutter_clone_cli.git
cd flutter_clone_cli
dart pub global activate --source path .
```

## Usage

### Basic Command

```bash
ftcreate my_new_app -t /path/to/template/project
```

### With Custom Organization ID

```bash
ftcreate my_new_app -t /path/to/template/project -o com.mycompany
```

### Full Options

```
Usage: ftcreate <project_name> [options]

Options:
  -h, --help              Print this usage information
  -t, --template          Path to the template Flutter project (required)
  -o, --org               Organization identifier (default: "com.example")
```

## How It Works

1. **Copies Template**: Creates a complete copy of your template project
2. **Updates Project Name**: Replaces the old project name in:
   - `pubspec.yaml`
   - All `.dart` files
   - `README.md`
   - Test files
3. **Updates Package IDs**: Configures Android and iOS bundle identifiers:
   - Android: `build.gradle`, `AndroidManifest.xml`, `MainActivity.kt`
   - iOS: `Info.plist`, `project.pbxproj`

## Project Name Rules

Project names must:
- Start with a lowercase letter
- Contain only lowercase letters, numbers, and underscores
- Examples: `my_app`, `awesome_project`, `app2`

## What Gets Excluded

The following are automatically excluded from copying:
- Hidden files and folders (`.git`, `.idea`, etc.)
- Build artifacts (`build/`, `.dart_tool/`)
- Flutter plugin files

## Example Workflow

1. Create your perfect template project with all your preferred packages, folder structure, and configurations
2. Use it to generate new projects:

```bash
# Navigate to where you want the new project
cd ~/projects

# Create from template
ftcreate shopping_app -t ~/templates/my_flutter_template -o com.mycompany

# Start developing
cd shopping_app
flutter pub get
flutter run
```

## Requirements

- Dart SDK >=3.0.0
- Flutter (for the template and generated projects)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/yourusername/flutter_template_cli).