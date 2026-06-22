// Coding Assistant Service - code-specific AI operations
// Code completion, refactoring, review, explanation, debugging, generation
import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/model_config_entity.dart';
import '../ai/ai_provider_factory.dart';

class CodingAssistantService {
  CodingAssistantService({required this.providerFactory});

  final AIProviderFactory providerFactory;

  /// Generate code from natural language description.
  Future<Either<Failure, String>> generateCode({
    required String description,
    required String language,
    String? context,
    String? framework,
  }) async {
    final prompt = '''
Generate $language code for the following request:
$description

${framework != null ? "Framework: $framework" : ""}
${context != null ? "Existing code context:\n```\n$context\n```" : ""}

Return ONLY the code in a single markdown code block. Do not include explanations.
''';
    return _complete(prompt);
  }

  /// Explain a piece of code in plain English.
  Future<Either<Failure, String>> explainCode({
    required String code,
    required String language,
    String? question,
  }) async {
    final prompt = '''
Explain this $language code${question != null ? " with focus on: $question" : ""}:

```$language
$code
```

Provide a clear, beginner-friendly explanation. Use markdown formatting.
''';
    return _complete(prompt);
  }

  /// Review code for bugs, security issues, and best practices.
  Future<Either<Failure, CodeReview>> reviewCode({
    required String code,
    required String language,
    String? context,
  }) async {
    final prompt = '''
Review this $language code for:
1. Bugs and potential errors
2. Security vulnerabilities
3. Performance issues
4. Best practices violations
5. Code style

```$language
$code
```

${context != null ? "Context: $context" : ""}

Return a JSON object with this structure:
{"summary": "...", "issues": [{"severity": "high|medium|low", "category": "bug|security|performance|style", "line": 1, "message": "...", "suggestion": "..."}], "score": 0-100}
''';
    final result = await _complete(prompt);
    return result.fold(
      (f) => Left(f),
      (text) => Right(
        CodeReview(
          summary: text,
          issues: [],
          score: 0,
          rawResponse: text,
        ),
      ),
    );
  }

  /// Refactor code to improve quality without changing behavior.
  Future<Either<Failure, String>> refactorCode({
    required String code,
    required String language,
    String? goal,
  }) async {
    final prompt = '''
Refactor this $language code${goal != null ? " to improve $goal" : ""}.
Preserve behavior. Return ONLY the refactored code in a code block.

```$language
$code
```
''';
    return _complete(prompt);
  }

  /// Add tests for the given code.
  Future<Either<Failure, String>> generateTests({
    required String code,
    required String language,
    String? testFramework,
  }) async {
    final prompt = '''
Generate ${testFramework ?? 'unit'} tests for this $language code.
Cover edge cases and error conditions.
Return ONLY the test code in a code block.

```$language
$code
```
''';
    return _complete(prompt);
  }

  /// Fix bugs in code.
  Future<Either<Failure, String>> fixBugs({
    required String code,
    required String language,
    required String errorOrBehavior,
  }) async {
    final prompt = '''
Fix the bugs in this $language code.

Problem:
$errorOrBehavior

```$language
$code
```

Return ONLY the fixed code in a code block. Briefly explain the fix in a comment.
''';
    return _complete(prompt);
  }

  /// Convert code from one language to another.
  Future<Either<Failure, String>> convertLanguage({
    required String sourceCode,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final prompt = '''
Convert this $sourceLanguage code to $targetLanguage.
Preserve behavior and use idiomatic $targetLanguage patterns.
Return ONLY the converted code in a code block.

```$sourceLanguage
$sourceCode
```
''';
    return _complete(prompt);
  }

  /// Generate documentation for code.
  Future<Either<Failure, String>> generateDocs({
    required String code,
    required String language,
    String format = 'markdown',
  }) async {
    final prompt = '''
Generate $format documentation for this $language code.
Include parameter descriptions, return values, and examples.

```$language
$code
```
''';
    return _complete(prompt);
  }

  /// Stream autocompletion suggestions.
  Stream<Either<Failure, String>> autocomplete({
    required String prefix,
    required String language,
    String? context,
  }) async* {
    final prompt = '''
Continue this $language code. Return ONLY the completion (no explanation).

${context != null ? "Context:\n```\n$context\n```\n" : ""}

Prefix to continue:
```
$prefix
```
''';
    final serviceResult =
        await providerFactory.autoSelect(taskType: ChatTaskType.coding);
    if (serviceResult.isLeft()) {
      yield serviceResult.fold(
        (l) => Left<Failure, String>(l),
        (_) => throw StateError(''),
      );
      return;
    }
    final service = serviceResult.getOrElse(() => throw StateError(''));
    final stream = service.stream(
      messages: [],
      config: _defaultCodingConfig,
      systemPrompt: prompt,
    );
    await for (final event in stream) {
      yield event;
    }
  }

  Future<Either<Failure, String>> _complete(String prompt) async {
    final serviceResult =
        await providerFactory.autoSelect(taskType: ChatTaskType.coding);
    if (serviceResult.isLeft()) {
      return serviceResult.fold(
        (l) => Left<Failure, String>(l),
        (_) => throw StateError(''),
      );
    }
    final service = serviceResult.getOrElse(() => throw StateError(''));
    return service.complete(
      messages: [],
      config: _defaultCodingConfig,
      systemPrompt: prompt,
    );
  }
}

class CodeReview {
  const CodeReview({
    required this.summary,
    required this.issues,
    required this.score,
    required this.rawResponse,
  });

  final String summary;
  final List<CodeIssue> issues;
  final int score;
  final String rawResponse;
}

class CodeIssue {
  const CodeIssue({
    required this.severity,
    required this.category,
    required this.line,
    required this.message,
    required this.suggestion,
  });

  final IssueSeverity severity;
  final IssueCategory category;
  final int line;
  final String message;
  final String suggestion;
}

enum IssueSeverity { high, medium, low }

enum IssueCategory { bug, security, performance, style, bestPractice }

const _defaultCodingConfig = ModelConfigEntity(
  provider: AIProvider.anthropic,
  modelId: 'claude-3-5-sonnet-20241022',
  displayName: 'Claude 3.5 Sonnet v2',
  temperature: 0.2,
  maxTokens: 8192,
  costPer1kInput: 0.003,
  costPer1kOutput: 0.015,
  contextWindow: 200000,
  supportsTools: true,
  supportsVision: true,
);
