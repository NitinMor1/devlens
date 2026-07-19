# 🔍 DevLens

![Pub Version](https://img.shields.io/pub/v/devlens?color=blue&style=for-the-badge)
![License](https://img.shields.io/github/license/my_org/devlens?style=for-the-badge)

**Flutter Dependency Explorer.** A developer tool to analyze any Flutter or Dart project and generate an interactive architecture and dependency visualization map.

---

## ✨ Features
- 🚀 **Fast Parsing**: Scans your entire `lib/` directory in milliseconds.
- 📦 **Dependency Mapping**: Accurately maps both `package:` and relative imports.
- 🏗️ **Architecture Analysis**: Categorizes files by types like `Screen`, `Bloc`, `Repository`, and `Model`.
- 📊 **JSON Export**: Generates a standard JSON graph model that can be consumed by visualizers.

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
Inside this folder, it generates a <code>graph.json</code> file (and other reports) containing the full dependency tree, which can be loaded into visualization tools!
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
