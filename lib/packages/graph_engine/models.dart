class DependencyGraph {
  final List<Node> nodes;

  DependencyGraph({required this.nodes});

  Map<String, dynamic> toJson({Map<String, dynamic>? projectSummaryJson}) {
    // Generate edges from node dependencies
    final edges = <Edge>[];
    final Map<String, int> incomingEdges = {};
    final Map<String, int> outgoingEdges = {};
    final Map<String, List<String>> reverseDependencies = {}; // Who depends on this node?

    for (final node in nodes) {
      incomingEdges[node.id] = 0;
      outgoingEdges[node.id] = 0;
      reverseDependencies[node.id] = [];
    }

    for (final node in nodes) {
      for (final dep in node.dependencies) {
        edges.add(Edge(source: node.id, target: dep, type: 'imports'));
        
        outgoingEdges[node.id] = (outgoingEdges[node.id] ?? 0) + 1;
        incomingEdges[dep] = (incomingEdges[dep] ?? 0) + 1;
        
        if (reverseDependencies.containsKey(dep)) {
          reverseDependencies[dep]!.add(node.id);
        }
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
    
    // Impact Radius (BFS for every node)
    final Map<String, List<String>> impactRadius = {};
    for (final node in nodes) {
      final queue = [node.id];
      final impacted = <String>{};
      
      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        final revDeps = reverseDependencies[current] ?? [];
        for (final revDep in revDeps) {
          if (!impacted.contains(revDep)) {
            impacted.add(revDep);
            queue.add(revDep);
          }
        }
      }
      impactRadius[node.id] = impacted.toList();
    }

    // Calculate Architecture Score
    int score = 100;
    if (circularDependencies.isNotEmpty) {
      score -= (circularDependencies.length * 5);
    }
    
    // Calculate type metrics
    int totalScreens = 0;
    int totalModels = 0;
    int totalRepositories = 0;
    int totalServices = 0;
    int totalWidgets = 0;
    
    for (final node in nodes) {
      if (node.type == 'screen') {
        totalScreens++;
      } else if (node.type == 'model') {
        totalModels++;
      } else if (node.type == 'repository') {
        totalRepositories++;
      } else if (node.type == 'service') {
        totalServices++;
      } else if (node.type == 'widget') {
        totalWidgets++;
      }
    }

    // Dynamic Threshold Calculation
    int threshold = nodes.length;
    if (nodes.length <= 50) {
      threshold = nodes.length;
    } else if (nodes.length <= 200) {
      threshold = 50;
    } else if (nodes.length <= 1000) {
      threshold = 75;
    } else {
      threshold = 100;
    }

    // Find Highly Coupled / God Classes & Rank Nodes
    final highlyCoupled = <Map<String, dynamic>>[];
    final godClasses = <Map<String, dynamic>>[];
    final allNodesRanked = <Map<String, dynamic>>[];
    
    for (final node in nodes) {
      final inDegree = incomingEdges[node.id] ?? 0;
      final outDegree = outgoingEdges[node.id] ?? 0;
      final totalDegree = inDegree + outDegree;
      
      allNodesRanked.add({'id': node.id, 'score': totalDegree});
      
      if (totalDegree > 20) {
        highlyCoupled.add({'id': node.id, 'score': totalDegree});
        score -= 2; // Penalize for high coupling
      }
      
      if (outDegree > 15) {
        godClasses.add({'id': node.id, 'imports': outDegree});
        score -= 3; // Penalize for god classes
      }
    }

    allNodesRanked.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final topNodes = allNodesRanked.take(threshold).map((e) => e['id'] as String).toList();

    score = score.clamp(0, 100);

    // Dead Code: files with 0 incoming dependencies
    final deadCode = nodes.where((n) {
      final inDeg = incomingEdges[n.id] ?? 0;
      final label = n.label.toLowerCase();
      // Exclude main.dart and generated files
      return inDeg == 0 && !label.contains('main') && !label.contains('.g.') && !label.contains('.freezed.');
    }).map((n) => {'id': n.id, 'label': n.label, 'type': n.type}).toList();

    // Folder Map: group nodes by module with type breakdown
    final Map<String, Map<String, dynamic>> folderMap = {};
    for (final node in nodes) {
      final parts = node.id.split('/');
      final module = parts.length > 2 ? parts.sublist(1, parts.length - 1).join('/') : 'root';
      folderMap.putIfAbsent(module, () => {'count': 0, 'screens': 0, 'models': 0, 'state': 0, 'repository': 0, 'files': 0});
      folderMap[module]!['count'] = (folderMap[module]!['count'] as int) + 1;
      final typeKey = node.type == 'screen' ? 'screens'
          : node.type == 'model' ? 'models'
          : node.type == 'state' ? 'state'
          : node.type == 'repository' ? 'repository'
          : 'files';
      folderMap[module]![typeKey] = (folderMap[module]![typeKey] as int) + 1;
    }
    final folderMapList = folderMap.entries
        .map((e) => {'module': e.key, ...e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

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
        'total_screens': totalScreens,
        'total_models': totalModels,
        'total_repositories': totalRepositories,
        'total_services': totalServices,
        'total_widgets': totalWidgets,
        'dynamic_threshold': threshold,
        'top_nodes': topNodes,
        'all_nodes_ranked': allNodesRanked,
        'impact_radius': impactRadius,
        'dead_code': deadCode,
        'folder_map': folderMapList,
        'project_summary': projectSummaryJson,
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
      // package:name/folder/subfolder/file.dart -> module = folder/subfolder
      module = parts.sublist(1, parts.length - 1).join('/');
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
