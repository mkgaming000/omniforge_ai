// Runtime Page - run code in 15+ languages
import 'package:flutter/material.dart';

import '../../../data/services/code_execution/code_execution_service.dart';
import '../../../injection/injection.dart';

class RuntimePage extends StatefulWidget {
  const RuntimePage({super.key});

  @override
  State<RuntimePage> createState() => _RuntimePageState();
}

class _RuntimePageState extends State<RuntimePage> {
  String _selectedLanguage = 'python';
  final _codeController = TextEditingController();
  String _output = '';
  bool _isRunning = false;

  static const _languages = {
    'python': {
      'name': 'Python',
      'icon': Icons.terminal,
      'color': Color(0xFF3776AB),
    },
    'javascript': {
      'name': 'JavaScript',
      'icon': Icons.javascript,
      'color': Color(0xFFF7DF1E),
    },
    'typescript': {
      'name': 'TypeScript',
      'icon': Icons.code,
      'color': Color(0xFF3178C6),
    },
    'html': {'name': 'HTML', 'icon': Icons.html, 'color': Color(0xFFE34F26)},
    'css': {'name': 'CSS', 'icon': Icons.css, 'color': Color(0xFF1572B6)},
    'react': {'name': 'React', 'icon': Icons.web, 'color': Color(0xFF61DAFB)},
    'vue': {'name': 'Vue', 'icon': Icons.web, 'color': Color(0xFF42B883)},
    'svelte': {'name': 'Svelte', 'icon': Icons.web, 'color': Color(0xFFFF3E00)},
    'node': {
      'name': 'Node.js',
      'icon': Icons.terminal,
      'color': Color(0xFF339933),
    },
    'java': {'name': 'Java', 'icon': Icons.coffee, 'color': Color(0xFFED8B00)},
    'cpp': {'name': 'C++', 'icon': Icons.memory, 'color': Color(0xFF00599C)},
    'php': {'name': 'PHP', 'icon': Icons.code, 'color': Color(0xFF777BB4)},
    'go': {'name': 'Go', 'icon': Icons.code, 'color': Color(0xFF00ADD8)},
    'rust': {'name': 'Rust', 'icon': Icons.code, 'color': Color(0xFFDEA584)},
    'dart': {
      'name': 'Dart',
      'icon': Icons.flutter_dash,
      'color': Color(0xFF0175C2),
    },
    'flutter': {
      'name': 'Flutter Preview',
      'icon': Icons.phone_android,
      'color': Color(0xFF02569B),
    },
  };

  @override
  void initState() {
    super.initState();
    _codeController.text = _sampleCode('python');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLanguageSelector(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildCodeEditor(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: _buildOutput(),
              ),
            ],
          ),
        ),
        _buildActionBar(),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final entry = _languages.entries.elementAt(index);
          final isSelected = _selectedLanguage == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              avatar: Icon(entry.value['icon'] as IconData, size: 16),
              label: Text(entry.value['name'] as String),
              onSelected: (_) {
                setState(() {
                  _selectedLanguage = entry.key;
                  _codeController.text = _sampleCode(entry.key);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCodeEditor() {
    return Container(
      color: const Color(0xFF1E1E2E),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _codeController,
        maxLines: null,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 13,
          color: Color(0xFFE6E0E9),
          height: 1.6,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '// Write your code here...',
          hintStyle: TextStyle(color: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildOutput() {
    return Container(
      color: const Color(0xFF0A0A0F),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.output, color: Color(0xFF00E5FF), size: 16),
              const SizedBox(width: 8),
              Text(
                'Output',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _output.isEmpty ? 'Click Run to execute...' : _output,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: _isRunning ? null : _run,
            icon: _isRunning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Run'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => _output = ''),
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save project',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Future<void> _run() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _output = '[${DateTime.now()}] Running $_selectedLanguage...\n';
    });

    final service = getIt<CodeExecutionService>();
    final result = await service.execute(
      language: _selectedLanguage,
      code: _codeController.text,
      timeoutSeconds: 30,
    );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isRunning = false;
        _output = '$_output\n✗ Error: ${failure.userMessage}';
      }),
      (r) => setState(() {
        _isRunning = false;
        final buffer = StringBuffer(_output);
        buffer.writeln();
        if (r.stdout.isNotEmpty) buffer.writeln(r.stdout);
        if (r.stderr.isNotEmpty) {
          buffer.writeln('--- stderr ---');
          buffer.writeln(r.stderr);
        }
        buffer.writeln();
        buffer.writeln('[Process exited with code ${r.exitCode} '
            'in ${r.duration.inMilliseconds}ms]');
        _output = buffer.toString();
      }),
    );
  }

  String _sampleCode(String lang) {
    switch (lang) {
      case 'python':
        return 'print("Hello, World!")';
      case 'javascript':
      case 'node':
        return 'console.log("Hello, World!");';
      case 'html':
        return '<!DOCTYPE html>\n<html>\n  <body>\n    <h1>Hello, World!</h1>\n  </body>\n</html>';
      case 'dart':
        return "void main() {\n  print('Hello, World!');\n}";
      default:
        return '// $lang\n// Write your code here';
    }
  }
}
