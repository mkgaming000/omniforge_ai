// Workspace Service - manages project workspaces, templates, file operations
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/workspace_entity.dart';

class WorkspaceService {
  /// Create a new workspace from a template.
  Future<Either<Failure, WorkspaceEntity>> createFromTemplate({
    required String name,
    required WorkspaceType type,
    String? description,
    String? basePath,
  }) async {
    try {
      final template = _templates[type];
      if (template == null) {
        return const Left(
          ValidationFailure(
            message: 'Unknown workspace template',
          ),
        );
      }
      final base = basePath ??
          p.join((await getApplicationDocumentsDirectory()).path, 'workspaces');
      final path = p.join(base, name);
      // Create the workspace directory + write all template files.
      final dir = Directory(path);
      await dir.create(recursive: true);
      for (final entry in template.files.entries) {
        final filePath = p.join(path, entry.key);
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }
      final workspace = WorkspaceEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        path: path,
        createdAt: DateTime.now(),
        description: description,
        type: type,
        language: template.language,
        framework: template.framework,
      );
      return Right(workspace);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to create workspace',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// List available templates.
  List<WorkspaceTemplate> get templates => _templates.values.toList();

  /// Open an existing workspace by path. Verifies the directory exists
  /// and returns a [WorkspaceEntity] populated with its metadata.
  Future<Either<Failure, WorkspaceEntity>> open(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        return const Left(
          NotFoundFailure(
            message: 'Workspace directory does not exist',
          ),
        );
      }
      final stat = await dir.stat();
      return Right(
        WorkspaceEntity(
          id: '',
          name: p.basename(path),
          path: path,
          createdAt: stat.changed,
          lastOpenedAt: DateTime.now(),
        ),
      );
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to open workspace',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Clone a Git repository as a workspace.
  ///
  /// Spawns `git clone` via [Process]. Requires git to be on PATH
  /// (standard on Termux/Linux/macOS dev environments).
  Future<Either<Failure, WorkspaceEntity>> cloneGit({
    required String gitUrl,
    required String name,
    String? basePath,
  }) async {
    try {
      // Reject URLs that could let an attacker smuggle git CLI flags
      // (e.g. `--upload-pack=...`) or reach file:// transports. Only
      // https://, ssh://, and the git@host:owner/repo shorthand are
      // permitted.
      final lowerUrl = gitUrl.toLowerCase();
      final isAllowed = lowerUrl.startsWith('https://') ||
          lowerUrl.startsWith('ssh://') ||
          lowerUrl.startsWith('git@');
      if (!isAllowed) {
        return const Left(
          ValidationFailure(
            message: 'Only https://, ssh://, and git@ URLs are allowed',
          ),
        );
      }
      final base = basePath ??
          p.join((await getApplicationDocumentsDirectory()).path, 'workspaces');
      final path = p.join(base, name);
      final parentDir = Directory(base);
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      final result = await Process.run(
        'git',
        ['clone', '--depth', '1', gitUrl, path],
        runInShell: false,
      );
      if (result.exitCode != 0) {
        return Left(
          NetworkFailure(
            message: 'git clone failed: ${result.stderr}',
          ),
        );
      }
      return Right(
        WorkspaceEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          path: path,
          createdAt: DateTime.now(),
          type: _detectTypeFromUrl(gitUrl),
          gitUrl: gitUrl,
        ),
      );
    } catch (e, st) {
      return Left(
        NetworkFailure(
          message: 'Failed to clone repository: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Export the workspace as a ZIP.
  ///
  /// Uses the system `zip` utility if available; otherwise falls back to
  /// creating a tarball. The destination directory is created if missing.
  Future<Either<Failure, String>> exportZip(
    WorkspaceEntity workspace, {
    String? outputPath,
  }) async {
    try {
      final outBase = outputPath ??
          p.join((await getApplicationDocumentsDirectory()).path, 'exports');
      final outDir = Directory(outBase);
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }
      final zipPath = p.join(outBase, '${workspace.name}.zip');
      // Try `zip` first (commonly available on Android via Termux).
      final result = await Process.run(
        'zip',
        ['-r', '-q', zipPath, '.'],
        workingDirectory: workspace.path,
        runInShell: false,
      );
      if (result.exitCode != 0) {
        // Fall back to tar.gz.
        final tarPath = p.join(outBase, '${workspace.name}.tar.gz');
        final tarResult = await Process.run(
          'tar',
          ['czf', tarPath, '-C', workspace.path, '.'],
          runInShell: false,
        );
        if (tarResult.exitCode != 0) {
          return Left(
            CacheFailure(
              message: 'Export failed: ${tarResult.stderr}',
            ),
          );
        }
        return Right(tarPath);
      }
      return Right(zipPath);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to export workspace: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Delete a workspace and all its files.
  Future<Either<Failure, void>> delete(WorkspaceEntity workspace) async {
    try {
      final dir = Directory(workspace.path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to delete workspace: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  WorkspaceType _detectTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('flutter')) return WorkspaceType.flutter;
    if (lower.contains('react')) return WorkspaceType.react;
    if (lower.contains('vue')) return WorkspaceType.vue;
    if (lower.contains('angular')) return WorkspaceType.angular;
    if (lower.contains('svelte')) return WorkspaceType.svelte;
    if (lower.contains('node')) return WorkspaceType.node;
    if (lower.contains('python') ||
        lower.contains('django') ||
        lower.contains('flask')) return WorkspaceType.python;
    if (lower.contains('rust')) return WorkspaceType.rust;
    // Match `go` / `golang` as a path segment or repo-name token so we
    // don't accidentally classify github.com/.../javascript as Go.
    if (RegExp(r'(/|^)(go|golang)(/|$|[-.])').hasMatch(lower)) {
      return WorkspaceType.go;
    }
    if (lower.contains('/java') ||
        lower.endsWith('.java') ||
        lower.contains('java-')) {
      return WorkspaceType.java;
    }
    if (lower.contains('cpp') || lower.contains('c++')) {
      return WorkspaceType.cpp;
    }
    return WorkspaceType.general;
  }

  static final Map<WorkspaceType, WorkspaceTemplate> _templates = {
    WorkspaceType.flutter: const WorkspaceTemplate(
      type: WorkspaceType.flutter,
      name: 'Flutter App',
      description: 'Cross-platform mobile + web app',
      language: 'Dart',
      framework: 'Flutter',
      files: {
        'pubspec.yaml': '''name: app
description: A new Flutter project.
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

flutter:
  uses-material-design: true
''',
        'lib/main.dart': """import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      home: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: Text('Hello, World!')),
      ),
    );
  }
}
""",
      },
    ),
    WorkspaceType.react: const WorkspaceTemplate(
      type: WorkspaceType.react,
      name: 'React App',
      description: 'Single-page React app with Vite',
      language: 'TypeScript',
      framework: 'React',
      files: {
        'package.json': '''{
  "name": "react-app",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  },
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  }
}''',
        'src/App.tsx': '''import { useState } from 'react';

export default function App() {
  const [count, setCount] = useState(0);
  return (
    <div>
      <h1>Hello, React!</h1>
      <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>
    </div>
  );
}''',
      },
    ),
    WorkspaceType.python: const WorkspaceTemplate(
      type: WorkspaceType.python,
      name: 'Python Project',
      description: 'Python project with venv setup',
      language: 'Python',
      framework: null,
      files: {
        'main.py': '''def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
''',
        'requirements.txt': '',
      },
    ),
    WorkspaceType.node: const WorkspaceTemplate(
      type: WorkspaceType.node,
      name: 'Node.js Project',
      description: 'Express.js server starter',
      language: 'JavaScript',
      framework: 'Express',
      files: {
        'package.json': '''{
  "name": "node-app",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}''',
        'index.js': '''const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => res.send('Hello, World!'));

app.listen(PORT, () => console.log(`Server on http://localhost:\${PORT}`));''',
      },
    ),
    WorkspaceType.web: const WorkspaceTemplate(
      type: WorkspaceType.web,
      name: 'Static Website',
      description: 'HTML + CSS + JS starter',
      language: 'HTML',
      framework: null,
      files: {
        'index.html': '''<!DOCTYPE html>
<html>
<head>
  <title>My Website</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>Hello, World!</h1>
  <script src="script.js"></script>
</body>
</html>''',
        'style.css': '''body {
  font-family: sans-serif;
  margin: 2rem;
}''',
        'script.js': '''console.log('Hello, World!');''',
      },
    ),
  };
}

class WorkspaceTemplate {
  const WorkspaceTemplate({
    required this.type,
    required this.name,
    required this.description,
    required this.language,
    this.framework,
    required this.files,
  });

  final WorkspaceType type;
  final String name;
  final String description;
  final String language;
  final String? framework;
  final Map<String, String> files;
}
