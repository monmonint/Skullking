package fr.remi.skull_king_scorekeeper

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "fr.remi.skullkingscore/updater",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isArm64" -> {
                    val arm64 = Build.SUPPORTED_ABIS.any { it.contains("arm64") }
                    result.success(arm64)
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.success("failed")
                    } else {
                        result.success(installApk(path))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(path: String): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !packageManager.canRequestPackageInstalls()
            ) {
                val settings = Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(settings)
                "needs_permission"
            } else {
                val file = File(path)
                val uri = FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file,
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                "started"
            }
        } catch (_: Exception) {
            "failed"
        }
    }
}
