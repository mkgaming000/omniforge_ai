// Google Drive Sync Service
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import 'cloud_sync_service.dart';

class GoogleDriveSyncService implements CloudSyncService {
  GoogleDriveSyncService();
  String? _accessToken;

  void setAccessToken(String token) => _accessToken = token;

  @override
  String get providerId => 'google_drive';

  @override
  String get displayName => 'Google Drive';

  @override
  String get authUrl => 'https://accounts.google.com/o/oauth2/auth';

  @override
  Future<bool> get isAuthenticated => Future.value(_accessToken != null);

  @override
  Future<Either<Failure, String>> authenticate() async {
    if (_accessToken == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'Google Drive requires OAuth. Configure in Settings.',
        ),
      );
    }
    return Right(_accessToken!);
  }

  @override
  Future<Either<Failure, List<CloudFile>>> listFiles({
    String path = '/',
    int limit = 100,
  }) async {
    if (_accessToken == null) {
      return const Left(UnauthorizedFailure(message: 'Not authenticated'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://www.googleapis.com/drive/v3',
        apiKey: _accessToken,
      );
      final response = await dio.get(
        '/files',
        queryParameters: {
          'pageSize': limit,
          'fields': 'files(id,name,mimeType,size,modifiedTime)',
          'q': 'trashed=false',
        },
      );
      final items = response.data['files'] as List;
      return items
          .map<CloudFile>(
            (item) => CloudFile(
              id: item['id'] as String,
              name: item['name'] as String,
              path: '/${item['name']}',
              size: int.tryParse(item['size'] as String? ?? '0') ?? 0,
              modifiedAt:
                  DateTime.tryParse(item['modifiedTime'] as String? ?? '') ??
                      DateTime.now(),
              mimeType: item['mimeType'] as String?,
              isFolder:
                  item['mimeType'] == 'application/vnd.google-apps.folder',
            ),
          )
          .toList();
    });
  }

  @override
  Future<Either<Failure, CloudFile>> uploadFile({
    required String localPath,
    required String remotePath,
  }) async {
    if (_accessToken == null) {
      return const Left(UnauthorizedFailure(message: 'Not authenticated'));
    }
    return safeApiCall(() async {
      final bytes = await File(localPath).readAsBytes();
      final fileName = remotePath.split('/').last;
      final formData = FormData.fromMap({
        'metadata': jsonEncode({
          'name': fileName,
          // Drive treats forward-slash paths as a flat name; we keep the
          // raw remotePath so callers can re-resolve it.
          'description': 'Uploaded by OmniForge AI: $remotePath',
        }),
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final dio = DioClient.create(
        baseUrl: 'https://www.googleapis.com/upload/drive/v3',
        apiKey: _accessToken,
      );
      // dio computes the multipart boundary + Content-Length automatically
      // when given a FormData body — do not set them manually.
      final response = await dio.post(
        '/files?uploadType=multipart',
        data: formData,
      );
      final data = response.data as Map<String, dynamic>;
      return CloudFile(
        id: data['id'] as String,
        name: data['name'] as String,
        path: remotePath,
        size: bytes.length,
        modifiedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<Either<Failure, String>> downloadFile({
    required String remotePath,
    required String localPath,
  }) async {
    if (_accessToken == null) {
      return const Left(UnauthorizedFailure(message: 'Not authenticated'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://www.googleapis.com/drive/v3',
        apiKey: _accessToken,
      );
      // First find file by name
      final list = await dio.get(
        '/files',
        queryParameters: {
          'q': "name='$remotePath' and trashed=false",
        },
      );
      final files = list.data['files'] as List;
      if (files.isEmpty) {
        throw const NotFoundFailure(message: 'Remote file not found');
      }
      final fileId = files.first['id'] as String;
      // Download content
      final response = await dio.get(
        '/files/$fileId',
        queryParameters: {'alt': 'media'},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data is List<int>
          ? response.data as List<int>
          : (response.data as String).codeUnits;
      final outFile = File(localPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(bytes);
      return localPath;
    });
  }

  @override
  Future<Either<Failure, void>> deleteFile(String remotePath) async {
    if (_accessToken == null) {
      return const Left(UnauthorizedFailure(message: 'Not authenticated'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://www.googleapis.com/drive/v3',
        apiKey: _accessToken,
      );
      final list = await dio.get(
        '/files',
        queryParameters: {
          'q': "name='$remotePath' and trashed=false",
        },
      );
      final files = list.data['files'] as List;
      if (files.isEmpty) {
        throw const NotFoundFailure(message: 'Remote file not found');
      }
      final fileId = files.first['id'] as String;
      await dio.delete('/files/$fileId');
      return;
    });
  }

  @override
  Future<Either<Failure, void>> createFolder(String path) async {
    if (_accessToken == null) {
      return const Left(UnauthorizedFailure(message: 'Not authenticated'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://www.googleapis.com/drive/v3',
        apiKey: _accessToken,
      );
      await dio.post(
        '/files',
        data: {
          'name': path,
          'mimeType': 'application/vnd.google-apps.folder',
        },
      );
      return;
    });
  }

  @override
  Future<void> signOut() async {
    _accessToken = null;
  }
}
