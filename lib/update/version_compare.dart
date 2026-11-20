/// Comparaison de versions et choix de l'APK GitHub.
///
/// Les fichiers publiés gardent des noms stables :
/// [kArm64ApkName] et [kFatApkName].
library;

const String kArm64ApkName = 'skull-king-scorekeeper-arm64-release.apk';
const String kFatApkName = 'skull-king-scorekeeper-fat-release.apk';

const String kGithubLatestReleaseUrl =
    'https://api.github.com/repos/monmonint/Skullking/releases/latest';

class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;

  const AppVersion(this.major, this.minor, this.patch);

  /// Lit `1.2.3`, `v1.2.3` ou `1.2.3+4`. Le suffixe de build est ignoré.
  static AppVersion? tryParse(String raw) {
    final match = RegExp(r'(\d+)\.(\d+)(?:\.(\d+))?').firstMatch(raw.trim());
    if (match == null) return null;
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3) ?? '0'),
    );
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// Vrai si [tagName] (ex. `v1.3.0`) est strictement plus récent que la
/// version installée (ex. `1.2.0`).
bool isNewerRelease(String installedVersion, String tagName) {
  final installed = AppVersion.tryParse(installedVersion);
  final remote = AppVersion.tryParse(tagName);
  if (installed == null || remote == null) return false;
  return remote.compareTo(installed) > 0;
}

/// Affiche le tag avec un `v` devant, comme dans le dialogue.
String displayReleaseTag(String tagName) {
  final trimmed = tagName.trim();
  if (trimmed.isEmpty) return '';
  final version = AppVersion.tryParse(trimmed);
  if (version == null) {
    return trimmed.startsWith('v') || trimmed.startsWith('V')
        ? trimmed
        : 'v$trimmed';
  }
  return 'v$version';
}

class ReleaseAsset {
  final String name;
  final String downloadUrl;

  const ReleaseAsset({required this.name, required this.downloadUrl});
}

class GithubRelease {
  final String tagName;
  final String notes;
  final String pageUrl;
  final List<ReleaseAsset> assets;

  const GithubRelease({
    required this.tagName,
    required this.notes,
    required this.pageUrl,
    required this.assets,
  });

  static GithubRelease? tryParse(Object? decoded) {
    if (decoded is! Map) return null;
    final tag = decoded['tag_name'];
    if (tag is! String || tag.trim().isEmpty) return null;
    final notes = decoded['body'];
    final page = decoded['html_url'];
    final rawAssets = decoded['assets'];
    final assets = <ReleaseAsset>[];
    if (rawAssets is List) {
      for (final item in rawAssets) {
        if (item is! Map) continue;
        final name = item['name'];
        final url = item['browser_download_url'];
        if (name is String &&
            url is String &&
            name.isNotEmpty &&
            url.isNotEmpty) {
          assets.add(ReleaseAsset(name: name, downloadUrl: url));
        }
      }
    }
    return GithubRelease(
      tagName: tag.trim(),
      notes: notes is String ? notes.trim() : '',
      pageUrl: page is String ? page : '',
      assets: assets,
    );
  }
}

/// Sur un appareil arm64, l'APK arm64 ; sinon le fat. Repli sur l'autre
/// fichier si l'asset préféré manque.
ReleaseAsset? chooseUpdateApk(
  List<ReleaseAsset> assets, {
  required bool preferArm64,
}) {
  ReleaseAsset? named(String name) {
    for (final asset in assets) {
      if (asset.name == name) return asset;
    }
    return null;
  }

  final arm64 = named(kArm64ApkName);
  final fat = named(kFatApkName);
  if (preferArm64) return arm64 ?? fat;
  return fat ?? arm64;
}
