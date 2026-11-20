import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'update_client.dart';
import 'version_compare.dart';

/// Enveloppe l'application pour activer la vérification au lancement.
class UpdateLaunch extends InheritedWidget {
  final bool enabled;

  const UpdateLaunch({super.key, required this.enabled, required super.child});

  static bool enabledOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UpdateLaunch>();
    return scope?.enabled ?? false;
  }

  @override
  bool updateShouldNotify(UpdateLaunch oldWidget) =>
      enabled != oldWidget.enabled;
}

/// Vérifie GitHub. Silencieux hors ligne ou si l'API refuse.
/// [manual] affiche « déjà à jour » quand la requête aboutit sans nouveauté.
Future<void> checkForAppUpdate(
  BuildContext context, {
  required bool manual,
}) async {
  final release = await fetchLatestRelease();
  if (!context.mounted || release == null) return;
  final installed = await _installedVersion();
  if (!context.mounted || installed == null) return;
  if (!isNewerRelease(installed, release.tagName)) {
    if (manual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez déjà la dernière version.')),
      );
    }
    return;
  }
  final preferArm64 = await ApkInstaller.preferArm64();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) =>
        _UpdateDialog(release: release, preferArm64: preferArm64),
  );
}

Future<String?> _installedVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    if (version.isEmpty) return null;
    return version;
  } catch (_) {
    return null;
  }
}

class _UpdateDialog extends StatefulWidget {
  final GithubRelease release;
  final bool preferArm64;

  const _UpdateDialog({required this.release, required this.preferArm64});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _busy = false;
  double? _progress;
  String? _status;

  Future<void> _openPage() async {
    final url = widget.release.pageUrl.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _update() async {
    final asset = chooseUpdateApk(
      widget.release.assets,
      preferArm64: widget.preferArm64,
    );
    if (asset == null) {
      await _openPage();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
      _progress = null;
      _status = 'Téléchargement…';
    });
    final file = await downloadReleaseApk(asset.downloadUrl, (value) {
      if (!mounted) return;
      setState(() => _progress = value);
    });
    if (!mounted) return;
    if (file == null) {
      await _openPage();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _status = 'Installation…');
    final outcome = await ApkInstaller.install(file.path);
    if (!mounted) return;
    switch (outcome) {
      case InstallOutcome.started:
        Navigator.of(context).pop();
      case InstallOutcome.needsPermission:
        setState(() {
          _busy = false;
          _status =
              'Autorisez l\'installation des applications inconnues, puis touchez à nouveau Mettre à jour.';
        });
      case InstallOutcome.failed:
        await _openPage();
        if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag = displayReleaseTag(widget.release.tagName);
    final notes = widget.release.notes.trim().isEmpty
        ? 'Notes de version indisponibles.'
        : widget.release.notes.trim();
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text('Nouvelle version $tag disponible'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Text(
                  notes,
                  style: const TextStyle(color: AppTheme.muted, height: 1.35),
                ),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                _progress == null
                    ? (_status ?? 'Téléchargement…')
                    : '${_status ?? 'Téléchargement…'} ${(_progress! * 100).round()} %',
                style: const TextStyle(fontSize: 13),
              ),
            ] else if (_status != null) ...[
              const SizedBox(height: 12),
              Text(
                _status!,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Plus tard'),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _update,
          child: const Text('Mettre à jour'),
        ),
      ],
    );
  }
}
