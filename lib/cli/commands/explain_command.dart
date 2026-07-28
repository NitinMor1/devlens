import 'package:args/command_runner.dart';
import 'package:devlens/packages/parser/dart_parser.dart';
import 'package:devlens/packages/graph_engine/models.dart';
import 'package:devlens/packages/architecture_analyzer/architecture_detector.dart';
import 'package:devlens/packages/architecture_analyzer/tech_stack_detector.dart';
import 'package:devlens/packages/architecture_analyzer/project_summary.dart';
import 'package:devlens/packages/architecture_analyzer/learning_path_detector.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class ExplainCommand extends Command<void> {
  @override
  final name = 'explain';

  @override
  final description = 'Provides an AI-like onboarding explanation of the project architecture and stack.';

  ExplainCommand() {
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
    print('Analyzing project at: $absolutePath\n');

    final libPath = p.join(absolutePath, 'lib');
    if (!Directory(libPath).existsSync()) {
      print('Error: Could not find lib/ directory at $libPath');
      return;
    }

    print('Detecting Architecture...');
    final archPattern = ArchitectureDetector().detect(absolutePath);

    print('Detecting Tech Stack...');
    final techStack = TechStackDetector().detect(absolutePath);

    print('Parsing Files for Statistics...');
    final parser = DartParser(rootPath: absolutePath);
    final nodes = await parser.parseProject();
    final graph = DependencyGraph(nodes: nodes);
    final graphData = graph.toJson();
    final metrics = graphData['metrics'] as Map<String, dynamic>;

    final learningPath = LearningPathDetector().detect(graph);

    final summary = ProjectSummary(
      techStack: techStack,
      architecturePattern: archPattern,
      totalFiles: metrics['total_nodes'] as int? ?? 0,
      screens: metrics['total_screens'] as int? ?? 0,
      models: metrics['total_models'] as int? ?? 0,
      repositories: metrics['total_repositories'] as int? ?? 0,
      services: metrics['total_services'] as int? ?? 0,
      learningPath: learningPath,
    );

    print('\n=============================================');
    print('DevLens AI Project Explorer (Onboarding)');
    print('=============================================\n');
    print(summary.toString());
    
    print('Recommended Learning Path');
    print('---------------------');
    if (learningPath.isEmpty) {
      print('Could not detect a clear learning path (main.dart not found).');
    } else {
      for (int i = 0; i < learningPath.length; i++) {
        print('  [${i + 1}] ${learningPath[i]}');
        if (i < learningPath.length - 1) {
          print('   ↓');
        }
      }
    }
    print('\n=============================================');
  }
}
