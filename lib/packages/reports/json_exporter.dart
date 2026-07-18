import 'dart:convert';
import 'dart:io';
import 'package:devlens/packages/graph_engine/models.dart';
import 'package:path/path.dart' as p;

class JsonExporter {
  static Future<void> export(DependencyGraph graph, String outputDir) async {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final graphJson = jsonEncode(graph.toJson());
    final graphFile = File(p.join(outputDir, 'graph.json'));
    await graphFile.writeAsString(graphJson);

    final statsJson = jsonEncode({
      'total_nodes': graph.nodes.length,
      'screens': graph.nodes.where((n) => n.type == 'screen').length,
      'states': graph.nodes.where((n) => n.type == 'state').length,
      'repositories': graph.nodes.where((n) => n.type == 'repository').length,
      'models': graph.nodes.where((n) => n.type == 'model').length,
      'others': graph.nodes.where((n) => n.type == 'file').length,
    });
    
    final statsFile = File(p.join(outputDir, 'stats.json'));
    await statsFile.writeAsString(statsJson);
  }
}
