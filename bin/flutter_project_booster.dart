import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:args/args.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('create', abbr: 'c', help: 'Create project structure and clean pubspec.yaml')
    ..addFlag('remove', abbr: 'r', help: 'Remove unused dependencies from pubspec.yaml');

  final argResults = parser.parse(args);

  if (argResults['create'] as bool) {
    await _createProjectStructure();
  } else if (argResults['remove'] as bool) {
    await _removeUnusedDependencies();
  } else {
    print('Please specify an action: --create or --remove');
    exit(1);
  }
}

Future<void> _createProjectStructure() async {
  final basePath = Directory.current.path;
  final pubspecPath = p.join(basePath, 'pubspec.yaml');

  // load JSON file from inside the package
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_project_booster/assets/project_components.json'),
  );

  if (uri == null) {
    stderr.writeln('❌ Error: Cannot locate project_components.json inside the package.');
    exit(1);
  }

  final jsonFile = File.fromUri(uri);
  if (!jsonFile.existsSync()) {
    stderr.writeln('❌ Error: project_components.json not found at ${jsonFile.path}');
    exit(1);
  }

  final jsonString = jsonFile.readAsStringSync();
  final Map<String, dynamic> project = jsonDecode(jsonString);
  final pubspecFile = File(pubspecPath);

  // Step 1: Create directories
  for (var dir in project['directories']) {
    final dirPath = Directory(p.join(basePath, dir));
    if (!dirPath.existsSync()) {
      dirPath.createSync(recursive: true);
      print('📁 Created directory: ${dirPath.path}');
    }
  }

  // Step 2: Create files
  for (var filePath in project['files']) {
    final file = File(p.join(basePath, filePath));
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      print('📄 Created file: ${file.path}');
    }
  }

  // Step 3: Update pubspec.yaml
  if (pubspecFile.existsSync()) {
    var content = pubspecFile.readAsStringSync();

    content = _removeComments(content);
    content = _addDependencies(content, project["dependencies"], "dependencies");
    content = _addDependencies(content, project["dev_dependencies"], "dev_dependencies");
    content = _addAssets(content, project["assets"]);

    pubspecFile.writeAsStringSync(content);
    print('✅ Updated pubspec.yaml successfully.');
  } else {
    stderr.writeln('❌ Error: pubspec.yaml not found at $pubspecPath');
    exit(1);
  }

  // Step 4: Run flutter pub get
  final result = await Process.run('flutter', ['pub', 'get']);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  print('🚀 Dependencies installed.');
}

Future<void> _removeUnusedDependencies() async {
  final basePath = Directory.current.path;
  final pubspecPath = p.join(basePath, 'pubspec.yaml');

  final pubspecFile = File(pubspecPath);
  if (!pubspecFile.existsSync()) {
    stderr.writeln('❌ Error: pubspec.yaml not found at $pubspecPath');
    exit(1);
  }

  var content = pubspecFile.readAsStringSync();
  content = _removeUnusedDependenciesFromYaml(content);

  pubspecFile.writeAsStringSync(content);
  print('✅ Removed unused dependencies from pubspec.yaml');
}

String _removeComments(String content) {
  return content
      .split('\n')
      .where((line) => !line.trim().startsWith('#'))
      .join('\n')
      .replaceAll(RegExp(r'\n\s*\n'), '\n');
}

String _addDependencies(String content, List<dynamic>? dependencies, String section) {
  if (dependencies == null || dependencies.isEmpty) return content;

  if (!content.contains('$section:')) {
    content += '\n$section:\n';
  }

  for (var package in dependencies) {
    final packageEntry = '  $package:\n';
    if (!content.contains(RegExp('  $package:'))) {
      content = content.replaceFirst('$section:\n', '$section:\n$packageEntry');
    }
  }

  return content;
}

String _addAssets(String content, List<dynamic>? assets) {
  if (assets == null || assets.isEmpty) return content;

  if (!content.contains('flutter:')) {
    content += '\nflutter:\n';
  }

  if (!content.contains('  assets:')) {
    content = content.replaceFirst('flutter:\n', 'flutter:\n  assets:\n');
  }

  for (var asset in assets) {
    final assetEntry = '    - $asset\n';
    if (!content.contains(assetEntry)) {
      content = content.replaceFirst('  assets:\n', '  assets:\n$assetEntry');
    }
  }

  return content;
}

String _removeUnusedDependenciesFromYaml(String content) {
  final dependencies = _getDependenciesFromPubspec(content);
  final dartFiles = _getDartFiles();
  final usedPackagesWithFiles = _getUsedPackagesWithFiles(dartFiles);

  for (var dependency in dependencies) {
    if (!usedPackagesWithFiles.containsKey(dependency)) {
      final regex = RegExp(r'^\s*' + RegExp.escape(dependency) + r':.*\n?', multiLine: true);
      content = content.replaceAll(regex, '');
      print('🧹 Removed unused package: $dependency');
    } else {
      final files = usedPackagesWithFiles[dependency]!;
      print('📦 Package "$dependency" is used in:');
      for (var file in files) {
        print('   → $file');
      }
    }
  }

  return content;
}

List<String> _getDependenciesFromPubspec(String content) {
  final dependencies = <String>[];

  // convert the content to a YamlMap
  final yamlMap = loadYaml(content);

  // Extract the dependencies from the yamlMap
  if (yamlMap['dependencies'] != null) {
    final dependenciesMap = yamlMap['dependencies'] as YamlMap;
    dependenciesMap.forEach((key, value) {
      dependencies.add(key);
    });
  }

  // Extract the dev_dependencies from the yamlMap
  // if (yamlMap['dev_dependencies'] != null) {
  //   final devDependenciesMap = yamlMap['dev_dependencies'] as YamlMap;
  //   devDependenciesMap.forEach((key, value) {
  //     dependencies.add(key);
  //   });
  // }


  // Extract the Assets from the yamlMap
  if (yamlMap['assets'] != null) {
    final devDependenciesMap = yamlMap['assets'] as YamlMap;
    devDependenciesMap.forEach((key, value) {
      dependencies.add(key);
    });
  }

  return dependencies;
}

List<FileSystemEntity> _getDartFiles() {
  final dartFiles = <FileSystemEntity>[];
  final dir = Directory(Directory.current.path);
  final files = dir.listSync(recursive: true);
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      dartFiles.add(file);
    }
  }
  return dartFiles;
}

Map<String, List<String>> _getUsedPackagesWithFiles(List<FileSystemEntity> dartFiles) {
  final usedPackages = <String, List<String>>{};
  final regex = RegExp(r'package:([a-zA-Z0-9_/-]+)', multiLine: true);

  for (var dartFile in dartFiles) {
    if (dartFile is File) {
      final content = dartFile.readAsStringSync();
      final matches = regex.allMatches(content);
      for (var match in matches) {
        final packageName = match.group(1)!.split('/').first;
        usedPackages.putIfAbsent(packageName, () => []).add(dartFile.path);
      }
    }
  }

  return usedPackages;
}
