// Terminal Page - sandboxed workspace shell + in-terminal AI chat
//
// IMPORTANT, HONEST SCOPE NOTE: stock, non-rooted Android does not expose a
// general-purpose POSIX shell or language runtimes (no bash/zsh/python/node
// binaries ship with the OS, and Android's app sandbox forbids executing
// arbitrary host binaries from third-party apps). A "real bash with real
// python/node REPLs" is not achievable here without bundling those runtimes,
// which is a much larger undertaking than fixing this screen. Rather than
// faking that capability, this terminal implements real, working built-in
// commands against the app's own sandboxed workspace directory, plus a real
// `claude` command wired to the already-implemented Anthropic provider.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../injection/injection.dart';
import '../../../data/services/ai/ai_provider_factory.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final _output = <String>[
    'OmniForge AI Terminal v1.0.0',
    "Sandboxed workspace shell — type 'help' for available commands.",
    '',
  ];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  Directory? _workspaceRoot;
  Directory? _cwd;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initWorkspace());
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
      _cwd = root;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _displayCwd {
    if (_workspaceRoot == null || _cwd == null) return '~';
    final rel = p.relative(_cwd!.path, from: _workspaceRoot!.path);
    return rel == '.' ? '~' : '~/$rel';
  }

  void _print(String line) => _output.add(line);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Container(
            color: const Color(0xFF0A0A0F),
            padding: const EdgeInsets.all(12),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _output.length,
              itemBuilder: (context, index) {
                return SelectableText(
                  _output[index],
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    color: Color(0xFF00E5FF),
                    height: 1.4,
                  ),
                );
              },
            ),
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF141118),
      child: Row(
        children: [
          const Icon(Icons.terminal, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            _workspaceRoot == null ? 'initializing…' : 'workspace',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white, size: 18),
            onPressed: () => setState(() => _output.clear()),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFF141118),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '$_displayCwd \$',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              color: Color(0xFF00E5FF),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_busy,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                color: Colors.white,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'type a command (try: help)',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onSubmitted: _execute,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green, size: 18),
            onPressed: _busy ? null : () => _execute(_inputController.text),
          ),
        ],
      ),
    );
  }

  Future<void> _execute(String raw) async {
    final command = raw.trim();
    if (command.isEmpty || _busy || _cwd == null) return;

    _inputController.clear();
    setState(() {
      _print('$_displayCwd \$ $command');
    });

    final parts = _splitArgs(command);
    final name = parts.first;
    final args = parts.skip(1).toList();

    try {
      switch (name) {
        case 'help':
          _printHelp();
          break;
        case 'clear':
          _output.clear();
          break;
        case 'pwd':
          _print(_cwd!.path);
          break;
        case 'ls':
          await _cmdLs(args);
          break;
        case 'cd':
          await _cmdCd(args);
          break;
        case 'mkdir':
          await _cmdMkdir(args);
          break;
        case 'touch':
          await _cmdTouch(args);
          break;
        case 'cat':
          await _cmdCat(args);
          break;
        case 'rm':
          await _cmdRm(args);
          break;
        case 'echo':
          _print(args.join(' '));
          break;
        case 'claude':
          await _cmdClaude(args.join(' '));
          break;
        case 'python':
        case 'node':
        case 'java':
        case 'bash':
        case 'zsh':
          _print(
            "'$name' requires a bundled language runtime, which Android's "
            'app sandbox does not provide without shipping that runtime '
            "inside the app. Not available in this build — try 'claude "
            "<prompt>' to ask the AI to run/explain code instead.",
          );
          break;
        default:
          _print('Command not found: $name (type "help" for a list)');
      }
    } catch (e) {
      _print('Error: $e');
    }

    _print('');
    setState(() {});
    _scrollToBottom();
  }

  List<String> _splitArgs(String command) {
    return command.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }

  void _printHelp() {
    _output.addAll([
      'Available commands (sandboxed to the app workspace directory):',
      '  ls [dir]        - list directory contents',
      '  cd <dir>        - change directory (supports .. and ~)',
      '  pwd             - print working directory',
      '  mkdir <dir>     - create a directory',
      '  touch <file>    - create an empty file',
      '  cat <file>      - print file contents',
      '  rm <path>       - delete a file or empty directory',
      '  echo <text>     - print text',
      '  claude <prompt> - ask Claude a question (uses your saved API key)',
      '  clear           - clear the terminal',
    ]);
  }

  String _resolve(String path) {
    if (path == '~' || path.isEmpty) return _workspaceRoot!.path;
    if (path.startsWith('~/')) {
      return p.normalize(p.join(_workspaceRoot!.path, path.substring(2)));
    }
    return p.normalize(p.isAbsolute(path) ? path : p.join(_cwd!.path, path));
  }

  /// Refuses to resolve outside the sandboxed workspace root.
  bool _withinSandbox(String resolved) {
    return p.isWithin(_workspaceRoot!.path, resolved) ||
        p.equals(_workspaceRoot!.path, resolved);
  }

  Future<void> _cmdLs(List<String> args) async {
    final resolved = args.isEmpty ? _cwd!.path : _resolve(args.first);
    if (!_withinSandbox(resolved)) {
      _print('ls: permission denied: cannot leave the workspace sandbox');
      return;
    }
    final target = Directory(resolved);
    if (!await target.exists()) {
      _print('ls: ${args.isEmpty ? '.' : args.first}: No such directory');
      return;
    }
    final entries = await target.list().toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    if (entries.isEmpty) {
      _print('(empty)');
      return;
    }
    for (final e in entries) {
      final isDir = e is Directory;
      _print('${isDir ? 'd ' : '- '}${p.basename(e.path)}');
    }
  }

  Future<void> _cmdCd(List<String> args) async {
    final target = args.isEmpty ? '~' : args.first;
    final resolved = target == '..' ? p.dirname(_cwd!.path) : _resolve(target);
    if (!_withinSandbox(resolved)) {
      _print('cd: permission denied: cannot leave the workspace sandbox');
      return;
    }
    final dir = Directory(resolved);
    if (!await dir.exists()) {
      _print('cd: $target: No such directory');
      return;
    }
    setState(() => _cwd = dir);
  }

  Future<void> _cmdMkdir(List<String> args) async {
    if (args.isEmpty) {
      _print('mkdir: missing operand');
      return;
    }
    final resolved = _resolve(args.first);
    if (!_withinSandbox(resolved)) {
      _print('mkdir: permission denied');
      return;
    }
    await Directory(resolved).create(recursive: true);
  }

  Future<void> _cmdTouch(List<String> args) async {
    if (args.isEmpty) {
      _print('touch: missing operand');
      return;
    }
    final resolved = _resolve(args.first);
    if (!_withinSandbox(resolved)) {
      _print('touch: permission denied');
      return;
    }
    final file = File(resolved);
    if (!await file.exists()) {
      await file.create(recursive: true);
    } else {
      await file.setLastModified(DateTime.now());
    }
  }

  Future<void> _cmdCat(List<String> args) async {
    if (args.isEmpty) {
      _print('cat: missing operand');
      return;
    }
    final resolved = _resolve(args.first);
    if (!_withinSandbox(resolved)) {
      _print('cat: permission denied: cannot leave the workspace sandbox');
      return;
    }
    final file = File(resolved);
    if (!await file.exists()) {
      _print('cat: ${args.first}: No such file');
      return;
    }
    try {
      final content = await file.readAsString();
      _print(content.isEmpty ? '(empty file)' : content);
    } catch (e) {
      _print('cat: ${args.first}: not a readable text file ($e)');
    }
  }

  Future<void> _cmdRm(List<String> args) async {
    if (args.isEmpty) {
      _print('rm: missing operand');
      return;
    }
    final resolved = _resolve(args.first);
    if (!_withinSandbox(resolved) || p.equals(resolved, _workspaceRoot!.path)) {
      _print('rm: permission denied');
      return;
    }
    final file = File(resolved);
    final dir = Directory(resolved);
    if (await file.exists()) {
      await file.delete();
    } else if (await dir.exists()) {
      try {
        await dir.delete();
      } on FileSystemException {
        _print('rm: ${args.first}: directory not empty');
      }
    } else {
      _print('rm: ${args.first}: No such file or directory');
    }
  }

  Future<void> _cmdClaude(String prompt) async {
    if (prompt.trim().isEmpty) {
      _print('usage: claude <prompt>');
      return;
    }
    setState(() => _busy = true);
    try {
      final factory = getIt<AIProviderFactory>();
      final serviceResult = await factory.getService(AIProvider.anthropic);

      await serviceResult.fold(
        (failure) async =>
            _print('claude: ${failure.message ?? 'request failed'}'),
        (service) async {
          final result = await service.complete(
            messages: [
              MessageEntity(
                id: _uuid.v4(),
                role: MessageRole.user,
                content: prompt,
                createdAt: DateTime.now(),
              ),
            ],
            config: const ModelConfigEntity(
              provider: AIProvider.anthropic,
              modelId: 'claude-3-5-sonnet-20241022',
              maxTokens: 1024,
            ),
          );
          result.fold(
            (failure) =>
                _print('claude: ${failure.message ?? 'request failed'}'),
            (text) => _print(text),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
