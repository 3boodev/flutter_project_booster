import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('FlutterProjectBooster CLI Tests', () {
    test('Create project structure', () async {
      final result = await Process.run('dart', ['bin/flutter_project_booster.dart', '--create']);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Created directory'));
      expect(result.stdout, contains('Created file'));
      expect(result.stdout, contains('Updated pubspec.yaml successfully.'));
    });

    test('Remove unused dependencies', () async {
      final result = await Process.run('dart', ['bin/flutter_project_booster.dart', '--remove']);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Removed unused package'));
    });
  });
}
