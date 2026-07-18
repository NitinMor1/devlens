class DependencyGraph {
  final List<Node> nodes;

  DependencyGraph({required this.nodes});

  Map<String, dynamic> toJson() {
    // Generate edges from node dependencies
    final edges = <Edge>[];
    for (final node in nodes) {
      for (final dep in node.dependencies) {
        edges.add(Edge(source: node.id, target: dep, type: 'imports'));
      }
    }

    return {
      'nodes': nodes.map((e) => e.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
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
    return {
      'id': id,
      'label': label,
      'type': type,
      'group': group,
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
