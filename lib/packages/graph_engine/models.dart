class DependencyGraph {
  final List<Node> nodes;

  DependencyGraph({required this.nodes});

  Map<String, dynamic> toJson() {
    // Generate edges from node dependencies
    final edges = <Edge>[];
    final Map<String, int> incomingEdges = {};
    final Map<String, int> outgoingEdges = {};

    for (final node in nodes) {
      incomingEdges[node.id] = 0;
      outgoingEdges[node.id] = 0;
    }

    for (final node in nodes) {
      for (final dep in node.dependencies) {
        edges.add(Edge(source: node.id, target: dep, type: 'imports'));
        
        outgoingEdges[node.id] = (outgoingEdges[node.id] ?? 0) + 1;
        incomingEdges[dep] = (incomingEdges[dep] ?? 0) + 1;
      }
    }

    // Detect Circular Dependencies (Simple DFS)
    final circularDependencies = <List<String>>[];
    final visited = <String>{};
    final recStack = <String>{};
    final Map<String, Node> nodeMap = {for (var n in nodes) n.id: n};

    void detectCycle(String nodeId, List<String> path) {
      visited.add(nodeId);
      recStack.add(nodeId);
      path.add(nodeId);

      final node = nodeMap[nodeId];
      if (node != null) {
        for (final dep in node.dependencies) {
          if (!visited.contains(dep)) {
            detectCycle(dep, List.from(path));
          } else if (recStack.contains(dep)) {
            // Cycle found
            final cycleIndex = path.indexOf(dep);
            if (cycleIndex != -1) {
              circularDependencies.add(path.sublist(cycleIndex));
            }
          }
        }
      }
      recStack.remove(nodeId);
    }

    for (final node in nodes) {
      if (!visited.contains(node.id)) {
        detectCycle(node.id, []);
      }
    }

    // Calculate Architecture Score
    int score = 100;
    if (circularDependencies.isNotEmpty) {
      score -= (circularDependencies.length * 5);
    }
    
    // Find Highly Coupled / God Classes
    final highlyCoupled = <Map<String, dynamic>>[];
    final godClasses = <Map<String, dynamic>>[];
    
    for (final node in nodes) {
      final inDegree = incomingEdges[node.id] ?? 0;
      final outDegree = outgoingEdges[node.id] ?? 0;
      
      if (inDegree + outDegree > 20) {
        highlyCoupled.add({'id': node.id, 'score': inDegree + outDegree});
        score -= 2; // Penalize for high coupling
      }
      
      if (outDegree > 15) {
        godClasses.add({'id': node.id, 'imports': outDegree});
        score -= 3; // Penalize for god classes
      }
    }

    score = score.clamp(0, 100);

    return {
      'nodes': nodes.map((e) => e.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
      'metrics': {
        'architecture_score': score,
        'circular_dependencies': circularDependencies,
        'highly_coupled': highlyCoupled..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int)),
        'god_classes': godClasses..sort((a, b) => (b['imports'] as int).compareTo(a['imports'] as int)),
        'total_nodes': nodes.length,
        'total_edges': edges.length,
      }
    };
  }
}

class Node {
  final String id;
  final String label;
  final String type;
  final String group;
  final List<String> dependencies;

  Node({
    required this.id,
    required this.label,
    required this.type,
    this.group = 'core',
    this.dependencies = const [],
  });

  Map<String, dynamic> toJson() {
    // Determine the folder module
    final parts = id.split('/');
    String module = 'root';
    if (parts.length > 2) {
      // package:name/folder/file.dart -> module = folder
      module = parts[1]; 
    }

    return {
      'id': id,
      'label': label,
      'type': type,
      'group': group,
      'module': module,
    };
  }
}

class Edge {
  final String source;
  final String target;
  final String type;

  Edge({
    required this.source,
    required this.target,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'target': target,
      'type': type,
    };
  }
}
