// Dropbox Sync Service
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import 'cloud_sync_service.dart';

class DropboxSyncService implements CloudSyncService {
  DropboxSyncService();
  String? _accessToken;

  void setAccessToken(String token) => _accessToken = token;

  @override
  String get providerId => 'dropbox';

  @override
  String get displayName => 'Dropbox';

  @override
  String get authUrl => 'https://www.dropbox.com/oauth2/authorize';

  @override
  Future<bool> get isAuthenticated => Future.value(_accessToken != null);

  @override
  Future<Either<Failure, String>> authenticate() async {
    if (_accessToken == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'Dropbox requires OAuth. Configure in Settings.',
        ),
      );
    }
    return Right(_accessToken!);
  }

  @override
  Future<Either<Failure, List<CloudFile>>> listFiles({
    String path = '',
    int limit = 100,
  }) async {
    if (_accessToken == null) {
      return const Left(UnauthorizedFailure(message: 'Not authenticated'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.dropboxapi.com/2',
        apiKey: _accessToken,
      );
      final response = await dio.post(
        '/files/list_folder',
        data: {'path': path.isEmpty ? '' : path, 'limit': limit},
      );
      final entries = response.data['entries'] as List;
      return entries
          .map<CloudFile>(
            (e) => CloudFile(
              id: e['id'] as String,
              name: e['name'] as String,
              path: e['path_display'] as String,
              size: (e['size'] as num?)?.toInt() ?? 0,
              modifiedAt:
                  DateTime.tryParse(e['server_modified'] as String? ?? '') ??
                      DateTime.now(),
              isFolder: e['.tag'] == 'folder',
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
      final file = File(localPath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', localPath);
      }
      final bytes = await file.readAsBytes();
      final dio = DioClient.create(
        baseUrl: 'https://content.dropboxapi.com/2',
        apiKey: _accessToken,
      );
      // Dropbox-API-arg must be JSON-encoded with strict escaping.
      final arg = jsonEncode({
        'path': remotePath,
        'mode': 'overwrite',
        'autorename': false,
        'mute': true,
      });
      dio.options.headers['Dropbox-API-arg'] = arg;
      dio.options.headers['Content-Type'] = 'application/octet-stream';
      final response = await dio.post(
        '/files/upload',
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Length': bytes.length,
          },
          responseType: ResponseType.json,
        ),
      );
      final data = response.data as Map<String, dynamic>;
      return CloudFile(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? remotePath.split('/').last,
        path: data['path_display'] as String? ?? remotePath,
        size: (data['size'] as num?)?.toInt() ?? bytes.length,
        modifiedAt:
            DateTime.tryParse(data['server_modified'] as String? ?? '') ??
                DateTime.now(),
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
        baseUrl: 'https://content.dropboxapi.com/2',
        apiKey: _accessToken,
      );
      dio.options.headers['Dropbox-API-arg'] = jsonEncode({'path': remotePath});
      final response = await dio.post(
        '/files/download',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data as List<int>;
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
        baseUrl: 'https://api.dropboxapi.com/2',
        apiKey: _accessToken,
      );
      await dio.post('/files/delete_v2', data: {'path': remotePath});
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
        baseUrl: 'https://api.dropboxapi.com/2',
        apiKey: _accessToken,
      );
      await dio.post('/files/create_folder_v2', data: {'path': path});
      return;
    });
  }

  @override
  Future<void> signOut() async {
    _accessToken = null;
  }
}
