## 1.2.0

- ✨ **Major Architecture Overhaul**: Replaced the single-view graph with a complete 6-Tab Onboarding Dashboard.
- 🗺️ **Learning Path**: Added an intelligent learning path report to guide developers through the most important files.
- ⚠️ **Risk Report**: Added scoring for Circular Dependencies, God Classes, and Highly Coupled files.
- 🗂️ **Folder Map**: Grouped metrics by folder boundaries instead of naive top-level modules.
- 💀 **Dead Code Detection**: Added a report that flags files with zero incoming edges.
- 🚀 **UI Redesign**: Complete rewrite of the HTML exporter to provide a modern, responsive, tabbed UI that works completely offline.

## 1.1.0

- ✨ **New Feature**: Added a stunning interactive frontend visualizer using `vis-network` (Dark mode & Glassmorphic UI).
- 🚀 **Auto-Launch**: Automatically opens the generated interactive map in the default system browser upon scan completion.
- 🐛 **Bug Fix**: Fixed a bug on Windows where file paths were mapped incorrectly resulting in disconnected graphs.
- 🧹 **Refactor**: Filtered external dependencies out of the graph (e.g. `dart:io`, `package:flutter`) to ensure clean, internal-only architecture maps.

## 1.0.2

- Add missing example, fix github URLs in pubspec, and add public API documentation to improve pub points.

## 1.0.1

- Add comprehensive README and MIT LICENSE.

## 1.0.0

- Initial version.
