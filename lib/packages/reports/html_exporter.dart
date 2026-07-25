import 'dart:convert';
import 'dart:io';
import 'package:devlens/packages/graph_engine/models.dart';
import 'package:path/path.dart' as p;

class HtmlExporter {
  static Future<void> export(DependencyGraph graph, String outputDir) async {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final graphJson = jsonEncode(graph.toJson());
    final htmlContent = _template.replaceFirst('__GRAPH_DATA__', graphJson);
    
    final htmlFile = File(p.join(outputDir, 'index.html'));
    await htmlFile.writeAsString(htmlContent);
  }

  static const String _template = r'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DevLens - Architecture Explorer</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <script type="text/javascript" src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style>
        :root {
            --bg-dark: #0f172a;
            --bg-panel: #1e293b;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --accent: #38bdf8;
            --border: #334155;
        }
        body, html {
            margin: 0; padding: 0; width: 100%; height: 100%;
            background-color: var(--bg-dark);
            color: var(--text-main);
            font-family: 'Inter', sans-serif;
            display: flex;
            overflow: hidden;
        }
        
        /* Sidebar */
        .sidebar {
            width: 320px;
            background-color: var(--bg-panel);
            border-right: 1px solid var(--border);
            display: flex;
            flex-direction: column;
            height: 100%;
        }
        .header {
            padding: 20px;
            border-bottom: 1px solid var(--border);
        }
        .header h1 { margin: 0; font-size: 1.5rem; color: var(--accent); }
        .score-badge {
            display: inline-block;
            background: rgba(16, 185, 129, 0.2);
            color: #10b981;
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: 600;
            margin-top: 10px;
            font-size: 0.875rem;
        }
        
        /* Tabs */
        .tabs {
            display: flex;
            border-bottom: 1px solid var(--border);
        }
        .tab {
            flex: 1; text-align: center; padding: 12px 0;
            cursor: pointer; color: var(--text-muted);
            font-weight: 500; font-size: 0.875rem;
            border-bottom: 2px solid transparent;
        }
        .tab.active { color: var(--accent); border-bottom-color: var(--accent); }
        
        /* Tab Content */
        .tab-content {
            flex: 1; overflow-y: auto; padding: 16px;
            display: none;
        }
        .tab-content.active { display: block; }
        
        /* Lists & Trees */
        ul { list-style: none; padding: 0; margin: 0; }
        .tree-node { margin-bottom: 4px; }
        .tree-node-label {
            padding: 6px 8px; border-radius: 4px; cursor: pointer;
            display: flex; align-items: center; gap: 8px; font-size: 0.875rem;
        }
        .tree-node-label:hover { background: rgba(255,255,255,0.05); }
        .tree-node-label.active { background: rgba(56, 189, 248, 0.1); color: var(--accent); }
        .tree-children { padding-left: 16px; display: none; }
        .tree-children.open { display: block; }
        
        /* Insights */
        .insight-card {
            background: rgba(0,0,0,0.2); padding: 12px; border-radius: 8px; margin-bottom: 12px;
        }
        .insight-card h4 { margin: 0 0 8px 0; color: #fca5a5; font-size: 0.875rem; text-transform: uppercase; }
        .insight-item { font-size: 0.875rem; margin-bottom: 4px; display: flex; justify-content: space-between;}
        
        /* Main Area */
        .main-area { flex: 1; display: flex; flex-direction: column; position: relative; }
        
        .workspace { flex: 1; position: relative; }

        /* Details Panel */
        .details-panel {
            position: absolute; top: 0; left: 0; right: 0; bottom: 0;
            padding: 24px;
            overflow-y: auto;
            background-color: var(--bg-dark);
            visibility: hidden;
            z-index: 5;
            box-sizing: border-box;
        }
        .details-panel.active { visibility: visible; }
        
        .details-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-top: 20px;}
        .details-list h4 { color: var(--text-muted); margin-bottom: 12px; border-bottom: 1px solid var(--border); padding-bottom: 8px;}
        .details-list li { padding: 8px; background: var(--bg-panel); margin-bottom: 4px; border-radius: 4px; font-size: 0.875rem; word-break: break-all;}
        
        /* Graph Area */
        #mynetwork { 
            position: absolute; top: 0; left: 0; right: 0; bottom: 0;
            visibility: hidden; 
        }
        #mynetwork.active { visibility: visible; }
        
        .toolbar {
            padding: 12px 24px; background: var(--bg-panel); border-bottom: 1px solid var(--border);
            display: flex; gap: 12px; align-items: center; z-index: 10;
        }
        select, button {
            background: var(--bg-dark); color: var(--text-main);
            border: 1px solid var(--border); padding: 6px 12px; border-radius: 4px; cursor: pointer;
        }
        
    </style>
