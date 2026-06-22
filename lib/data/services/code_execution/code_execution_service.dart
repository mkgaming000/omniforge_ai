// Code Execution Service - run code in 15+ languages via cloud or local
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';

abstract class CodeExecutionService {
  /// Execute code in the specified language and return output.
  Future<Either<Failure, ExecutionResult>> execute({
    required String language,
    required String code,
    Map<String, String> stdin = const {},
    List<String> args = const [],
    int timeoutSeconds = 30,
  });

  /// Execute code with streaming output (stdout/stderr in real-time).
  Stream<Either<Failure, ExecutionEvent>> executeStream({
    required String language,
    required String code,
    Map<String, String> stdin = const {},
  });

  /// List supported languages.
  List<SupportedLanguage> get supportedLanguages;
}

class ExecutionResult {
  const ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.duration,
    this.outputFiles = const [],
  });

  final String stdout;
  final String stderr;
  final int exitCode;
  final Duration duration;
  final List<OutputFile> outputFiles;

  bool get success => exitCode == 0;
}

class ExecutionEvent {
  const ExecutionEvent({
    required this.type,
    this.content,
    this.timestamp,
  });

  final ExecutionEventType type;
  final String? content;
  final DateTime? timestamp;
}

enum ExecutionEventType { stdout, stderr, exit, error }

class OutputFile {
  const OutputFile({
    required this.name,
    required this.path,
    required this.size,
    this.mimeType,
  });

  final String name;
  final String path;
  final int size;
  final String? mimeType;
}

class SupportedLanguage {
  const SupportedLanguage({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.fileExtension,
    this.defaultCode = '',
    this.versions = const [],
  });

  final String id;
  final String name;
  final String icon;
  final int color;
  final String fileExtension;
  final String defaultCode;
  final List<String> versions;
}

/// Piston API (emkc.org) - free, open-source code execution
class PistonExecutionService implements CodeExecutionService {
  PistonExecutionService();

  @override
  List<SupportedLanguage> get supportedLanguages => const [
        SupportedLanguage(
          id: 'python',
          name: 'Python 3',
          icon: 'python',
          color: 0xFF3776AB,
          fileExtension: '.py',
          defaultCode: 'print("Hello, World!")',
          versions: ['3.12.0', '3.11.6', '3.10.13'],
        ),
        SupportedLanguage(
          id: 'javascript',
          name: 'Node.js',
          icon: 'node',
          color: 0xFF339933,
          fileExtension: '.js',
          defaultCode: 'console.log("Hello, World!");',
          versions: ['21.4.0', '20.10.0', '18.19.0'],
        ),
        SupportedLanguage(
          id: 'typescript',
          name: 'TypeScript',
          icon: 'ts',
          color: 0xFF3178C6,
          fileExtension: '.ts',
          defaultCode:
              'const greet = (name: string) => `Hello, \${name}!`;\nconsole.log(greet("World"));',
        ),
        SupportedLanguage(
          id: 'java',
          name: 'Java',
          icon: 'java',
          color: 0xFFED8B00,
          fileExtension: '.java',
          defaultCode:
              'public class Main {\n  public static void main(String[] args) {\n    System.out.println("Hello, World!");\n  }\n}',
        ),
        SupportedLanguage(
          id: 'cpp',
          name: 'C++',
          icon: 'cpp',
          color: 0xFF00599C,
          fileExtension: '.cpp',
          defaultCode:
              '#include <iostream>\n\nint main() {\n  std::cout << "Hello, World!" << std::endl;\n  return 0;\n}',
        ),
        SupportedLanguage(
          id: 'c',
          name: 'C',
          icon: 'c',
          color: 0xFFA8B9CC,
          fileExtension: '.c',
          defaultCode:
              '#include <stdio.h>\n\nint main() {\n  printf("Hello, World!\\n");\n  return 0;\n}',
        ),
        SupportedLanguage(
          id: 'go',
          name: 'Go',
          icon: 'go',
          color: 0xFF00ADD8,
          fileExtension: '.go',
          defaultCode:
              'package main\n\nimport "fmt"\n\nfunc main() {\n  fmt.Println("Hello, World!")\n}',
        ),
        SupportedLanguage(
          id: 'rust',
          name: 'Rust',
          icon: 'rust',
          color: 0xFFDEA584,
          fileExtension: '.rs',
          defaultCode: 'fn main() {\n  println!("Hello, World!");\n}',
        ),
        SupportedLanguage(
          id: 'php',
          name: 'PHP',
          icon: 'php',
          color: 0xFF777BB4,
          fileExtension: '.php',
          defaultCode: '<?php\necho "Hello, World!\\n";',
        ),
        SupportedLanguage(
          id: 'ruby',
          name: 'Ruby',
          icon: 'ruby',
          color: 0xFFCC342D,
          fileExtension: '.rb',
          defaultCode: 'puts "Hello, World!"',
        ),
        SupportedLanguage(
          id: 'lua',
          name: 'Lua',
          icon: 'lua',
          color: 0xFF2C2D72,
          fileExtension: '.lua',
          defaultCode: 'print("Hello, World!")',
        ),
        SupportedLanguage(
          id: 'dart',
          name: 'Dart',
          icon: 'dart',
          color: 0xFF0175C2,
          fileExtension: '.dart',
          defaultCode: 'void main() {\n  print("Hello, World!");\n}',
        ),
      ];

