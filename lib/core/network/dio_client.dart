// Dio HTTP client configuration with retry, logging, auth interceptors
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../errors/error_handler.dart';
import '../errors/failures.dart';

class DioClient {
  DioClient._();

  static Dio create({
    required String baseUrl,
    String? apiKey,
    String? apiKeyHeader,
    Map<String, dynamic>? defaultHeaders,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?defaultHeaders,
        },
        responseType: ResponseType.json,
        // Treat only 2xx as success. 4xx (auth, validation, rate limit)
        // and 5xx (server) errors throw DioException, which ErrorHandler
        // converts to typed Failures. Without this, 4xx responses would
        // be silently parsed as success bodies, hiding real errors.
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    // Auth interceptor
    if (apiKey != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (apiKeyHeader == 'Authorization') {
              options.headers['Authorization'] = 'Bearer $apiKey';
            } else if (apiKeyHeader != null) {
              options.headers[apiKeyHeader] = apiKey;
            } else {
              options.headers['Authorization'] = 'Bearer $apiKey';
            }
            handler.next(options);
          },
        ),
      );
    }

    // Retry on transient failures
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retries: AppConstants.maxRetries,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
        ],
        retryEvaluator: (error, attempt) {
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError) {
            return true;
          }
          final status = error.response?.statusCode;
          if (status != null && (status == 429 || status >= 500)) {
            return true;
          }
          return false;
        },
      ),
    );

    // Logging in debug
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }

    return dio;
  }

  /// Build a Dio instance configured for Server-Sent Events (streaming)
  static Dio createStream({
    required String baseUrl,
    String? apiKey,
    String? apiKeyHeader,
  }) {
    final dio = create(
      baseUrl: baseUrl,
      apiKey: apiKey,
      apiKeyHeader: apiKeyHeader,
    );
    dio.options.responseType = ResponseType.stream;
    dio.options.headers['Accept'] = 'text/event-stream';
    dio.options.receiveTimeout = const Duration(minutes: 5);
    return dio;
  }
}

/// Generic safe API call wrapper.
Future<Either<Failure, T>> safeApiCall<T>(
  Future<T> Function() call,
) async {
  try {
    final result = await call();
    return Right(result);
  } catch (e, st) {
    return Left(ErrorHandler.handle(e, st));
  }
}
