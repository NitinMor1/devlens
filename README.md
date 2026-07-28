# 🔍 DevLens

![Pub Version](https://img.shields.io/pub/v/devlens?color=blue&style=for-the-badge)
![License](https://img.shields.io/github/license/my_org/devlens?style=for-the-badge)

**Flutter Dependency Explorer.** A developer tool to analyze any Flutter or Dart project and generate an interactive architecture and dependency visualization map.

---

## ✨ Features
- 🚀 **Offline HTML Dashboard**: Generates a stunning 6-tab Onboarding Dashboard (Learning Path, Risk Report, Folder Map, Dead Code, Graph).
- 🧠 **AST Code Analysis**: Uses the official `analyzer` package to statically parse Dart files, extracting imports and file types.
- 🏗️ **Architecture Health Score**: Detects Circular Dependencies, God Classes, and Highly Coupled files to grade your codebase.
- 🗺️ **Learning Path**: Automatically calculates the optimal reading order for a new developer to understand the project in 10 minutes.
- 💀 **Dead Code Detection**: Highlights orphaned files that have zero incoming dependencies.

---

## 🚀 Getting Started

### Installation

Activate the CLI globally via pub:

```bash
dart pub global activate devlens
```

### Usage

Run the scanner in the root of any Flutter or Dart project:

```bash
devlens scan
```

You can also specify a specific path:

```bash
devlens scan --path /path/to/your/flutter_project
```

---

## 🗺️ How it Works & Where Everything Goes

When you run `devlens scan`, here is what happens under the hood and where the outputs are generated:

<details>
<summary><b>1. Parsing Phase</b> <i>[Click to expand]</i></summary>
<br>
The <code>DartParser</code> scans through your project's <code>lib/</code> directory, reading every <code>.dart</code> file. It extracts dependencies and identifies the type of each component (e.g., is it a State, Screen, or Repository?).
</details>

<details>
<summary><b>2. Graph Generation</b> <i>[Click to expand]</i></summary>
<br>
The parsed files are converted into a connected <code>DependencyGraph</code>. This engine models the nodes (files) and edges (imports) of your architecture.
</details>

<details>
<summary><b>3. Output (<code>.dep_explorer/</code>)</b> <i>[Click to expand]</i></summary>
<br>
Once the scan is complete, DevLens creates a new directory in your project root called <b><code>.dep_explorer/</code></b>. <br>
Inside this folder, it generates an <code>index.html</code> file which automatically opens in your browser. This contains the full 6-tab Onboarding Dashboard!
</details>

---

## 📁 Source Code Architecture

Curious about how DevLens itself is built? Here's a quick overview of our source code:

- 📂 **`bin/`**: Contains the executable entrypoint (`devlens.dart`).
- 📂 **`lib/cli/`**: The command-line interface logic and command runner.
- 📂 **`lib/packages/parser/`**: The Dart analyzer code that reads your files.
- 📂 **`lib/packages/graph_engine/`**: Data structures for the dependency graph.
- 📂 **`lib/packages/reports/`**: Exporters that write the `.dep_explorer/` outputs.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/my_org/devlens/issues).