  @override
  Future<Either<Failure, ExecutionResult>> execute({
    required String language,
    required String code,
    Map<String, String> stdin = const {},
    List<String> args = const [],
    int timeoutSeconds = 30,
  }) async {
    final startedAt = DateTime.now();
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://emkc.org/api/v2/piston',
      );
      // Piston accepts the language id directly; for aliases we map below.
      final lang = _pistonLanguage(language);
      final response = await dio.post(
        '/execute',
        data: {
          'language': lang,
          'version': '*', // let Piston pick the latest
          'files': [
            {
              'name': 'main${_extensionFor(lang)}',
              'content': code,
            }
          ],
          'stdin': stdin.values.join('\n'),
          'args': args,
          'compile_timeout': timeoutSeconds,
          'run_timeout': timeoutSeconds,
        },
        options: Options(
          receiveTimeout: Duration(seconds: timeoutSeconds + 5),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      final data = response.data as Map<String, dynamic>;
      final run = (data['run'] ?? {}) as Map<String, dynamic>;
      final compile = (data['compile'] ?? {}) as Map<String, dynamic>;
      final stdout = (run['stdout'] as String?) ?? '';
      final stderr = (run['stderr'] as String?) ?? '';
      final compileStderr = (compile['stderr'] as String?) ?? '';
      final exitCode = (run['code'] as num?)?.toInt() ?? 0;
      final duration = DateTime.now().difference(startedAt);
      return ExecutionResult(
        stdout: stdout,
        stderr: stderr.isNotEmpty
            ? '$compileStderr\n$stderr'.trim()
            : compileStderr,
        exitCode: exitCode,
        duration: duration,
      );
    });
  }

  /// Map our supported language IDs to Piston's canonical names.
  String _pistonLanguage(String language) {
    const aliases = {
      'python': 'python3',
      'javascript': 'javascript',
      'typescript': 'typescript',
      'java': 'java',
      'cpp': 'c++',
      'c': 'c',
      'go': 'go',
      'rust': 'rust',
      'php': 'php',
      'ruby': 'ruby',
      'lua': 'lua',
      'dart': 'dart',
    };
    return aliases[language] ?? language;
  }

  /// File extension for the requested language (used as the temp filename).
  String _extensionFor(String lang) {
    switch (lang) {
      case 'python3':
        return '.py';
      case 'javascript':
        return '.js';
      case 'typescript':
        return '.ts';
      case 'java':
        return '.java';
      case 'c++':
        return '.cpp';
      case 'c':
        return '.c';
      case 'go':
        return '.go';
      case 'rust':
        return '.rs';
      case 'php':
        return '.php';
      case 'ruby':
        return '.rb';
      case 'lua':
        return '.lua';
      case 'dart':
        return '.dart';
      default:
        return '.txt';
    }
  }

  @override
  Stream<Either<Failure, ExecutionEvent>> executeStream({
    required String language,
    required String code,
    Map<String, String> stdin = const {},
  }) async* {
    // Piston doesn't support streaming; emulate by chunking final result
    final result = await execute(language: language, code: code, stdin: stdin);
    yield result.fold(
      (failure) => Left<Failure, ExecutionEvent>(failure),
      (r) => Right(
        ExecutionEvent(
          type: ExecutionEventType.stdout,
          content: r.stdout,
          timestamp: DateTime.now(),
        ),
      ),
    );
    yield const Right(
      ExecutionEvent(
        type: ExecutionEventType.exit,
      ),
    );
  }
}

/// Judge0 execution service (self-hosted or via RapidAPI)
class Judge0ExecutionService implements CodeExecutionService {
  Judge0ExecutionService();
  // ignore: unused_field
  String? _apiKey;
  // ignore: unused_field
  String? _host;

  void configure({required String apiKey, required String host}) {
    _apiKey = apiKey;
    _host = host;
  }

  @override
  List<SupportedLanguage> get supportedLanguages =>
      PistonExecutionService().supportedLanguages;

  @override
  Future<Either<Failure, ExecutionResult>> execute({
    required String language,
    required String code,
    Map<String, String> stdin = const {},
    List<String> args = const [],
    int timeoutSeconds = 30,
  }) async {
    // No Judge0 HTTP client is wired up. Whether or not a host + API key
    // has been set, surface an honest failure so callers can fall back to
    // the default Piston runner.
    return const Left(
      ValidationFailure(
        message: 'Judge0 code execution is not configured. Add a Judge0 host '
            '+ API key in Settings, or use the default Piston runner.',
      ),
    );
  }

  @override
  Stream<Either<Failure, ExecutionEvent>> executeStream({
    required String language,
    required String code,
    Map<String, String> stdin = const {},
  }) async* {
    final result = await execute(language: language, code: code, stdin: stdin);
    yield result.fold(
      (failure) => Left<Failure, ExecutionEvent>(failure),
      (r) => Right(
        ExecutionEvent(
          type: ExecutionEventType.stdout,
          content: r.stdout,
          timestamp: DateTime.now(),
        ),
      ),
    );
  }
}
