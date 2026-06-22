// Centralized error handler that converts exceptions to Failures
import 'package:dio/dio.dart';

import 'failures.dart';

class ErrorHandler {
  ErrorHandler._();

  static Failure handle(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;

    if (error is DioException) {
      return _handleDioError(error, stackTrace);
    }

    if (error is FormatException) {
      return ValidationFailure(
        message: 'Invalid data format: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is ArgumentError) {
      return ValidationFailure(
        message: error.message.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownFailure(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static Failure _handleDioError(DioException e, StackTrace? stackTrace) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(
          message: 'Request timed out',
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: 'No internet connection',
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badResponse:
        return _handleResponse(e.response, e, stackTrace);
      case DioExceptionType.cancel:
        return UnknownFailure(
          message: 'Request was cancelled',
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badCertificate:
        return SecurityFailure(
          message: 'SSL certificate verification failed',
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.unknown:
        return UnknownFailure(
          message: e.message ?? 'Unknown network error',
          originalError: e,
          stackTrace: stackTrace,
        );
    }
  }

  static Failure _handleResponse(
    Response<dynamic>? response,
    DioException e,
    StackTrace? stackTrace,
  ) {
    if (response == null) {
      return ServerFailure(
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String? errorMessage;

    if (data is Map<String, dynamic>) {
      errorMessage = (data['error']?['message'] ??
          data['message'] ??
          data['detail'] ??
          data['error']) as String?;
    } else if (data is String) {
      errorMessage = data;
    }

    if (statusCode == 401 || statusCode == 403) {
      return UnauthorizedFailure(
        message: errorMessage,
        code: statusCode.toString(),
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 429) {
      return RateLimitFailure(
        message: errorMessage,
        code: '429',
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 404) {
      return NotFoundFailure(
        message: errorMessage,
        code: '404',
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    if (statusCode >= 500) {
      return ServerFailure(
        message: errorMessage,
        code: statusCode.toString(),
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 400 || statusCode == 422) {
      return ValidationFailure(
        message: errorMessage,
        code: statusCode.toString(),
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    return ProviderFailure(
      message: errorMessage,
      code: statusCode.toString(),
      originalError: e,
      stackTrace: stackTrace,
    );
  }
}
