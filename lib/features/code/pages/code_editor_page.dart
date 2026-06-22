// Code Editor Page - real file-backed editor over the sandboxed workspace
//
// HONEST SCOPE NOTE: this edits real files (open/edit/save) in the same
// `<app docs>/workspace` sandbox the Terminal feature operates on, so the
// two features are consistent and interoperable. It does NOT run a real
// Dart analyzer in-app (that requires bundling the `analyzer` package and
// a full Dart SDK snapshot, a much larger undertaking) — the diagnostics
// panel says so plainly rather than showing a fake "no problems" status.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CodeEditorPage extends StatefulWidget {
  const CodeEditorPage({super.key});

  @override
  State<CodeEditorPage> createState() => _CodeEditorPageState();
}

class _OpenFile {
  _OpenFile(this.path, String content)
      : controller = TextEditingController(text: content),
        savedContent = content;

  final String path;
  final TextEditingController controller;
  String savedContent;

  bool get isDirty => controller.text != savedContent;
  String get name => p.basename(path);
}

class _CodeEditorPageState extends State<CodeEditorPage> {
  Directory? _workspaceRoot;
  Directory? _browsingDir;
  final List<_OpenFile> _openFiles = [];
  int _activeTab = -1;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_initWorkspace());
  }

  @override
  void dispose() {
    for (final f in _openFiles) {
      f.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initWorkspace() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, 'workspace'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    if (!mounted) return;
    setState(() {
      _workspaceRoot = root;
      _browsingDir = root;
    });
  }

  Future<void> _openFile(File file) async {
    final existingIndex = _openFiles.indexWhere((f) => f.path == file.path);
    if (existingIndex != -1) {
      setState(() => _activeTab = existingIndex);
      return;
    }
    try {
      final content = await file.readAsString();
      setState(() {
        _openFiles.add(_OpenFile(file.path, content));
        _activeTab = _openFiles.length - 1;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not open ${p.basename(file.path)}: $e');
    }
  }

  Future<void> _saveActiveFile() async {
    if (_activeTab < 0 || _activeTab >= _openFiles.length) return;
    final f = _openFiles[_activeTab];
    try {
      await File(f.path).writeAsString(f.controller.text);
      setState(() => f.savedContent = f.controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${f.name}'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Could not save ${f.name}: $e');
    }
  }

  void _closeTab(int index) {
    final f = _openFiles[index];
    f.controller.dispose();
    setState(() {
      _openFiles.removeAt(index);
      if (_activeTab >= _openFiles.length) {
        _activeTab = _openFiles.length - 1;
      }
    });
  }

  Future<void> _createFile(String name) async {
    if (_browsingDir == null || _workspaceRoot == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        trimmed.contains('/') ||
        trimmed.contains('\\') ||
        trimmed.contains('..')) {
      setState(() => _error = 'Invalid filename: "$trimmed"');
      return;
    }
    final file = File(p.join(_browsingDir!.path, trimmed));
    if (!p.isWithin(_workspaceRoot!.path, file.path)) {
      setState(() => _error = 'Cannot create a file outside the workspace');
      return;
    }
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    setState(() {});
    await _openFile(file);
  }

  @override
  Widget build(BuildContext context) {
    if (_workspaceRoot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: _FileExplorer(
            root: _workspaceRoot!,
            current: _browsingDir!,
            onOpenFile: _openFile,
            onChangeDir: (d) => setState(() => _browsingDir = d),
            onNewFile: _promptNewFile,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              _buildTabBar(),
              if (_error != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.withOpacity(0.15),
                  padding: const EdgeInsets.all(8),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              Expanded(child: _buildEditor()),
              _buildDiagnosticsPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _promptNewFile() async {
    final controller = TextEditingController();
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New file'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'filename.dart'),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Create'),
            ),
          ],
        ),
      );
      if (name != null && name.trim().isNotEmpty) {
        await _createFile(name);
      }
    } finally {
      controller.dispose();
    }
  }

  Widget _buildTabBar() {
    if (_openFiles.isEmpty) {
      return Container(
        height: 36,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'No file open — pick one from the explorer',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return SizedBox(
      height: 36,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _openFiles.length,
          itemBuilder: (context, index) {
            final f = _openFiles[index];
            final active = index == _activeTab;
            return InkWell(
              onTap: () => setState(() => _activeTab = index),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.isDirty ? '${f.name} •' : f.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _closeTab(index),
                      child: const Icon(Icons.close, size: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditor() {
    if (_activeTab < 0 || _activeTab >= _openFiles.length) {
      return Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E2E)
            : const Color(0xFFFAFAFA),
        alignment: Alignment.center,
        child: const Text('Open a file to start editing'),
      );
    }
    final f = _openFiles[_activeTab];
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E2E)
          : const Color(0xFFFAFAFA),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: IconButton(
                tooltip: 'Save (writes to disk)',
                icon: const Icon(Icons.save, size: 18),
                onPressed: f.isDirty ? _saveActiveFile : null,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              key: ValueKey(f.path),
              controller: f.controller,
              maxLines: null,
              expands: true,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsPanel() {
    return Container(
      height: 64,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const _PanelHeader(title: 'Problems'),
          Expanded(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.info_outline, size: 16),
              title: Text(
                'Static analysis is not wired up in-app yet — run '
                '`dart analyze` from the CLI to check this file.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileExplorer extends StatelessWidget {
  const _FileExplorer({
    required this.root,
    required this.current,
    required this.onOpenFile,
    required this.onChangeDir,
    required this.onNewFile,
  });

  final Directory root;
  final Directory current;
  final ValueChanged<File> onOpenFile;
  final ValueChanged<Directory> onChangeDir;
  final VoidCallback onNewFile;

  Future<List<FileSystemEntity>> _listSorted(Directory dir) async {
    final entries = await dir.list().toList();
    entries.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      return p.basename(a.path).compareTo(p.basename(b.path));
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p.equals(current.path, root.path)
                        ? 'workspace'
                        : p.relative(current.path, from: root.path),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'New file',
                  icon: const Icon(Icons.note_add_outlined, size: 18),
                  onPressed: onNewFile,
                ),
              ],
            ),
          ),
          if (!p.equals(current.path, root.path))
            ListTile(
              dense: true,
              leading: const Icon(Icons.arrow_upward, size: 16),
              title: const Text('..'),
              onTap: () {
                final parent = Directory(p.dirname(current.path));
                // Never navigate above the workspace root.
                if (p.isWithin(root.path, parent.path) ||
                    p.equals(root.path, parent.path)) {
                  onChangeDir(parent);
                }
              },
            ),
          Expanded(
            child: FutureBuilder<List<FileSystemEntity>>(
              future: _listSorted(current),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data!;
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Empty — create a file to get started'),
                  );
                }
                return ListView(
                  children: entries.map((e) {
                    if (e is Directory) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.folder,
                          size: 18,
                          color: Colors.amber,
                        ),
                        title: Text(p.basename(e.path)),
                        onTap: () => onChangeDir(e),
                      );
                    }
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.description_outlined, size: 16),
                      title: Text(p.basename(e.path)),
                      onTap: () => onOpenFile(e as File),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
