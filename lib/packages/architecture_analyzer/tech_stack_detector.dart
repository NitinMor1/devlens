import 'dart:io';
import 'package:yaml/yaml.dart';
import 'project_summary.dart';

class TechStackDetector {
  static const Map<String, String> _stateManagementPackages = {
    'riverpod': 'Riverpod',
    'flutter_riverpod': 'Riverpod',
    'provider': 'Provider',
    'bloc': 'BLoC',
    'flutter_bloc': 'BLoC',
    'get': 'GetX',
    'mobx': 'MobX',
    'redux': 'Redux',
  };

  static const Map<String, String> _routingPackages = {
    'go_router': 'GoRouter',
    'auto_route': 'AutoRoute',
    'fluro': 'Fluro',
    'vrouter': 'VRouter',
    'beamer': 'Beamer',
  };

  static const Map<String, String> _corePackages = {
    'dio': 'Dio',
    'http': 'HTTP',
    'firebase_core': 'Firebase',
    'hive': 'Hive',
    'sqflite': 'Sqflite',
    'shared_preferences': 'Shared Preferences',
    'freezed': 'Freezed',
    'dartz': 'Dartz',
    'fpdart': 'Fpdart',
    'graphql_flutter': 'GraphQL',
  };

  TechStack detect(String projectPath) {
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      return TechStack();
    }

    final pubspecContent = pubspecFile.readAsStringSync();
    final yamlNode = loadYaml(pubspecContent);

    if (yamlNode is! YamlMap) {
      return TechStack();
    }

    final dependencies = yamlNode['dependencies'];
    final devDependencies = yamlNode['dev_dependencies'];

    final Set<String> stateManagement = {};
    final Set<String> routing = {};
    final Set<String> corePackages = {};

    bool isFlutter = false;

    void processDependencies(dynamic deps) {
      if (deps is YamlMap) {
        for (final entry in deps.entries) {
          final pkgName = entry.key.toString();
          
          if (pkgName == 'flutter') {
            isFlutter = true;
          }
          
          if (_stateManagementPackages.containsKey(pkgName)) {
            stateManagement.add(_stateManagementPackages[pkgName]!);
          }
          if (_routingPackages.containsKey(pkgName)) {
            routing.add(_routingPackages[pkgName]!);
          }
          if (_corePackages.containsKey(pkgName)) {
            corePackages.add(_corePackages[pkgName]!);
          }
        }
      }
    }

    processDependencies(dependencies);
    processDependencies(devDependencies);

    if (isFlutter && routing.isEmpty) {
      routing.add('Native Navigator');
    }

    return TechStack(
      stateManagement: stateManagement.toList()..sort(),
      routing: routing.toList()..sort(),
      corePackages: corePackages.toList()..sort(),
    );
  }
}
