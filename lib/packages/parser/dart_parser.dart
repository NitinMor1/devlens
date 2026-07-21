import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:devlens/packages/graph_engine/models.dart';
import 'package:path/path.dart' as p;

/// Core parser that analyzes Dart projects and extracts architecture metadata.
/// 
/// It traverses the lib/ directory to map dependencies and class types.
class DartParser {
  final String rootPath;
  late final String libPath;
  late final String packageName;

  DartParser({required this.rootPath}) {
    libPath = p.join(rootPath, 'lib');
    _detectPackageName();
  }

  void _detectPackageName() {
    final pubspec = File(p.join(rootPath, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final lines = pubspec.readAsLinesSync();
      for (final line in lines) {
        if (line.startsWith('name:')) {
          packageName = line.split(':')[1].trim();
          return;
        }
      }
    }
    packageName = p.basename(rootPath);
  }

  Future<List<Node>> parseProject() async {
    final nodes = <Node>[];
    final dir = Directory(libPath);
    
    if (!dir.existsSync()) return nodes;

    final files = dir.listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final node = _parseFile(file);
      if (node != null) {
        nodes.add(node);
      }
    }

    return nodes;
  }

  Node? _parseFile(File file) {
    try {
      final content = file.readAsStringSync();
      final result = parseString(content: content, throwIfDiagnostics: false);
      final unit = result.unit;

      final relativePath = p.relative(file.path, from: libPath);
      // Construct package URI to use as an ID
      final id = "package:$packageName/${relativePath.replaceAll('\\', '/')}";
      
      final dependencies = <String>[];

      for (final directive in unit.directives) {
        if (directive is ImportDirective) {
          final uri = directive.uri.stringValue;
          if (uri != null) {
             // Only include internal package dependencies to keep the graph clean
             if (uri.startsWith('package:$packageName/')) {
                 dependencies.add(uri);
             } else if (!uri.startsWith('package:') && !uri.startsWith('dart:')) {
                // relative import, convert to package import
                final fileDir = p.dirname(file.path);
                final absoluteTarget = p.normalize(p.join(fileDir, uri));
                final targetRelative = p.relative(absoluteTarget, from: libPath);
                final resolvedUri = "package:$packageName/${targetRelative.replaceAll('\\', '/')}";
                dependencies.add(resolvedUri);
             }
          }
        }
      }

      // Basic Type detection by looking at classes (e.g. if it ends with Screen, Bloc, etc)
      String type = 'file';
      for (final declaration in unit.declarations) {
        if (declaration is ClassDeclaration) {
          final className = declaration.namePart.typeName.lexeme;
          if (className.endsWith('Screen') || className.endsWith('Page') || className.endsWith('View')) {
            type = 'screen';
          } else if (className.endsWith('Bloc') || className.endsWith('Cubit')) {
            type = 'state';
          } else if (className.endsWith('Repository')) {
            type = 'repository';
          } else if (className.endsWith('Model') || className.endsWith('Entity')) {
            type = 'model';
          }
        }
      }

      return Node(
        id: id,
        label: p.basename(file.path),
        type: type,
        dependencies: dependencies,
      );
    } catch (e) {
      print('Error parsing \${file.path}: \$e');
      return null;
    }
  }
}