</head>
<body>

    <div class="sidebar">
        <div class="header">
            <h1>DevLens</h1>
            <div class="score-badge" id="score-badge">Score: --</div>
        </div>
        
        <div class="tabs">
            <div class="tab active" data-target="tab-explorer">Explorer</div>
            <div class="tab" data-target="tab-insights">Insights</div>
        </div>
        
        <div class="tab-content active" id="tab-explorer">
            <ul id="file-tree"></ul>
        </div>
        
        <div class="tab-content" id="tab-insights">
            <div class="insight-card">
                <h4>God Classes</h4>
                <div id="god-classes"></div>
            </div>
            <div class="insight-card">
                <h4>Highly Coupled</h4>
                <div id="highly-coupled"></div>
            </div>
            <div class="insight-card">
                <h4>Circular Dependencies</h4>
                <div id="circular-deps"></div>
            </div>
        </div>
    </div>
    
    <div class="main-area">
        <div class="toolbar">
            <span style="font-size: 0.875rem; color: var(--text-muted);">Graph Module:</span>
            <select id="module-select">
                <option value="top_relevant">Top Relevant Files (Default)</option>
                <option value="all">Entire Project (Slow)</option>
            </select>
            <button id="btn-draw">Draw Graph</button>
            <button id="btn-details" style="margin-left:auto;">Show Details</button>
        </div>
        
        <div class="workspace">
            <div id="mynetwork" class="active"></div>
            
            <div id="details-panel" class="details-panel">
                <h2 id="details-title">Select a file</h2>
                <div class="details-grid">
                    <div class="details-list">
                        <h4>Depends On (Imports)</h4>
                        <ul id="list-imports"></ul>
                    </div>
                    <div class="details-list">
                        <h4>Imported By</h4>
                        <ul id="list-imported-by"></ul>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        const rawData = __GRAPH_DATA__;
        
        // Colors
        const typeColors = {
            'screen': '#3b82f6', 'state': '#a855f7', 'repository': '#f59e0b',
            'model': '#10b981', 'file': '#64748b'
        };

        // UI Setup
        document.getElementById('score-badge').innerText = `Architecture Score: ${rawData.metrics.architecture_score}/100`;
        
        // Populate Insights
        const gcContainer = document.getElementById('god-classes');
        rawData.metrics.god_classes.forEach(gc => {
            gcContainer.innerHTML += `<div class="insight-item"><span>${gc.id.split('/').pop()}</span> <span>${gc.imports}</span></div>`;
        });
        if(rawData.metrics.god_classes.length === 0) gcContainer.innerHTML = '<div class="insight-item">None 🎉</div>';

        const hcContainer = document.getElementById('highly-coupled');
        rawData.metrics.highly_coupled.forEach(hc => {
            hcContainer.innerHTML += `<div class="insight-item"><span>${hc.id.split('/').pop()}</span> <span>${hc.score}</span></div>`;
        });
        if(rawData.metrics.highly_coupled.length === 0) hcContainer.innerHTML = '<div class="insight-item">None 🎉</div>';

        const cdContainer = document.getElementById('circular-deps');
        if(rawData.metrics.circular_dependencies.length > 0) {
            cdContainer.innerHTML = `<div class="insight-item">${rawData.metrics.circular_dependencies.length} cycles detected! Check terminal for details.</div>`;
        } else {
            cdContainer.innerHTML = '<div class="insight-item">None 🎉</div>';
        }

        // Build Tree (Group by module)
        const modules = {};
        rawData.nodes.forEach(n => {
            if(!modules[n.module]) modules[n.module] = [];
            modules[n.module].push(n);
        });

        const tree = document.getElementById('file-tree');
        const modSelect = document.getElementById('module-select');
        
        Object.keys(modules).sort().forEach(mod => {
            // Add to select
            modSelect.innerHTML += `<option value="${mod}">${mod}</option>`;
            
            // Add to tree
            const li = document.createElement('li');
            li.className = 'tree-node';
            li.innerHTML = `
                <div class="tree-node-label" onclick="this.nextElementSibling.classList.toggle('open')">📁 ${mod}</div>
                <ul class="tree-children">
                    ${modules[mod].sort((a,b)=>a.label.localeCompare(b.label)).map(n => `
                        <li class="tree-node">
                            <div class="tree-node-label file-node" data-id="${n.id}">📄 ${n.label}</div>
                        </li>
                    `).join('')}
                </ul>
            `;
            tree.appendChild(li);
        });

        // Tabs Logic
        document.querySelectorAll('.tab').forEach(tab => {
            tab.addEventListener('click', () => {
                document.querySelectorAll('.tab, .tab-content').forEach(e => e.classList.remove('active'));
                tab.classList.add('active');
                document.getElementById(tab.dataset.target).classList.add('active');
            });
        });

        // Graphing Logic
        let network = null;
        
        function drawGraph(moduleId) {
            document.getElementById('mynetwork').classList.add('active');
            document.getElementById('details-panel').classList.remove('active');
            
            let nodesToDraw = rawData.nodes;
            if (moduleId === 'top_relevant') {
                const topNodesSet = new Set(rawData.metrics.top_nodes);
                nodesToDraw = rawData.nodes.filter(n => topNodesSet.has(n.id));
            } else if(moduleId !== 'all') {
                nodesToDraw = rawData.nodes.filter(n => n.module === moduleId);
                // Also include immediate dependencies of this module
                const moduleNodeIds = new Set(nodesToDraw.map(n => n.id));
                const relatedNodeIds = new Set();
                
                rawData.edges.forEach(e => {
                    if (moduleNodeIds.has(e.source) && !moduleNodeIds.has(e.target)) relatedNodeIds.add(e.target);
                    if (moduleNodeIds.has(e.target) && !moduleNodeIds.has(e.source)) relatedNodeIds.add(e.source);
                });
                
                rawData.nodes.forEach(n => {
                    if (relatedNodeIds.has(n.id)) nodesToDraw.push(n);
                });
            }
            
            const nodeIds = new Set(nodesToDraw.map(n => n.id));
            const edgesToDraw = rawData.edges.filter(e => nodeIds.has(e.source) && nodeIds.has(e.target));
            
            const visNodes = nodesToDraw.map(n => ({
                id: n.id, label: n.label,
                color: { background: typeColors[n.type] || typeColors.file, border: '#ffffff' },
                font: { color: '#fff' }
            }));
            
            const visEdges = edgesToDraw.map(e => ({
                from: e.source, to: e.target, arrows: 'to', color: 'rgba(148, 163, 184, 0.4)'
            }));

            const container = document.getElementById('mynetwork');
            const data = { nodes: new vis.DataSet(visNodes), edges: new vis.DataSet(visEdges) };
            const options = {
                nodes: { shape: 'dot', size: 16 },
                physics: { forceAtlas2Based: { gravitationalConstant: -50 } }
            };
            
            if (network) network.destroy();
            network = new vis.Network(container, data, options);
            
            network.on('selectNode', (params) => {
                showDetails(params.nodes[0]);
            });
        }

        document.getElementById('btn-draw').addEventListener('click', () => {
            drawGraph(document.getElementById('module-select').value);
        });
        
        document.getElementById('btn-details').addEventListener('click', () => {
            document.getElementById('mynetwork').classList.remove('active');
            document.getElementById('details-panel').classList.add('active');
        });

        // Details View Logic
        function showDetails(nodeId) {
            document.querySelectorAll('.file-node').forEach(n => n.classList.remove('active'));
            const el = document.querySelector(`.file-node[data-id="${nodeId}"]`);
            if (el) el.classList.add('active');
            
            document.getElementById('mynetwork').classList.remove('active');
            document.getElementById('details-panel').classList.add('active');
            
            const node = rawData.nodes.find(n => n.id === nodeId);
            document.getElementById('details-title').innerText = node.id;
            
            const imports = rawData.edges.filter(e => e.source === nodeId).map(e => e.target);
            const importedBy = rawData.edges.filter(e => e.target === nodeId).map(e => e.source);
            
            document.getElementById('list-imports').innerHTML = imports.map(id => `<li>${id}</li>`).join('') || '<li>None</li>';
            document.getElementById('list-imported-by').innerHTML = importedBy.map(id => `<li>${id}</li>`).join('') || '<li>None</li>';
        }
        
        // Bind tree clicks
        document.querySelectorAll('.file-node').forEach(node => {
            node.addEventListener('click', (e) => {
                e.stopPropagation();
                showDetails(node.dataset.id);
            });
        });
        
        // Initial draw (relevance filter by default)
        modSelect.value = 'top_relevant';
        drawGraph(modSelect.value);

    </script>
</body>
</html>
''';
}
