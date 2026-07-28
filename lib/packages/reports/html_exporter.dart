import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class HtmlExporter {
  static Future<void> export(Map<String, dynamic> graphData, String outputDir) async {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final graphJson = jsonEncode(graphData);
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
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --bg: #0f1117;
            --surface: #1a1d27;
            --surface2: #22263a;
            --border: rgba(255,255,255,0.07);
            --accent: #38bdf8;
            --accent2: #818cf8;
            --success: #34d399;
            --warning: #fbbf24;
            --danger: #f87171;
            --text: #e2e8f0;
            --text-muted: #64748b;
        }
        body { font-family: 'Inter', sans-serif; background: var(--bg); color: var(--text); height: 100vh; display: flex; flex-direction: column; overflow: hidden; }

        /* ── TOP NAV ── */
        .topnav {
            display: flex; align-items: center; gap: 0;
            background: var(--surface); border-bottom: 1px solid var(--border);
            padding: 0 24px; height: 56px; flex-shrink: 0;
        }
        .brand { font-weight: 700; font-size: 1.1rem; color: var(--accent); margin-right: 32px; letter-spacing: -0.5px; }
        .score-badge {
            font-size: 0.75rem; font-weight: 600; padding: 3px 10px; border-radius: 20px;
            margin-right: 24px;
        }
        .score-badge.good { background: rgba(52,211,153,0.15); color: var(--success); }
        .score-badge.warn { background: rgba(251,191,36,0.15); color: var(--warning); }
        .score-badge.bad  { background: rgba(248,113,113,0.15); color: var(--danger); }
        .tabs { display: flex; gap: 2px; flex: 1; }
        .tab {
            padding: 0 20px; height: 56px; display: flex; align-items: center; gap: 8px;
            cursor: pointer; font-size: 0.875rem; font-weight: 500; color: var(--text-muted);
            border-bottom: 2px solid transparent; transition: all 0.15s; white-space: nowrap;
        }
        .tab:hover { color: var(--text); }
        .tab.active { color: var(--accent); border-bottom-color: var(--accent); }
        .tab .badge {
            font-size: 0.7rem; padding: 1px 6px; border-radius: 10px;
            background: rgba(248,113,113,0.2); color: var(--danger); font-weight: 600;
        }
        .tab .badge.neutral { background: rgba(100,116,139,0.2); color: var(--text-muted); }

        /* ── MAIN CONTENT ── */
        .content { flex: 1; overflow-y: auto; padding: 28px 32px; }

        /* ── OVERVIEW ── */
        .overview-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 24px; }
        .card {
            background: var(--surface); border: 1px solid var(--border);
            border-radius: 12px; padding: 20px;
        }
        .card h3 { font-size: 0.75rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); margin-bottom: 16px; }
        .stat-row { display: flex; justify-content: space-between; align-items: center; padding: 8px 0; border-bottom: 1px solid var(--border); font-size: 0.875rem; }
        .stat-row:last-child { border-bottom: none; }
        .stat-value { font-weight: 600; }
        .stat-value.good { color: var(--success); }
        .stat-value.warn { color: var(--warning); }
        .stat-value.bad  { color: var(--danger); }
        .health-bar-wrap { margin-top: 8px; }
        .health-bar-label { display: flex; justify-content: space-between; font-size: 0.8rem; margin-bottom: 6px; color: var(--text-muted); }
        .health-bar { height: 8px; border-radius: 4px; background: var(--surface2); overflow: hidden; }
        .health-bar-fill { height: 100%; border-radius: 4px; transition: width 0.6s ease; }
        .arch-badge {
            display: inline-block; padding: 4px 12px; border-radius: 6px; font-size: 0.8rem; font-weight: 600;
            background: rgba(56,189,248,0.1); color: var(--accent); border: 1px solid rgba(56,189,248,0.2);
            margin-bottom: 8px;
        }
        .tech-pill {
            display: inline-block; padding: 3px 10px; border-radius: 20px; font-size: 0.75rem;
            background: var(--surface2); color: var(--text-muted); margin: 3px;
        }

        /* ── LEARNING PATH ── */
        .lp-container { max-width: 700px; }
        .lp-step {
            display: flex; gap: 16px; align-items: flex-start;
            background: var(--surface); border: 1px solid var(--border);
            border-radius: 12px; padding: 16px 20px; margin-bottom: 12px;
            transition: border-color 0.15s; cursor: default;
        }
        .lp-step:hover { border-color: var(--accent); }
        .lp-num {
            width: 32px; height: 32px; border-radius: 50%; background: rgba(56,189,248,0.15);
            color: var(--accent); font-weight: 700; font-size: 0.875rem;
            display: flex; align-items: center; justify-content: center; flex-shrink: 0;
        }
        .lp-info h4 { font-size: 0.9rem; font-weight: 600; margin-bottom: 4px; }
        .lp-info p { font-size: 0.8rem; color: var(--text-muted); }
        .lp-connector { width: 2px; height: 16px; background: var(--border); margin-left: 30px; }

        /* ── RISK REPORT ── */
        .risk-table { width: 100%; border-collapse: collapse; }
        .risk-table th { text-align: left; font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); padding: 8px 12px; border-bottom: 1px solid var(--border); }
        .risk-table td { padding: 10px 12px; border-bottom: 1px solid var(--border); font-size: 0.875rem; }
        .risk-table tr:hover td { background: rgba(255,255,255,0.02); }
        .risk-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; margin-right: 8px; }
        .risk-dot.high   { background: var(--danger); }
        .risk-dot.medium { background: var(--warning); }
        .risk-dot.low    { background: var(--success); }
        .risk-bar { height: 4px; border-radius: 2px; background: var(--surface2); margin-top: 4px; }
        .risk-bar-fill { height: 100%; border-radius: 2px; }
        .tag { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.7rem; font-weight: 600; }
        .tag.screen { background: rgba(56,189,248,0.15); color: #7dd3fc; }
        .tag.model { background: rgba(167,139,250,0.15); color: #c4b5fd; }
        .tag.state { background: rgba(251,191,36,0.15); color: #fde68a; }
        .tag.repository { background: rgba(52,211,153,0.15); color: #6ee7b7; }
        .tag.file { background: rgba(100,116,139,0.15); color: #94a3b8; }

        /* ── FOLDER MAP ── */
        .folder-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 12px; }
        .folder-card {
            background: var(--surface); border: 1px solid var(--border); border-radius: 12px;
            padding: 16px; transition: border-color 0.15s; cursor: pointer;
        }
        .folder-card:hover { border-color: var(--accent2); }
        .folder-card h4 { font-size: 0.875rem; font-weight: 600; margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
        .folder-card .folder-desc { font-size: 0.78rem; color: var(--text-muted); margin-bottom: 12px; }
        .folder-pills { display: flex; flex-wrap: wrap; gap: 6px; }
        .folder-pill { font-size: 0.7rem; padding: 2px 8px; border-radius: 4px; font-weight: 500; }
        .folder-pill.screens { background: rgba(56,189,248,0.1); color: #7dd3fc; }
        .folder-pill.models  { background: rgba(167,139,250,0.1); color: #c4b5fd; }
        .folder-pill.state   { background: rgba(251,191,36,0.1); color: #fde68a; }
        .folder-pill.repo    { background: rgba(52,211,153,0.1); color: #6ee7b7; }
        .folder-pill.files   { background: rgba(100,116,139,0.1); color: #94a3b8; }
        .folder-pill.total   { background: rgba(255,255,255,0.05); color: var(--text-muted); }

        /* ── DEAD CODE ── */
        .dead-list { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 8px; }
        .dead-item {
            background: var(--surface); border: 1px solid var(--border); border-radius: 8px;
            padding: 12px 16px; font-size: 0.85rem; display: flex; align-items: center; gap: 10px;
        }
        .dead-item .skull { font-size: 1rem; }
        .dead-item .name { font-weight: 500; flex: 1; word-break: break-all; }
        .empty-state { text-align: center; padding: 60px; color: var(--text-muted); }
        .empty-state .emoji { font-size: 3rem; margin-bottom: 16px; }
        .empty-state p { font-size: 0.9rem; }

        /* ── GRAPH ── */
        .graph-toolbar {
            display: flex; align-items: center; gap: 12px;
            background: var(--surface); border: 1px solid var(--border);
            border-radius: 10px; padding: 10px 16px; margin-bottom: 16px;
        }
        .graph-toolbar select, .graph-toolbar button {
            background: var(--surface2); border: 1px solid var(--border);
            color: var(--text); padding: 6px 12px; border-radius: 6px;
            font-size: 0.8rem; cursor: pointer; font-family: inherit;
        }
        .graph-toolbar button:hover { background: var(--accent); color: #000; }
        .graph-toolbar label { display: flex; align-items: center; gap: 6px; font-size: 0.8rem; color: var(--text-muted); cursor: pointer; }
        #mynetwork { width: 100%; height: calc(100vh - 200px); border-radius: 10px; border: 1px solid var(--border); background: var(--surface); }

        /* ── PANELS COMMON ── */
        .panel { display: none; }
        .panel.active { display: block; }
        .section-title { font-size: 1.1rem; font-weight: 700; margin-bottom: 6px; }
        .section-sub { font-size: 0.85rem; color: var(--text-muted); margin-bottom: 24px; }

        /* ── DETAILS PANEL ── */
        .details-overlay {
            display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.6);
            z-index: 100; align-items: center; justify-content: center;
        }
        .details-overlay.active { display: flex; }
        .details-box {
            background: var(--surface); border: 1px solid var(--border); border-radius: 16px;
            padding: 28px; width: 560px; max-height: 80vh; overflow-y: auto;
        }
        .details-box h2 { font-size: 0.9rem; color: var(--accent); word-break: break-all; margin-bottom: 20px; }
        .details-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .details-list h4 { font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); margin-bottom: 8px; }
        .details-list li { font-size: 0.8rem; padding: 4px 0; border-bottom: 1px solid var(--border); word-break: break-all; }
        .btn-close { float: right; background: var(--surface2); border: 1px solid var(--border); color: var(--text); padding: 4px 12px; border-radius: 6px; cursor: pointer; font-size: 0.8rem; }
        .btn-impact { margin-top: 16px; padding: 8px 16px; border: none; border-radius: 6px; background: #ef4444; color: white; cursor: pointer; font-weight: 600; font-size: 0.85rem; }
    </style>
</head>
<body>

<div class="topnav">
    <div class="brand">DevLens</div>
    <div id="score-badge" class="score-badge">Score: —</div>
    <div class="tabs">
        <div class="tab active" data-tab="overview">📋 Overview</div>
        <div class="tab" data-tab="learning">🗺️ Learning Path</div>
        <div class="tab" data-tab="risk">⚠️ Risk Report <span id="badge-risk" class="badge">0</span></div>
        <div class="tab" data-tab="folders">🗂️ Folder Map</div>
        <div class="tab" data-tab="dead">💀 Dead Code <span id="badge-dead" class="badge neutral">0</span></div>
        <div class="tab" data-tab="graph">🔗 Graph</div>
    </div>
</div>

<!-- ── OVERVIEW ── -->
<div id="panel-overview" class="content panel active">
    <div class="section-title">Project Overview</div>
    <div class="section-sub">A high-level summary of your codebase architecture, tech stack, and health.</div>
    <div class="overview-grid">
        <div class="card">
            <h3>Architecture</h3>
            <div id="arch-content"></div>
        </div>
        <div class="card">
            <h3>File Statistics</h3>
            <div id="stats-content"></div>
        </div>
        <div class="card">
            <h3>Health Score</h3>
            <div id="health-content"></div>
        </div>
        <div class="card">
            <h3>Tech Stack</h3>
            <div id="tech-content"></div>
        </div>
    </div>
</div>

<!-- ── LEARNING PATH ── -->
<div id="panel-learning" class="content panel">
    <div class="section-title">Learning Path</div>
    <div class="section-sub">Read these files in order to understand 80% of this codebase in under 10 minutes.</div>
    <div class="lp-container" id="lp-content"></div>
</div>

<!-- ── RISK REPORT ── -->
<div id="panel-risk" class="content panel">
    <div class="section-title">Risk Report</div>
    <div class="section-sub">Files with the most incoming dependencies. Changing these will have the widest impact on the codebase.</div>
    <table class="risk-table">
        <thead>
            <tr>
                <th>Risk</th>
                <th>File</th>
                <th>Type</th>
                <th>Connections</th>
                <th>Impact</th>
            </tr>
        </thead>
        <tbody id="risk-tbody"></tbody>
    </table>
</div>

<!-- ── FOLDER MAP ── -->
<div id="panel-folders" class="content panel">
    <div class="section-title">Folder Map</div>
    <div class="section-sub">Your project's folder structure and what each folder contains. Click a folder to explore it in the Graph tab.</div>
    <div class="folder-grid" id="folder-grid"></div>
</div>

<!-- ── DEAD CODE ── -->
<div id="panel-dead" class="content panel">
    <div class="section-title">Dead Code</div>
    <div class="section-sub">Files with zero incoming dependencies — nothing imports them. They may be unused and safe to delete (always verify before deleting).</div>
    <div class="dead-list" id="dead-list"></div>
</div>

<!-- ── GRAPH ── -->
<div id="panel-graph" class="content panel">
    <div class="graph-toolbar">
        <span style="font-size:0.8rem;color:var(--text-muted);">Folder:</span>
        <select id="module-select">
            <option value="top_relevant">Top Relevant Files</option>
            <option value="all">Entire Project</option>
        </select>
        <label>
            <input type="checkbox" id="hide-hubs" checked> Hide Hub Files
        </label>
        <button id="btn-draw">Draw Graph</button>
        <span style="font-size:0.75rem;color:var(--text-muted);margin-left:auto;">Click any node for details</span>
    </div>
    <div id="mynetwork"></div>
</div>

<!-- ── DETAILS OVERLAY ── -->
<div class="details-overlay" id="details-overlay">
    <div class="details-box">
        <button class="btn-close" onclick="document.getElementById('details-overlay').classList.remove('active')">✕ Close</button>
        <h2 id="details-title">Select a file</h2>
        <div class="details-grid">
            <div class="details-list">
                <h4>Imports (Depends On)</h4>
                <ul id="list-imports"></ul>
            </div>
            <div class="details-list">
                <h4>Imported By</h4>
                <ul id="list-imported-by"></ul>
            </div>
        </div>
        <div style="margin-top:16px;padding-top:16px;border-top:1px solid var(--border);">
            <p style="font-size:0.85rem;color:var(--text-muted);">If you change this file, <strong id="impact-count" style="color:#f87171;">0</strong> files could be affected.</p>
            <button class="btn-impact" id="btn-isolate-impact">Isolate Impact Radius in Graph</button>
        </div>
    </div>
</div>

<script>
    const rawData = __GRAPH_DATA__;
    const metrics = rawData.metrics;
    const sum = metrics.project_summary || {};

    // ── TAB SWITCHING ──────────────────────────────────────
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
            tab.classList.add('active');
            document.getElementById('panel-' + tab.dataset.tab).classList.add('active');
            // Auto-draw graph when switching to graph tab
            if (tab.dataset.tab === 'graph' && !network) drawGraph('top_relevant');
        });
    });

    // ── SCORE BADGE ───────────────────────────────────────
    const score = metrics.architecture_score || 0;
    const badge = document.getElementById('score-badge');
    badge.textContent = 'Score: ' + score + '/100';
    badge.className = 'score-badge ' + (score >= 70 ? 'good' : score >= 40 ? 'warn' : 'bad');

    // ── BADGE COUNTS ──────────────────────────────────────
    const godCount = (metrics.god_classes || []).length;
    const coupled = (metrics.highly_coupled || []).length;
    document.getElementById('badge-risk').textContent = godCount + coupled;
    const deadCount = (metrics.dead_code || []).length;
    document.getElementById('badge-dead').textContent = deadCount;

    // ── OVERVIEW: ARCHITECTURE ────────────────────────────
    const archEl = document.getElementById('arch-content');
    const archPattern = sum.architecture || 'Unknown Pattern';
    const routing = sum.routing || 'Native Navigator';
    const stateMgmt = (sum.state_management || []).join(', ') || '—';
    archEl.innerHTML = `
        <div class="arch-badge">${archPattern}</div>
        <div class="stat-row"><span>Architecture</span><span class="stat-value">${archPattern}</span></div>
        <div class="stat-row"><span>Routing</span><span class="stat-value">${routing}</span></div>
        <div class="stat-row"><span>State Mgmt</span><span class="stat-value">${stateMgmt}</span></div>
    `;

    // ── OVERVIEW: STATS ───────────────────────────────────
    document.getElementById('stats-content').innerHTML = `
        <div class="stat-row"><span>Total Files</span><span class="stat-value">${metrics.total_nodes}</span></div>
        <div class="stat-row"><span>Screens</span><span class="stat-value" style="color:var(--accent)">${metrics.total_screens}</span></div>
        <div class="stat-row"><span>Models</span><span class="stat-value" style="color:#c4b5fd">${metrics.total_models}</span></div>
        <div class="stat-row"><span>Repositories</span><span class="stat-value" style="color:#6ee7b7">${metrics.total_repositories}</span></div>
        <div class="stat-row"><span>Services</span><span class="stat-value">${metrics.total_services}</span></div>
        <div class="stat-row"><span>Total Connections</span><span class="stat-value">${metrics.total_edges}</span></div>
    `;

    // ── OVERVIEW: HEALTH ──────────────────────────────────
    const circ = (metrics.circular_dependencies || []).length;
    const healthEl = document.getElementById('health-content');
    const fillColor = score >= 70 ? '#34d399' : score >= 40 ? '#fbbf24' : '#f87171';
    healthEl.innerHTML = `
        <div class="health-bar-wrap">
            <div class="health-bar-label"><span>Architecture Score</span><span>${score}/100</span></div>
            <div class="health-bar"><div class="health-bar-fill" style="width:${score}%;background:${fillColor};"></div></div>
        </div>
        <div style="margin-top:16px;">
            <div class="stat-row"><span>Circular Dependencies</span><span class="stat-value ${circ > 0 ? 'bad' : 'good'}">${circ} ${circ > 0 ? '⚠️' : '✅'}</span></div>
            <div class="stat-row"><span>Highly Coupled Files</span><span class="stat-value ${coupled > 0 ? 'warn' : 'good'}">${coupled} ${coupled > 0 ? '⚠️' : '✅'}</span></div>
            <div class="stat-row"><span>God Classes</span><span class="stat-value ${godCount > 0 ? 'bad' : 'good'}">${godCount} ${godCount > 0 ? '⚠️' : '✅'}</span></div>
            <div class="stat-row"><span>Dead Code</span><span class="stat-value ${deadCount > 0 ? 'warn' : 'good'}">${deadCount} files</span></div>
        </div>
    `;

    // ── OVERVIEW: TECH STACK ──────────────────────────────
    const techEl = document.getElementById('tech-content');
    const pkgs = (sum.core_packages || []).concat(sum.state_management || []).concat(sum.routing ? [sum.routing] : []);
    techEl.innerHTML = pkgs.length
        ? pkgs.map(p => `<span class="tech-pill">${p}</span>`).join('')
        : '<span style="color:var(--text-muted);font-size:0.85rem;">No packages detected</span>';

    // ── LEARNING PATH ─────────────────────────────────────
    const lpEl = document.getElementById('lp-content');
    const lpFiles = (sum.learning_path || []);
    const lpDescriptions = {
        'main.dart': 'Entry point — app bootstrap, providers, and initial configuration',
        'app.dart': 'Root widget — MaterialApp, theme, and global setup',
        'router': 'Navigation hub — all routes and screen transitions',
        'route': 'Navigation hub — all routes and screen transitions',
        'screen': 'UI screen — the visual layer for this feature',
        'page': 'UI page — the visual layer for this feature',
        'provider': 'State management — manages and exposes data to the UI',
        'bloc': 'Business logic — handles events and emits states',
        'cubit': 'Business logic — simplified state management',
        'repository': 'Data layer — fetches and caches data from APIs',
        'service': 'Service layer — handles specific business operations',
        'model': 'Data model — structure of the data in this domain',
    };
    function getDesc(filename) {
        const lower = filename.toLowerCase();
        for (const [key, desc] of Object.entries(lpDescriptions)) {
            if (lower.includes(key)) return desc;
        }
        return 'Core file — important for understanding the project';
    }
    if (lpFiles.length === 0) {
        lpEl.innerHTML = '<p style="color:var(--text-muted)">Learning path could not be generated. Ensure main.dart exists.</p>';
    } else {
        lpEl.innerHTML = lpFiles.map((file, i) => {
            const name = file.split('/').pop();
            return `
                ${i > 0 ? '<div class="lp-connector"></div>' : ''}
                <div class="lp-step">
                    <div class="lp-num">${i + 1}</div>
                    <div class="lp-info">
                        <h4>${name}</h4>
                        <p>${getDesc(name)}</p>
                        <p style="margin-top:4px;font-size:0.75rem;color:#475569;">${file}</p>
                    </div>
                </div>
            `;
        }).join('');
    }

    // ── RISK REPORT ───────────────────────────────────────
    const riskTbody = document.getElementById('risk-tbody');
    const allRanked = (metrics.all_nodes_ranked || []);
    const maxScore = allRanked.length > 0 ? allRanked[0].score : 1;
    const impactMap = metrics.impact_radius || {};
    allRanked.slice(0, 30).forEach((n, i) => {
        const name = n.id.split('/').pop();
        const nodeData = rawData.nodes.find(nd => nd.id === n.id);
        const type = nodeData ? nodeData.type : 'file';
        const impactCount = (impactMap[n.id] || []).length;
        const pct = Math.round((n.score / maxScore) * 100);
        const riskLevel = pct > 66 ? 'high' : pct > 33 ? 'medium' : 'low';
        const riskLabel = pct > 66 ? '🔴 High' : pct > 33 ? '🟠 Medium' : '🟢 Low';
        riskTbody.innerHTML += `
            <tr style="cursor:pointer;" onclick="openDetails('${n.id}')">
                <td>${riskLabel}</td>
                <td><strong>${name}</strong><div style="font-size:0.75rem;color:var(--text-muted);word-break:break-all;">${n.id}</div></td>
                <td><span class="tag ${type}">${type}</span></td>
                <td>
                    <strong>${n.score}</strong>
                    <div class="risk-bar"><div class="risk-bar-fill" style="width:${pct}%;background:${riskLevel==='high'?'#f87171':riskLevel==='medium'?'#fbbf24':'#34d399'};"></div></div>
                </td>
                <td style="color:var(--text-muted);">${impactCount} files</td>
            </tr>
        `;
    });

    // ── FOLDER MAP ────────────────────────────────────────
    const folderGrid = document.getElementById('folder-grid');
    const folderMap = metrics.folder_map || [];
    function folderDesc(f) {
        if (f.screens > 0 && f.screens >= f.files) return '🖥️ UI Screens — presentation layer';
        if (f.models > 0 && f.models >= f.files) return '📦 Data Models — domain entities';
        if (f.state > 0 && f.state >= f.files) return '⚡ State Management — app logic';
        if (f.repository > 0 && f.repository >= f.files) return '🗄️ Data Layer — API & storage';
        if (f.screens > 0 || f.models > 0) return '📂 Mixed — multiple concerns';
        return '🔧 Utilities & Helpers';
    }
    folderMap.forEach(f => {
        const pills = [
            f.screens > 0 ? `<span class="folder-pill screens">${f.screens} screens</span>` : '',
            f.models > 0  ? `<span class="folder-pill models">${f.models} models</span>` : '',
            f.state > 0   ? `<span class="folder-pill state">${f.state} state</span>` : '',
            f.repository > 0 ? `<span class="folder-pill repo">${f.repository} repo</span>` : '',
            f.files > 0   ? `<span class="folder-pill files">${f.files} utils</span>` : '',
            `<span class="folder-pill total">${f.count} total</span>`
        ].filter(Boolean).join('');
        const card = document.createElement('div');
        card.className = 'folder-card';
        card.innerHTML = `
            <h4>📁 ${f.module}</h4>
            <div class="folder-desc">${folderDesc(f)}</div>
            <div class="folder-pills">${pills}</div>
        `;
        card.onclick = () => {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
            document.querySelector('[data-tab="graph"]').classList.add('active');
            document.getElementById('panel-graph').classList.add('active');
            document.getElementById('module-select').value = f.module;
            drawGraph(f.module);
        };
        folderGrid.appendChild(card);
    });

    // ── DEAD CODE ─────────────────────────────────────────
    const deadList = document.getElementById('dead-list');
    const deadCode = metrics.dead_code || [];
    if (deadCode.length === 0) {
        deadList.innerHTML = '<div class="empty-state"><div class="emoji">✅</div><p>No dead code detected! Every file is imported by at least one other file.</p></div>';
    } else {
        deadCode.forEach(n => {
            deadList.innerHTML += `
                <div class="dead-item">
                    <span class="skull">💀</span>
                    <span class="name">${n.label}</span>
                    <span class="tag ${n.type}">${n.type}</span>
                </div>
            `;
        });
    }

    // ── GRAPH ─────────────────────────────────────────────
    let network = null;
    const HUB_THRESHOLD = 30;
    const typeColors = { screen: '#38bdf8', model: '#818cf8', state: '#fbbf24', repository: '#34d399', service: '#f97316', file: '#64748b' };

    const connectionCount = {};
    rawData.edges.forEach(e => {
        connectionCount[e.source] = (connectionCount[e.source] || 0) + 1;
        connectionCount[e.target] = (connectionCount[e.target] || 0) + 1;
    });

    // Populate module dropdown from folder map
    (metrics.folder_map || []).forEach(f => {
        document.getElementById('module-select').innerHTML += `<option value="${f.module}">${f.module} (${f.count} files)</option>`;
    });

    document.getElementById('btn-draw').addEventListener('click', () => {
        drawGraph(document.getElementById('module-select').value);
    });

    function drawGraph(moduleId) {
        let nodesToDraw = rawData.nodes;
        let impactMode = false, impactNodeId = null;
        const hideHubs = document.getElementById('hide-hubs').checked;

        if (moduleId.startsWith('impact_')) {
            impactMode = true;
            impactNodeId = moduleId.replace('impact_', '');
            const impacted = new Set([impactNodeId, ...(impactMap[impactNodeId] || [])]);
            nodesToDraw = rawData.nodes.filter(n => impacted.has(n.id));
        } else if (moduleId === 'top_relevant') {
            const topSet = new Set(metrics.top_nodes || []);
            nodesToDraw = rawData.nodes.filter(n => topSet.has(n.id));
        } else if (moduleId === 'all') {
            nodesToDraw = rawData.nodes;
        } else {
            nodesToDraw = rawData.nodes.filter(n => n.module === moduleId);
            const modIds = new Set(nodesToDraw.map(n => n.id));
            const related = new Set();
            rawData.edges.forEach(e => {
                if (modIds.has(e.source) && !modIds.has(e.target)) related.add(e.target);
                if (modIds.has(e.target) && !modIds.has(e.source)) related.add(e.source);
            });
            rawData.nodes.forEach(n => { if (related.has(n.id)) nodesToDraw.push(n); });
        }

        if (hideHubs && !impactMode) {
            nodesToDraw = nodesToDraw.filter(n => (connectionCount[n.id] || 0) <= HUB_THRESHOLD);
        }

        const nodeIds = new Set(nodesToDraw.map(n => n.id));
        const edgesToDraw = rawData.edges.filter(e => nodeIds.has(e.source) && nodeIds.has(e.target));

        const visNodes = nodesToDraw.map(n => ({
            id: n.id, label: n.label,
            color: {
                background: impactMode ? (n.id === impactNodeId ? '#ef4444' : '#fca5a5') : (typeColors[n.type] || typeColors.file),
                border: '#ffffff',
                highlight: { background: '#38bdf8', border: '#fff' }
            },
            font: { color: '#fff', size: 12 }
        }));
        const visEdges = edgesToDraw.map(e => ({
            from: e.source, to: e.target, arrows: 'to',
            color: impactMode ? 'rgba(239,68,68,0.5)' : 'rgba(148,163,184,0.3)'
        }));

        const isFolderView = !impactMode && moduleId !== 'top_relevant' && moduleId !== 'all';
        const options = isFolderView ? {
            nodes: { shape: 'box', margin: 10, font: { size: 13, color: '#fff' }, borderWidth: 2, shadow: true },
            edges: { smooth: { type: 'cubicBezier', forceDirection: 'vertical', roundness: 0.4 }, arrows: { to: { scaleFactor: 0.7 } } },
            layout: { hierarchical: { enabled: true, direction: 'UD', sortMethod: 'directed', levelSeparation: 140, nodeSpacing: 180 } },
            physics: false, interaction: { hover: true }
        } : {
            nodes: { shape: 'box', margin: 8, font: { size: 12, color: '#fff' }, borderWidth: 2 },
            edges: { smooth: { type: 'continuous' } },
            physics: { solver: 'forceAtlas2Based', forceAtlas2Based: { gravitationalConstant: -200, centralGravity: 0.005, springLength: 220, springConstant: 0.04, damping: 0.4, avoidOverlap: 1.0 }, stabilization: { iterations: 300 } },
            interaction: { hover: true }
        };

        const container = document.getElementById('mynetwork');
        if (network) network.destroy();
        network = new vis.Network(container, { nodes: new vis.DataSet(visNodes), edges: new vis.DataSet(visEdges) }, options);
        network.on('selectNode', params => openDetails(params.nodes[0]));
    }

    // ── DETAILS ───────────────────────────────────────────
    function openDetails(nodeId) {
        const node = rawData.nodes.find(n => n.id === nodeId);
        if (!node) return;
        document.getElementById('details-title').textContent = node.id;
        const imports = rawData.edges.filter(e => e.source === nodeId).map(e => e.target);
        const importedBy = rawData.edges.filter(e => e.target === nodeId).map(e => e.source);
        document.getElementById('list-imports').innerHTML = imports.map(id => `<li>${id.split('/').pop()}</li>`).join('') || '<li style="color:var(--text-muted)">None</li>';
        document.getElementById('list-imported-by').innerHTML = importedBy.map(id => `<li>${id.split('/').pop()}</li>`).join('') || '<li style="color:var(--text-muted)">None</li>';
        document.getElementById('impact-count').textContent = (impactMap[nodeId] || []).length;
        document.getElementById('btn-isolate-impact').onclick = () => {
            document.getElementById('details-overlay').classList.remove('active');
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
            document.querySelector('[data-tab="graph"]').classList.add('active');
            document.getElementById('panel-graph').classList.add('active');
            drawGraph('impact_' + nodeId);
        };
        document.getElementById('details-overlay').classList.add('active');
    }

    // Close overlay on backdrop click
    document.getElementById('details-overlay').addEventListener('click', function(e) {
        if (e.target === this) this.classList.remove('active');
    });
</script>
</body>
</html>
''';
}
