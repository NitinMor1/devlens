class ProjectSummary {
  final TechStack techStack;
  final ArchitecturePattern architecturePattern;
  final int totalFiles;
  final int screens;
  final int models;
  final int repositories;
  final int services;

  ProjectSummary({
    required this.techStack,
    required this.architecturePattern,
    this.totalFiles = 0,
    this.screens = 0,
    this.models = 0,
    this.repositories = 0,
    this.services = 0,
  });

  @override
  String toString() {
    return '''
Project Summary
---------------------
Architecture: ${architecturePattern.name}

Tech Stack:
- State Management: ${techStack.stateManagement.isEmpty ? 'None detected' : techStack.stateManagement.join(', ')}
- Routing: ${techStack.routing.isEmpty ? 'None detected' : techStack.routing.join(', ')}
- Core Packages: ${techStack.corePackages.isEmpty ? 'None detected' : techStack.corePackages.join(', ')}

Files: $totalFiles
Screens: $screens
Models: $models
Repositories: $repositories
Services: $services
''';
  }
}

class TechStack {
  final List<String> stateManagement;
  final List<String> routing;
  final List<String> corePackages;

  TechStack({
    this.stateManagement = const [],
    this.routing = const [],
    this.corePackages = const [],
  });
}

enum ArchitecturePattern {
  cleanArchitecture('Clean Architecture'),
  featureFirst('Feature First'),
  layerFirst('Layer First (MVC/MVVM)'),
  unknown('Unknown');

  final String name;
  const ArchitecturePattern(this.name);
}
