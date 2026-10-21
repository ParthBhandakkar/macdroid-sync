import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/remote_file_entry.dart';

class RemoteFileService {
  // Returns safe starting directory paths for the host platform
  static Future<List<Map<String, String>>> getQuickAccessRoots() async {
    final list = <Map<String, String>>[];

    if (kIsWeb) {
      list.add({'name': 'Virtual Storage', 'path': '/virtual'});
      return list;
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        list.add({'name': 'Downloads', 'path': downloads.path});
      }
    } catch (_) {}

    try {
      final docs = await getApplicationDocumentsDirectory();
      list.add({'name': 'Documents', 'path': docs.path});
    } catch (_) {}

    try {
      if (Platform.isMacOS || Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          list.add({'name': 'Home', 'path': home});
          final desktop = p.join(home, 'Desktop');
          if (Directory(desktop).existsSync()) {
            list.add({'name': 'Desktop', 'path': desktop});
          }
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          list.add({'name': 'User Profile', 'path': userProfile});
          final desktop = p.join(userProfile, 'Desktop');
          if (Directory(desktop).existsSync()) {
            list.add({'name': 'Desktop', 'path': desktop});
          }
        }
      } else if (Platform.isAndroid) {
        list.add({'name': 'Internal Storage', 'path': '/storage/emulated/0'});
        list.add({'name': 'Downloads', 'path': '/storage/emulated/0/Download'});
        list.add({'name': 'DCIM (Photos)', 'path': '/storage/emulated/0/DCIM'});
      }
    } catch (_) {}

    if (list.isEmpty) {
      list.add({'name': 'Root', 'path': '/'});
    }

    return list;
  }

  // Lists files in the requested directory path on this local device
  static Future<List<RemoteFileEntry>> listDirectory(String targetPath) async {
    if (kIsWeb) {
      // Mock virtual browser for web demo/browser target
      return [
        RemoteFileEntry(
          name: 'Sample_Document.pdf',
          path: '/virtual/Sample_Document.pdf',
          isDirectory: false,
          size: 1024 * 350,
          modified: DateTime.now().subtract(const Duration(hours: 3)),
          mimeType: 'application/pdf',
        ),
        RemoteFileEntry(
          name: 'Camera',
          path: '/virtual/Camera',
          isDirectory: true,
          size: 0,
          modified: DateTime.now().subtract(const Duration(days: 1)),
          mimeType: 'inode/directory',
        ),
      ];
    }

    final dir = Directory(targetPath);
    if (!await dir.exists()) {
      return [];
    }

    final entries = <RemoteFileEntry>[];

    try {
      final list = dir.listSync(followLinks: false);
      for (final entity in list) {
        final name = p.basename(entity.path);
        // Skip common noisy OS hidden files
        if (name.startsWith('.') && name != '.macdroid') continue;
        if (name == 'Thumbs.db' || name == 'desktop.ini') continue;

        try {
          final stat = entity.statSync();
          final isDir = stat.type == FileSystemEntityType.directory;
          entries.add(RemoteFileEntry(
            name: name,
            path: entity.path,
            isDirectory: isDir,
            size: isDir ? 0 : stat.size,
            modified: stat.modified,
            mimeType: isDir ? 'inode/directory' : _inferMimeType(name),
          ));
        } catch (_) {
          // Skip inaccessible individual files
        }
      }

      // Sort: Directories first, then alphabetical
      entries.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    } catch (_) {
      // Return empty if permission denied
    }

    return entries;
  }

  static String _inferMimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.zip':
        return 'application/zip';
      case '.apk':
        return 'application/vnd.android.package-archive';
      default:
        return 'application/octet-stream';
    }
  }
}
