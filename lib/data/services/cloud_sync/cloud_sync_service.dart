// Cloud Sync Service - abstract interface for cloud storage providers
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';

abstract class CloudSyncService {
  String get providerId;
  String get displayName;
  String get authUrl;

  /// Authenticate with the cloud provider (returns access token).
  Future<Either<Failure, String>> authenticate();

  /// Check if currently authenticated.
  Future<bool> get isAuthenticated;

  /// List files in a remote directory.
  Future<Either<Failure, List<CloudFile>>> listFiles({
    String path = '/',
    int limit = 100,
  });

  /// Upload a file to the cloud.
  Future<Either<Failure, CloudFile>> uploadFile({
    required String localPath,
    required String remotePath,
  });

  /// Download a file from the cloud.
  Future<Either<Failure, String>> downloadFile({
    required String remotePath,
    required String localPath,
  });

  /// Delete a file from the cloud.
  Future<Either<Failure, void>> deleteFile(String remotePath);

  /// Create a folder.
  Future<Either<Failure, void>> createFolder(String path);

  /// Sign out and revoke tokens.
  Future<void> signOut();
}

class CloudFile {
  const CloudFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedAt,
    this.mimeType,
    this.isFolder = false,
    this.downloadUrl,
  });

  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime modifiedAt;
  final String? mimeType;
  final bool isFolder;
  final String? downloadUrl;
}
