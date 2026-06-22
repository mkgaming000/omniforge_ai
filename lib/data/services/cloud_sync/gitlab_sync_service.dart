// GitLab Sync Service
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import 'cloud_sync_service.dart';

class GitLabSyncService implements CloudSyncService {
  GitLabSyncService();
  String? _token;
  int? _projectId;

  void configure({required String token, required int projectId}) {
    _token = token;
    _projectId = projectId;
  }

  @override
  String get providerId => 'gitlab';

  @override
  String get displayName => 'GitLab';

  @override
  String get authUrl => 'https://gitlab.com/oauth/authorize';

  @override
  Future<bool> get isAuthenticated =>
      Future.value(_token != null && _projectId != null);

  @override
  Future<Either<Failure, String>> authenticate() async {
    if (_token == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'GitLab token not configured. Generate at '
              'gitlab.com/-/profile/personal_access_tokens',
        ),
      );
    }
    return Right(_token!);
  }

  @override
  Future<Either<Failure, List<CloudFile>>> listFiles({
    String path = '/',
    int limit = 100,
  }) async {
    if (_token == null || _projectId == null) {
      return const Left(UnauthorizedFailure(message: 'GitLab not configured'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://gitlab.com/api/v4',
        apiKey: _token,
      );
      final response = await dio.get(
        '/projects/$_projectId/repository/tree',
        queryParameters: {'path': path, 'per_page': limit},
      );
      final items = response.data as List;
      return items
          .map<CloudFile>(
            (item) => CloudFile(
              id: item['id'] as String,
              name: item['name'] as String,
              path: item['path'] as String,
              size: 0,
              modifiedAt: DateTime.now(),
              isFolder: item['type'] == 'tree',
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
    if (_token == null || _projectId == null) {
      return const Left(UnauthorizedFailure(message: 'GitLab not configured'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://gitlab.com/api/v4',
        apiKey: _token,
      );
      final bytes = await File(localPath).readAsBytes();
      final encoded = Uri.encodeComponent(remotePath);
      final fileName = remotePath.split('/').last;
      final response = await dio.post(
        '/projects/$_projectId/repository/files/$encoded',
        data: {
          'branch': 'main',
          'content': base64Encode(bytes),
          'encoding': 'base64',
          'commit_message': 'OmniForge AI sync: upload $remotePath',
        },
      );
      final data = response.data as Map<String, dynamic>;
      // GitLab's repository-files API returns the committed file_path
      // (the closest thing to a stable id) plus the blob content. We use
      // file_path as the CloudFile id when no numeric id is present.
      final id = (data['id'] ?? data['file_path'] ?? remotePath).toString();
      return CloudFile(
        id: id,
        name: fileName,
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
    if (_token == null || _projectId == null) {
      return const Left(UnauthorizedFailure(message: 'GitLab not configured'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://gitlab.com/api/v4',
        apiKey: _token,
      );
      final encoded = Uri.encodeComponent(remotePath);
      final response = await dio.get(
        '/projects/$_projectId/repository/files/$encoded/raw',
        queryParameters: {'ref': 'main'},
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
    if (_token == null || _projectId == null) {
      return const Left(UnauthorizedFailure(message: 'GitLab not configured'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://gitlab.com/api/v4',
        apiKey: _token,
      );
      final encoded = Uri.encodeComponent(remotePath);
      await dio.delete(
        '/projects/$_projectId/repository/files/$encoded',
        queryParameters: {
          'branch': 'main',
          'commit_message': 'OmniForge AI sync: delete $remotePath',
        },
      );
      return;
    });
  }

  @override
  Future<Either<Failure, void>> createFolder(String path) async {
    if (_token == null || _projectId == null) {
      return const Left(UnauthorizedFailure(message: 'GitLab not configured'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://gitlab.com/api/v4',
        apiKey: _token,
      );
      // GitLab doesn't have a "create folder" endpoint; the convention is
      // to commit a `.gitkeep` file at the desired path.
      final remotePath = '$path/.gitkeep';
      final encoded = Uri.encodeComponent(remotePath);
      await dio.post(
        '/projects/$_projectId/repository/files/$encoded',
        data: {
          'branch': 'main',
          'content': '',
          'encoding': 'base64',
          'commit_message': 'OmniForge AI sync: create folder $path',
        },
      );
      return;
    });
  }

  @override
  Future<void> signOut() async {
    _token = null;
    _projectId = null;
  }
}
