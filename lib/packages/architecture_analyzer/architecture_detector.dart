import 'dart:io';
import 'project_summary.dart';

class ArchitectureDetector {
  ArchitecturePattern detect(String projectPath) {
    final libDir = Directory('$projectPath/lib');
    if (!libDir.existsSync()) {
      return ArchitecturePattern.unknown;
    }

    final entities = libDir.listSync(recursive: true);
    final dirs = entities.whereType<Directory>().map((e) {
      // Get the relative path from lib directory
      return e.path.substring(libDir.path.length).replaceAll('\\', '/');
    }).toList();

    bool hasDomain = false;
    bool hasData = false;
    bool hasPresentation = false;
    
    bool hasFeatures = false;
    
    bool hasModels = false;
    bool hasViews = false;
    bool hasControllers = false;

    for (final dir in dirs) {
      final lowerDir = dir.toLowerCase();
      if (lowerDir.contains('/domain')) hasDomain = true;
      if (lowerDir.contains('/data')) hasData = true;
      if (lowerDir.contains('/presentation')) hasPresentation = true;

      if (lowerDir.contains('/features') || lowerDir.contains('/modules')) hasFeatures = true;

      if (lowerDir.contains('/models')) hasModels = true;
      if (lowerDir.contains('/views') || lowerDir.contains('/ui') || lowerDir.contains('/screens')) hasViews = true;
      if (lowerDir.contains('/controllers') || lowerDir.contains('/viewmodels')) hasControllers = true;
    }

    if (hasDomain && hasData && hasPresentation) {
      return ArchitecturePattern.cleanArchitecture;
    }

    if (hasFeatures) {
      return ArchitecturePattern.featureFirst;
    }
    
    if (hasModels && hasViews && hasControllers) {
      return ArchitecturePattern.layerFirst;
    }

    return ArchitecturePattern.unknown;
  }
}
