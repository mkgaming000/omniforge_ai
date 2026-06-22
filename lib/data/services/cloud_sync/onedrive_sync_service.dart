// OneDrive Sync Service
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import 'cloud_sync_service.dart';

class OneDriveSyncService implements CloudSyncService {
  OneDriveSyncService();
  String? _accessToken;

  void setAccessToken(String token) => _accessToken = token;

  @override
  String get providerId => 'onedrive';

  @override
  String get displayName => 'OneDrive';

  @override
  String get authUrl =>
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';

  @override
  Future<bool> get isAuthenticated => Future.value(_accessToken != null);

  @override
  Future<Either<Failure, String>> authenticate() async {
    if (_accessToken == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'OneDrive requires Microsoft OAuth. Configure in Settings.',
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
        baseUrl: 'https://graph.microsoft.com/v1.0/me',
        apiKey: _accessToken,
      );
      final response = await dio.get(
        '/drive/root${path == '/' ? '' : ':/$path'}:/children',
      );
      final items = response.data['value'] as List;
      return items
          .map<CloudFile>(
            (item) => CloudFile(
              id: item['id'] as String,
              name: item['name'] as String,
              path: item['parentReference']?['path'] as String? ?? '/',
              size: (item['size'] as num?)?.toInt() ?? 0,
              modifiedAt: DateTime.tryParse(
                    item['lastModifiedDateTime'] as String? ?? '',
                  ) ??
                  DateTime.now(),
              isFolder: item.containsKey('folder') as bool,
            ),
          )
          .take(limit)
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
      final dio = DioClient.create(
        baseUrl: 'https://graph.microsoft.com/v1.0/me',
        apiKey: _accessToken,
      );
      final bytes = await File(localPath).readAsBytes();
      final encoded = Uri.encodeComponent(remotePath);
      final response = await dio.put(
        '/drive/root:/$encoded:/content',
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': bytes.length,
          },
        ),
      );
      final data = response.data as Map<String, dynamic>;
      return CloudFile(
        id: data['id'] as String,
        name: data['name'] as String? ?? remotePath.split('/').last,
        path: remotePath,
        size: (data['size'] as num?)?.toInt() ?? bytes.length,
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
        baseUrl: 'https://graph.microsoft.com/v1.0/me',
        apiKey: _accessToken,
      );
      final encoded = Uri.encodeComponent(remotePath);
      final response = await dio.get(
        '/drive/root:/$encoded:/content',
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
        baseUrl: 'https://graph.microsoft.com/v1.0/me',
        apiKey: _accessToken,
      );
      await dio.delete('/drive/root:/$remotePath');
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
        baseUrl: 'https://graph.microsoft.com/v1.0/me',
        apiKey: _accessToken,
      );
      await dio.post(
        '/drive/root/children',
        data: {
          'name': path,
          'folder': {},
          '@microsoft.graph.conflictBehavior': 'rename',
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
