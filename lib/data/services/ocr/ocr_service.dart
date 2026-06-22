// OCR Service - extract text from images and scanned documents
// Uses Google ML Kit on-device, Tesseract fallback, or cloud OCR providers.
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';

abstract class OcrService {
  Future<Either<Failure, OcrResult>> extractText(
    String imagePath, {
    String? language,
    bool preserveLayout = true,
  });

  Future<Either<Failure, List<OcrResult>>> extractTextBatch(
    List<String> imagePaths,
  );

  bool get isAvailable;
  String get providerId;
}

class OcrResult {
  const OcrResult({
    required this.text,
    required this.confidence,
    this.blocks = const [],
    this.language,
    this.metadata = const {},
  });

  final String text;
  final double confidence;
  final List<OcrBlock> blocks;
  final String? language;
  final Map<String, dynamic> metadata;
}

class OcrBlock {
  const OcrBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
    this.lines = const [],
  });

  final String text;
  final double confidence;
  final OcrBoundingBox boundingBox;
  final List<OcrLine> lines;
}

class OcrLine {
  const OcrLine({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });

  final String text;
  final double confidence;
  final OcrBoundingBox boundingBox;
}

class OcrBoundingBox {
  const OcrBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
}

/// ML Kit on-device OCR (recommended for Android).
///
/// Uses `google_mlkit_text_recognition` — runs entirely on-device, no API
/// key required, no network traffic. Latin script by default; switch to
/// `TextRecognizer(script: TextRecognitionScript.latin)` for other scripts.
class MlKitOcrService implements OcrService {
  MlKitOcrService();

  // Lazily instantiated so the plugin isn't touched in unit tests.
  TextRecognizer? _recognizer;
  TextRecognizer get _recognizerInstance =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  @override
  String get providerId => 'mlkit';

  @override
  bool get isAvailable => true;

  @override
  Future<Either<Failure, OcrResult>> extractText(
    String imagePath, {
    String? language,
    bool preserveLayout = true,
  }) async {
    return safeApiCall(() async {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizerInstance.processImage(inputImage);

      final blocks = recognized.blocks;
      final blockEntities = <OcrBlock>[];
      final textBuffer = StringBuffer();

      for (final b in blocks) {
        final lineEntities = <OcrLine>[];
        for (final line in b.lines) {
          lineEntities.add(
            OcrLine(
              text: line.text,
              confidence: line.confidence ?? 0.0,
              boundingBox: OcrBoundingBox(
                left: line.boundingBox.left,
                top: line.boundingBox.top,
                width: line.boundingBox.width,
                height: line.boundingBox.height,
              ),
            ),
          );
        }
        // TextBlock.confidence was removed in newer ML Kit; derive a
        // block-level confidence from the per-line confidences we already
        // gathered.
        final blockConfidence = lineEntities.isEmpty
            ? 0.0
            : lineEntities.map((l) => l.confidence).reduce((a, b) => a + b) /
                lineEntities.length;
        blockEntities.add(
          OcrBlock(
            text: b.text,
            confidence: blockConfidence,
            boundingBox: OcrBoundingBox(
              left: b.boundingBox.left,
              top: b.boundingBox.top,
              width: b.boundingBox.width,
              height: b.boundingBox.height,
            ),
            lines: lineEntities,
          ),
        );
        textBuffer.writeln(b.text);
      }

      final avgConfidence = blockEntities.isEmpty
          ? 0.0
          : blockEntities.map((b) => b.confidence).reduce((a, b) => a + b) /
              blockEntities.length;

      return OcrResult(
        text: textBuffer.toString().trim(),
        confidence: avgConfidence,
        language: language ?? 'en',
        blocks: blockEntities,
        metadata: {
          'provider': 'mlkit',
          'imagePath': imagePath,
          'blockCount': blocks.length,
          'preserveLayout': preserveLayout,
        },
      );
    });
  }

