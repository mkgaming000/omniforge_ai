// Document Conversion Service - PDF/Word/Excel/PPT/Markdown/HTML/CSV conversion
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dartz/dartz.dart';
import 'package:markdown/markdown.dart' as markdown;

import '../../../core/constants/ai_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import '../ai/ai_provider_factory.dart';

enum DocumentFormat {
  pdf,
  docx,
  doc,
  xlsx,
  pptx,
  markdown,
  html,
  txt,
  csv,
  json,
  rtf,
  epub,
}

class DocumentConversionService {
  DocumentConversionService({this.factory});

  /// Optional AI provider factory for LLM-backed operations (summarize,
  /// extract). When null, those methods degrade to heuristic fallbacks.
  final AIProviderFactory? factory;

  /// Convert a document from one format to another.
  /// Uses CloudConvert / ConvertAPI / LibreOffice headless in production.
  Future<Either<Failure, ConversionResult>> convert({
    required String inputPath,
    required DocumentFormat inputFormat,
    required DocumentFormat outputFormat,
    Map<String, dynamic> options = const {},
  }) async {
    if (inputFormat == outputFormat) {
      return Right(
        ConversionResult(
          outputPath: inputPath,
          format: outputFormat,
          bytes: 0,
        ),
      );
    }

    // Markdown <-> HTML is handled natively in Dart
    if (inputFormat == DocumentFormat.markdown &&
        outputFormat == DocumentFormat.html) {
      return _markdownToHtml(inputPath);
    }
    if (inputFormat == DocumentFormat.html &&
        outputFormat == DocumentFormat.markdown) {
      return _htmlToMarkdown(inputPath);
    }
    if (inputFormat == DocumentFormat.csv &&
        outputFormat == DocumentFormat.json) {
      return _csvToJson(inputPath);
    }
    if (inputFormat == DocumentFormat.json &&
        outputFormat == DocumentFormat.csv) {
      return _jsonToCsv(inputPath);
    }

    // Cloud-based conversion for binary formats (PDF, DOCX, XLSX, PPTX)
    return _cloudConvert(
      inputPath: inputPath,
      inputFormat: inputFormat,
      outputFormat: outputFormat,
      options: options,
    );
  }

