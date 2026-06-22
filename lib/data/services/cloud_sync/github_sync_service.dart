// GitHub Sync Service - sync files to/from GitHub repositories
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import 'cloud_sync_service.dart';

class GitHubSyncService implements CloudSyncService {
  GitHubSyncService();

  String? _token;
  String? _username;
  String? _repo;

  void configure({
    required String token,
    required String username,
    required String repo,
  }) {
    _token = token;
    _username = username;
    _repo = repo;
  }

  @override
  String get providerId => 'github';

  @override
  String get displayName => 'GitHub';

  @override
  String get authUrl => 'https://github.com/login/oauth/authorize';

  @override
  Future<bool> get isAuthenticated => Future.value(_token != null);

  @override
  Future<Either<Failure, String>> authenticate() async {
    if (_token == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'GitHub token not configured. Generate one at '
              'github.com/settings/tokens with repo scope.',
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
    if (_token == null || _repo == null || _username == null) {
      return const Left(UnauthorizedFailure(message: 'GitHub not configured'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.github.com',
        apiKey: _token,
      );
      final response = await dio.get(
        '/repos/$_username/$_repo/contents$path',
      );
      final items = response.data as List;
      return items
          .map<CloudFile>(
            (item) => CloudFile(
              id: item['sha'] as String,
              name: item['name'] as String,
              path: item['path'] as String,
              size: (item['size'] as num).toInt(),
              modifiedAt: DateTime.now(),
              isFolder: item['type'] == 'dir',
              downloadUrl: item['download_url'] as String?,
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
    if (_token == null || _repo == null || _username == null) {
      return const Left(UnauthorizedFailure(message: 'GitHub not configured'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.github.com',
        apiKey: _token,
      );
      // Read file as base64
      final fileBytes = await _readFileBytes(localPath);
      final content = base64Encode(fileBytes);

      final response = await dio.put(
        '/repos/$_username/$_repo/contents/$remotePath',
        data: {
          'message': 'OmniForge AI sync: $remotePath',
          'content': content,
        },
      );
      final contentData = response.data['content'] as Map<String, dynamic>;
      return CloudFile(
        id: contentData['sha'] as String,
        name: contentData['name'] as String,
        path: contentData['path'] as String,
        size: (contentData['size'] as num).toInt(),
        modifiedAt: DateTime.now(),
        downloadUrl: contentData['download_url'] as String?,
      );
    });
  }

  @override
  Future<Either<Failure, String>> downloadFile({
    required String remotePath,
    required String localPath,
  }) async {
    if (_token == null || _repo == null || _username == null) {
      return const Left(UnauthorizedFailure(message: 'GitHub not configured'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.github.com',
        apiKey: _token,
      );
      final response = await dio.get(
        '/repos/$_username/$_repo/contents/$remotePath',
      );
      final content = response.data['content'] as String;
      final bytes = base64Decode(content);
      await _writeFileBytes(localPath, bytes);
      return localPath;
    });
  }

  @override
  Future<Either<Failure, void>> deleteFile(String remotePath) async {
    if (_token == null || _repo == null || _username == null) {
      return const Left(UnauthorizedFailure(message: 'GitHub not configured'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.github.com',
        apiKey: _token,
      );
      // Get the SHA first
      final info = await dio.get(
        '/repos/$_username/$_repo/contents/$remotePath',
      );
      final sha = info.data['sha'] as String;
      await dio.delete(
        '/repos/$_username/$_repo/contents/$remotePath',
        data: {
          'message': 'OmniForge AI sync: delete $remotePath',
          'sha': sha,
        },
      );
      return;
    });
  }

  @override
  Future<Either<Failure, void>> createFolder(String path) async {
    // GitHub has no first-class folders; create a .gitkeep sentinel file so
    // the directory is tracked in git.
    final tempDir = await Directory.systemTemp.createTemp('omniforge_gh_');
    final keepFile = File('${tempDir.path}/.gitkeep');
    await keepFile.writeAsString('');
    try {
      final result = await uploadFile(
        localPath: keepFile.path,
        remotePath: '$path/.gitkeep',
      );
      return result.map((_) {});
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        AppLogger.w('GitHub sync: temp dir cleanup failed: $e');
      }
    }
  }

  @override
  Future<void> signOut() async {
    _token = null;
    _username = null;
    _repo = null;
  }

  Future<List<int>> _readFileBytes(String path) async {
    if (path.isEmpty) {
      throw FileSystemException('Path is empty', path);
    }
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', path);
    }
    return file.readAsBytes();
  }

  Future<void> _writeFileBytes(String path, List<int> bytes) async {
    if (path.isEmpty) {
      throw FileSystemException('Path is empty', path);
    }
    final file = File(path);
    // Ensure parent directory exists.
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);
  }
}
