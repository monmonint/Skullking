import 'package:flutter_test/flutter_test.dart';
import 'package:skull_king_scorekeeper/update/version_compare.dart';

void main() {
  test('une release plus récente est détectée', () {
    expect(isNewerRelease('1.2.0', 'v1.3.0'), isTrue);
    expect(isNewerRelease('1.2.0+3', 'v1.3.0'), isTrue);
    expect(isNewerRelease('1.9.0', 'v1.10.0'), isTrue);
    expect(isNewerRelease('1.3', 'v1.3.1'), isTrue);
  });

  test(
    'la même version ou une plus ancienne ne déclenche pas de mise à jour',
    () {
      expect(isNewerRelease('1.3.0', 'v1.3.0'), isFalse);
      expect(isNewerRelease('1.3.0+4', 'v1.3.0'), isFalse);
      expect(isNewerRelease('1.4.0', 'v1.3.0'), isFalse);
      expect(isNewerRelease('1.3.0', ''), isFalse);
      expect(isNewerRelease('pas-une-version', 'v1.3.0'), isFalse);
    },
  );

  test('le tag affiché garde le préfixe v', () {
    expect(displayReleaseTag('v1.3.0'), 'v1.3.0');
    expect(displayReleaseTag('1.3.0'), 'v1.3.0');
  });

  test('arm64 préfère l\'APK arm64, les autres le fat', () {
    const assets = [
      ReleaseAsset(name: kFatApkName, downloadUrl: 'https://example/fat'),
      ReleaseAsset(name: kArm64ApkName, downloadUrl: 'https://example/arm64'),
      ReleaseAsset(name: 'notes.txt', downloadUrl: 'https://example/notes'),
    ];
    expect(
      chooseUpdateApk(assets, preferArm64: true)!.downloadUrl,
      'https://example/arm64',
    );
    expect(
      chooseUpdateApk(assets, preferArm64: false)!.downloadUrl,
      'https://example/fat',
    );
  });

  test('repli sur l\'autre APK si l\'asset préféré manque', () {
    const onlyFat = [
      ReleaseAsset(name: kFatApkName, downloadUrl: 'https://example/fat'),
    ];
    expect(chooseUpdateApk(onlyFat, preferArm64: true)!.name, kFatApkName);
    const onlyArm = [
      ReleaseAsset(name: kArm64ApkName, downloadUrl: 'https://example/arm64'),
    ];
    expect(chooseUpdateApk(onlyArm, preferArm64: false)!.name, kArm64ApkName);
    expect(chooseUpdateApk(const [], preferArm64: true), isNull);
  });

  test('le JSON GitHub fournit le tag comparé à la version installée', () {
    final release = GithubRelease.tryParse({
      'tag_name': 'v1.3.0',
      'body': 'Icône pirate.',
      'html_url': 'https://github.com/monmonint/Skullking/releases/tag/v1.3.0',
      'assets': [
        {
          'name': kArm64ApkName,
          'browser_download_url': 'https://example/arm64',
        },
        {'name': kFatApkName, 'browser_download_url': 'https://example/fat'},
      ],
    });
    expect(release, isNotNull);
    expect(isNewerRelease('1.2.0', release!.tagName), isTrue);
    expect(isNewerRelease('1.3.0', release.tagName), isFalse);
    expect(release.notes, 'Icône pirate.');
    expect(
      chooseUpdateApk(release.assets, preferArm64: true)!.name,
      kArm64ApkName,
    );
    expect(GithubRelease.tryParse({'body': 'sans tag'}), isNull);
  });
}