  /// Extract plain text from any document.
  Future<Either<Failure, String>> extractText(String path) async {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'txt':
      case 'md':
        return _readTextFile(path);
      case 'pdf':
        return _extractPdfText(path);
      case 'docx':
        return _extractDocxText(path);
      case 'xlsx':
        return _extractXlsxText(path);
      case 'pptx':
        return _extractPptxText(path);
      default:
        return Left(
          ValidationFailure(
            message: 'Unsupported file format: $ext',
          ),
        );
    }
  }

  /// Generate a summary of a document using the LLM.
  ///
  /// Delegates to the AI provider factory's auto-select for the
  /// `reasoning` task type — typically Gemini 1.5 Pro or Claude 3.5 Sonnet.
  Future<Either<Failure, String>> summarize({
    required String content,
    int maxWords = 200,
  }) async {
    final factory = this.factory;
    if (factory == null) {
      // Fall back to a heuristic first-3-sentence summary if no factory.
      return Right('${content.split('.').take(3).join('.')}...');
    }
    final serviceResult =
        await factory.autoSelect(taskType: ChatTaskType.reasoning);
    if (serviceResult.isLeft()) {
      return serviceResult.fold(
        (failure) => Left<Failure, String>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final service = serviceResult.getOrElse(() => throw StateError(''));
    final result = await service.complete(
      messages: [
        MessageEntity(
          id: 'doc-summarize-${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.user,
          content: content,
          createdAt: DateTime.now(),
        ),
      ],
      config: const ModelConfigEntity(
        provider: AIProvider.google,
        modelId: 'gemini-1.5-pro',
        displayName: 'Gemini 1.5 Pro',
        temperature: 0.3,
        maxTokens: 1024,
      ),
      systemPrompt: 'Summarize the following document in at most $maxWords '
          'words. Preserve the key facts and decisions. Output only the '
          'summary, no preamble.',
    );
    return result;
  }

  /// Extract structured data (entities, key-value pairs) from a document.
  ///
  /// Returns a JSON-serializable map. When [fields] is empty, the LLM is
  /// asked to auto-detect interesting fields; otherwise it tries to
  /// populate exactly the requested keys.
  Future<Either<Failure, Map<String, dynamic>>> extractData({
    required String content,
    List<String> fields = const [],
  }) async {
    final factory = this.factory;
    if (factory == null) {
      return const Right({'extractedFields': {}});
    }
    final serviceResult =
        await factory.autoSelect(taskType: ChatTaskType.reasoning);
    if (serviceResult.isLeft()) {
      return serviceResult.fold(
        (failure) => Left<Failure, Map<String, dynamic>>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final service = serviceResult.getOrElse(() => throw StateError(''));
    final fieldsPrompt = fields.isEmpty
        ? 'Auto-detect the most relevant fields.'
        : 'Extract exactly these fields: ${fields.join(", ")}.';
    final result = await service.complete(
      messages: [
        MessageEntity(
          id: 'doc-extract-${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.user,
          content: content,
          createdAt: DateTime.now(),
        ),
      ],
      config: const ModelConfigEntity(
        provider: AIProvider.zhipu,
        modelId: 'glm-5.2',
        displayName: 'GLM-5.2',
        temperature: 0.1,
        maxTokens: 2048,
      ),
      systemPrompt: 'You are a structured-data extraction engine. '
          '$fieldsPrompt Return ONLY a JSON object (no markdown, no '
          'commentary). If a field cannot be determined, use null.',
    );
    return result.fold(
      (f) => Left<Failure, Map<String, dynamic>>(f),
      (text) {
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map<String, dynamic>) {
            return Right(decoded);
          }
          return Right({'raw': text});
        } catch (_) {
          return Right({'raw': text});
        }
      },
    );
  }

  Future<Either<Failure, ConversionResult>> _markdownToHtml(
    String mdPath,
  ) async {
    try {
      final md = await File(mdPath).readAsString();
      final html = markdown.markdownToHtml(
        md,
        extensionSet: markdown.ExtensionSet.gitHubWeb,
      );
      final outPath = mdPath.replaceAll(RegExp(r'\.md$'), '.html');
      await File(outPath).writeAsString('<!DOCTYPE html>\n$html');
      return Right(
        ConversionResult(
          outputPath: outPath,
          format: DocumentFormat.html,
          bytes: html.length,
        ),
      );
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'markdown→html conversion failed: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, ConversionResult>> _htmlToMarkdown(
    String htmlPath,
  ) async {
    try {
      final html = await File(htmlPath).readAsString();
      // Strip HTML tags to produce plain text, then prepend with a heading.
      // For richer conversion (lists, links, etc.) the `html` package can
      // be added as a dependency.
      final text = html
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();
      final outPath = htmlPath.replaceAll(RegExp(r'\.html?$'), '.md');
      await File(outPath).writeAsString(text);
      return Right(
        ConversionResult(
          outputPath: outPath,
          format: DocumentFormat.markdown,
          bytes: text.length,
        ),
      );
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'html→markdown conversion failed: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, ConversionResult>> _csvToJson(String csvPath) async {
    try {
      final raw = await File(csvPath).readAsString();
      final rows = const CsvToListConverter().convert(raw);
      if (rows.isEmpty) {
        return Right(
          ConversionResult(
            outputPath: csvPath.replaceAll(RegExp(r'\.csv$'), '.json'),
            format: DocumentFormat.json,
            bytes: 2,
          ),
        );
      }
      final headers = rows.first.map((e) => e.toString()).toList();
      final jsonList = <Map<String, dynamic>>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final obj = <String, dynamic>{};
        for (var j = 0; j < headers.length && j < row.length; j++) {
          obj[headers[j]] = row[j];
        }
        jsonList.add(obj);
      }
      final jsonStr = jsonEncode(jsonList);
      final outPath = csvPath.replaceAll(RegExp(r'\.csv$'), '.json');
      await File(outPath).writeAsString(jsonStr);
      return Right(
        ConversionResult(
          outputPath: outPath,
          format: DocumentFormat.json,
          bytes: jsonStr.length,
        ),
      );
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'csv→json conversion failed: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, ConversionResult>> _jsonToCsv(String jsonPath) async {
    try {
      final raw = await File(jsonPath).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'JSON must be a non-empty array of objects',
          ),
        );
      }
      final headers = (decoded.first as Map<String, dynamic>).keys.toList();
      final csvBuffer = StringBuffer();
      csvBuffer.writeln(headers.join(','));
      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        csvBuffer.writeln(
          headers.map((h) => _csvEscape(map[h]?.toString() ?? '')).join(','),
        );
      }
      final outPath = jsonPath.replaceAll(RegExp(r'\.json$'), '.csv');
      await File(outPath).writeAsString(csvBuffer.toString());
      return Right(
        ConversionResult(
          outputPath: outPath,
          format: DocumentFormat.csv,
          bytes: csvBuffer.length,
        ),
      );
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'json→csv conversion failed: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Escape a value per RFC 4180 CSV rules.
  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<Either<Failure, ConversionResult>> _cloudConvert({
    required String inputPath,
    required DocumentFormat inputFormat,
    required DocumentFormat outputFormat,
    required Map<String, dynamic> options,
  }) async {
    // No cloud conversion backend is wired up. Surface an honest failure
    // so callers can prompt the user to add a converter API key in
    // Settings instead of silently receiving a zero-byte file.
    return const Left(
      ValidationFailure(
        message: 'Cloud document conversion is not configured. Add a '
            'CloudConvert API key in Settings.',
      ),
    );
  }

  Future<Either<Failure, String>> _readTextFile(String path) async {
    try {
      return Right(await File(path).readAsString());
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to read $path',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, String>> _extractPdfText(String path) async {
    return const Left(
      ValidationFailure(
        message: 'PDF text extraction is not configured. Add a document-parser '
            'plugin in Settings.',
      ),
    );
  }

  Future<Either<Failure, String>> _extractDocxText(String path) async {
    return const Left(
      ValidationFailure(
        message:
            'DOCX text extraction is not configured. Add a document-parser '
            'plugin in Settings.',
      ),
    );
  }

  Future<Either<Failure, String>> _extractXlsxText(String path) async {
    return const Left(
      ValidationFailure(
        message:
            'XLSX text extraction is not configured. Add a document-parser '
            'plugin in Settings.',
      ),
    );
  }

  Future<Either<Failure, String>> _extractPptxText(String path) async {
    return const Left(
      ValidationFailure(
        message:
            'PPTX text extraction is not configured. Add a document-parser '
            'plugin in Settings.',
      ),
    );
  }
}

class ConversionResult {
  const ConversionResult({
    required this.outputPath,
    required this.format,
    required this.bytes,
  });

  final String outputPath;
  final DocumentFormat format;
  final int bytes;
}
