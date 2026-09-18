package com.fryd.fryd

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "com.fryd.fryd/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    result.error(
                        "UNSUPPORTED_ANDROID_VERSION",
                        "Saving reports to public Downloads requires Android 10 or newer.",
                        null,
                    )
                    return@setMethodCallHandler
                }

                val fileName = call.argument<String>("fileName")
                val mimeType = call.argument<String>("mimeType")
                val bytes = call.argument<ByteArray>("bytes")
                if (fileName.isNullOrBlank() || mimeType.isNullOrBlank() || bytes == null) {
                    result.error("INVALID_FILE", "Report file data is incomplete.", null)
                    return@setMethodCallHandler
                }

                try {
                    val values = ContentValues().apply {
                        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                        put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                        put(
                            MediaStore.MediaColumns.RELATIVE_PATH,
                            Environment.DIRECTORY_DOWNLOADS,
                        )
                        put(MediaStore.MediaColumns.IS_PENDING, 1)
                    }
                    val resolver = applicationContext.contentResolver
                    val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                        ?: throw IllegalStateException("Downloads file could not be created.")
                    try {
                        resolver.openOutputStream(uri)?.use { it.write(bytes) }
                            ?: throw IllegalStateException("Downloads file could not be opened.")
                        values.clear()
                        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                        resolver.update(uri, values, null, null)
                        result.success("Downloads/$fileName")
                    } catch (error: Exception) {
                        resolver.delete(uri, null, null)
                        throw error
                    }
                } catch (error: Exception) {
                    result.error("SAVE_FAILED", error.message, null)
                }
            }
    }
}
