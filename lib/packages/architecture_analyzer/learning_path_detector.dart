import 'package:devlens/packages/graph_engine/models.dart';

class LearningPathDetector {
  List<String> detect(DependencyGraph graph) {
    final path = <String>[];
    
    // 1. Find main.dart
    Node? mainNode;
    try {
      mainNode = graph.nodes.firstWhere((n) => n.id.endsWith('main.dart'));
    } catch (_) {}

    if (mainNode == null) return path;
    
    path.add(mainNode.label); // Usually 'main.dart'

    // Map out nodes for quick lookup
    final Map<String, Node> nodeMap = {for (var n in graph.nodes) n.id: n};

    // Helper to find most connected dependency of a specific type or any
    Node? findNext(Node current, {String? type}) {
      Node? bestNode;
      int maxDeps = -1;
      
      for (final depId in current.dependencies) {
        final depNode = nodeMap[depId];
        if (depNode != null && !path.contains(depNode.label)) {
          if (type == null || depNode.type == type) {
            // Favor nodes that have more outgoing dependencies (core files)
            if (depNode.dependencies.length > maxDeps) {
              maxDeps = depNode.dependencies.length;
              bestNode = depNode;
            }
          }
        }
      }
      return bestNode;
    }

    // 2. Find core setup (app.dart, routing)
    final appNode = findNext(mainNode);
    if (appNode != null) {
      path.add(appNode.label);
      
      // 3. Find first screen
      final screenNode = findNext(appNode, type: 'screen') ?? findNext(mainNode, type: 'screen');
      if (screenNode != null) {
        path.add(screenNode.label);
        
        // 4. Find core repository or service used by that screen
        final repoNode = findNext(screenNode, type: 'repository') ?? findNext(screenNode, type: 'service');
        if (repoNode != null) {
          path.add(repoNode.label);
          
          // 5. Find core model
          final modelNode = findNext(repoNode, type: 'model');
          if (modelNode != null) {
            path.add(modelNode.label);
          }
        }
      }
    }

    return path;
  }
}