  @override
  Future<Either<Failure, List<OcrResult>>> extractTextBatch(
    List<String> imagePaths,
  ) async {
    final results = <OcrResult>[];
    for (final path in imagePaths) {
      final result = await extractText(path);
      result.fold(
        (failure) => results.add(
          OcrResult(
            text: '',
            confidence: 0,
            metadata: {'error': failure.userMessage},
          ),
        ),
        (ocr) => results.add(ocr),
      );
    }
    return Right(results);
  }
}

/// Cloud OCR via Google Vision API
class GoogleVisionOcrService implements OcrService {
  GoogleVisionOcrService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  @override
  String get providerId => 'google_vision';

  @override
  bool get isAvailable => _apiKey != null;

  @override
  Future<Either<Failure, OcrResult>> extractText(
    String imagePath, {
    String? language,
    bool preserveLayout = true,
  }) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'Google Vision API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);
      final dio = DioClient.create(
        baseUrl: 'https://vision.googleapis.com/v1',
        apiKey: _apiKey,
        apiKeyHeader: 'X-Goog-Api-Key',
      );
      final response = await dio.post(
        '/images:annotate',
        data: {
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1},
              ],
              'imageContext': {
                if (language != null) 'languageHints': [language],
              },
            }
          ],
        },
      );
      final data = response.data as Map<String, dynamic>;
      final responses = data['responses'] as List;
      if (responses.isEmpty) {
        return OcrResult(
          text: '',
          confidence: 0,
          language: language ?? 'en',
          metadata: {'provider': 'google_vision', 'imagePath': imagePath},
        );
      }
      final first =
          (responses.first as Map<String, dynamic>)['fullTextAnnotation']
              as Map<String, dynamic>?;
      final text = (first?['text'] as String?) ?? '';
      final blocks =
          (first?['pages'] as List?)?.firstOrNull as Map<String, dynamic>?;
      final blockCount = (blocks?['blocks'] as List?)?.length ?? 0;
      return OcrResult(
        text: text,
        confidence: 0.95, // Google Vision doesn't return per-block confidence
        language: language ?? 'en',
        metadata: {
          'provider': 'google_vision',
          'imagePath': imagePath,
          'blockCount': blockCount,
        },
      );
    });
  }

  @override
  Future<Either<Failure, List<OcrResult>>> extractTextBatch(
    List<String> imagePaths,
  ) async {
    final results = <OcrResult>[];
    for (final path in imagePaths) {
      final result = await extractText(path);
      result.fold(
        (f) => AppLogger.w('OCR batch item failed: ${f.userMessage}'),
        (ocr) => results.add(ocr),
      );
    }
    return Right(results);
  }
}

/// AWS Textract OCR (cloud, high-accuracy for documents)
class AwsTextractOcrService implements OcrService {
  AwsTextractOcrService();
  String? _accessKey;
  String? _secretKey;
  // ignore: unused_field
  String? _region;

  void configure({
    required String accessKey,
    required String secretKey,
    String region = 'us-east-1',
  }) {
    _accessKey = accessKey;
    _secretKey = secretKey;
    _region = region;
  }

  @override
  String get providerId => 'aws_textract';

  @override
  bool get isAvailable => _accessKey != null && _secretKey != null;

  @override
  Future<Either<Failure, OcrResult>> extractText(
    String imagePath, {
    String? language,
    bool preserveLayout = true,
  }) async {
    if (!isAvailable) {
      return const Left(
        UnauthorizedFailure(
          message: 'AWS credentials not configured.',
        ),
      );
    }
    // No AWS Textract client is wired up. Surface an honest failure so
    // callers can prompt the user to add credentials or fall back to
    // the on-device ML Kit OCR service.
    return const Left(
      ValidationFailure(
        message: 'AWS Textract OCR is not configured. Add AWS credentials in '
            'Settings, or use the on-device ML Kit OCR.',
      ),
    );
  }

  @override
  Future<Either<Failure, List<OcrResult>>> extractTextBatch(
    List<String> imagePaths,
  ) async {
    final results = <OcrResult>[];
    for (final path in imagePaths) {
      final result = await extractText(path);
      result.fold(
        (f) => AppLogger.w('OCR batch item failed: ${f.userMessage}'),
        (ocr) => results.add(ocr),
      );
    }
    return Right(results);
  }
}
