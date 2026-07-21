import 'package:args/command_runner.dart';
import 'package:devlens/packages/parser/dart_parser.dart';
import 'package:devlens/packages/graph_engine/models.dart';
import 'package:devlens/packages/reports/json_exporter.dart';
import 'package:devlens/packages/reports/html_exporter.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class ScanCommand extends Command<void> {
  @override
  final name = 'scan';

  @override
  final description = 'Scans the Flutter project and generates dependency reports.';

  ScanCommand() {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'The path to the Flutter project. Defaults to current directory.',
      defaultsTo: '.',
    );
  }

  @override
  Future<void> run() async {
    final targetPath = argResults?['path'] as String;
    final absolutePath = p.absolute(targetPath);
    print('Scanning project at: $absolutePath');

    final libPath = p.join(absolutePath, 'lib');
    if (!Directory(libPath).existsSync()) {
      print('Error: Could not find lib/ directory at $libPath');
      print('Make sure you are running this in a Flutter or Dart project root.');
      return;
    }

    print('Parsing Dart files...');
    final parser = DartParser(rootPath: absolutePath);
    final nodes = await parser.parseProject();

    print('Parsed ${nodes.length} files.');

    print('Generating graph...');
    final graph = DependencyGraph(nodes: nodes);

    print('Exporting reports...');
    final outDir = p.join(absolutePath, '.dep_explorer');
    await JsonExporter.export(graph, outDir);
    await HtmlExporter.export(graph, outDir);

    print('Scan complete! Reports saved to $outDir');
    
    final htmlPath = p.normalize(p.join(outDir, 'index.html'));
    final fileUri = 'file:///${htmlPath.replaceAll('\\', '/')}';
    
    print('\n🚀 Visualization ready! Opening in your browser...');
    
    try {
      if (Platform.isWindows) {
        await Process.run('start', [fileUri], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [fileUri]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [fileUri]);
      }
    } catch (e) {
      print('Could not open browser automatically. You can open this file manually:');
      print('   $fileUri');
    }
  }
}
