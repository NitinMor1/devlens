import 'package:args/command_runner.dart';
import 'package:devlens/packages/parser/dart_parser.dart';
import 'package:devlens/packages/graph_engine/models.dart';
import 'package:devlens/packages/reports/json_exporter.dart';
import 'package:devlens/packages/reports/html_exporter.dart';
import 'package:devlens/packages/architecture_analyzer/architecture_detector.dart';
import 'package:devlens/packages/architecture_analyzer/tech_stack_detector.dart';
import 'package:devlens/packages/architecture_analyzer/project_summary.dart';
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

    print('Detecting Architecture & Tech Stack...');
    final archPattern = ArchitectureDetector().detect(absolutePath);
    final techStack = TechStackDetector().detect(absolutePath);

    print('Parsing Dart files...');
    final parser = DartParser(rootPath: absolutePath);
    final nodes = await parser.parseProject();

    print('Parsed ${nodes.length} files.');

    print('Generating graph...');
    final graph = DependencyGraph(nodes: nodes);
    
    final summaryJson = {
      'architecture': archPattern.name,
      'state_management': techStack.stateManagement,
      'routing': techStack.routing,
      'core_packages': techStack.corePackages,
    };
    
    final graphData = graph.toJson(projectSummaryJson: summaryJson);
    final metrics = graphData['metrics'] as Map<String, dynamic>;

    print('\n🚀 DevLens Architecture Report\n');
    print('Project Overview');
    print('-------------------------');
    print('Files:              ${metrics['total_nodes']}');
    print('Screens:            ${metrics['total_screens']}');
    print('Models:             ${metrics['total_models']}');
    print('Repositories:       ${metrics['total_repositories']}');
    print('Services:           ${metrics['total_services']}');
    print('Widgets:            ${metrics['total_widgets']}');
    
    print('\nArchitecture Health');
    print('-------------------------');
    final circularCount = (metrics['circular_dependencies'] as List).length;
    print('Circular Dependencies:       $circularCount   ${circularCount > 0 ? '(WARNING)' : ''}');
    
    final coupledCount = (metrics['highly_coupled'] as List).length;
    print('Highly Coupled Files:       $coupledCount   ${coupledCount > 0 ? '(WARNING)' : ''}');
    
    final godCount = (metrics['god_classes'] as List).length;
    print('God Classes (>15 imports):  $godCount   ${godCount > 0 ? '(WARNING)' : ''}');

    print('\nTop Connected Files (Relevance)');
    print('-------------------------');
    final ranked = metrics['all_nodes_ranked'] as List;
    for (int i = 0; i < ranked.length && i < 3; i++) {
      final node = ranked[i];
      final id = node['id'] as String;
      final name = id.split('/').last;
      print('${i + 1}. $name (${node['score']} connections)');
    }

    print('\nExporting reports...');
    final outDir = p.join(absolutePath, '.dep_explorer');
    await JsonExporter.export(graph, graphData, outDir);
    await HtmlExporter.export(graphData, outDir);

    print('\nScan complete! Reports saved to $outDir');
    
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
