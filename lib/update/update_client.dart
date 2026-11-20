import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'version_compare.dart';

enum InstallOutcome { started, needsPermission, failed }

class ApkInstaller {
  static const _channel = MethodChannel('fr.remi.skullkingscore/updater');

  static Future<bool> preferArm64() async {
    try {
      final value = await _channel.invokeMethod<bool>('isArm64');
      return value ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<InstallOutcome> install(String path) async {
    try {
      final value = await _channel.invokeMethod<String>('installApk', {
        'path': path,
      });
      switch (value) {
        case 'started':
          return InstallOutcome.started;
        case 'needs_permission':
          return InstallOutcome.needsPermission;
        default:
          return InstallOutcome.failed;
      }
    } catch (_) {
      return InstallOutcome.failed;
    }
  }
}

/// `null` si hors ligne, limité, ou réponse illisible. Pas d'exception.
Future<GithubRelease?> fetchLatestRelease() async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(Uri.parse(kGithubLatestReleaseUrl));
    request.headers.set(HttpHeaders.userAgentHeader, 'SkullKingScorekeeper');
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );
    final response = await request.close().timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      await response.drain<void>();
      return null;
    }
    final body = await response.transform(utf8.decoder).join();
    return GithubRelease.tryParse(jsonDecode(body));
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// Télécharge l'APK dans le cache. [onProgress] reçoit 0..1, ou null si la
/// taille est inconnue. `null` si le téléchargement échoue.
Future<File?> downloadReleaseApk(
  String url,
  void Function(double? progress) onProgress,
) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 12);
  IOSink? sink;
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.userAgentHeader, 'SkullKingScorekeeper');
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      await response.drain<void>();
      return null;
    }
    final total = response.contentLength;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/skull-king-update.apk');
    sink = file.openWrite();
    var received = 0;
    onProgress(total > 0 ? 0 : null);
    await for (final chunk in response) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress(received / total);
    }
    await sink.flush();
    await sink.close();
    sink = null;
    onProgress(1);
    return file;
  } catch (_) {
    return null;
  } finally {
    if (sink != null) {
      try {
        await sink.close();
      } catch (_) {}
    }
    client.close(force: true);
  }
}
