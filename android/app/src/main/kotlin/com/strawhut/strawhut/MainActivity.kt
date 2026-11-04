package com.strawhut.strawhut

import android.content.ContentResolver
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.strawhut.strawhut/file_saver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(CryptoPlugin())
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val fileName = call.argument<String>("fileName") ?: run {
                        result.error("INVALID_ARGS", "fileName is required", null)
                        return@setMethodCallHandler
                    }
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    val bytes = call.argument<ByteArray>("bytes") ?: run {
                        result.error("INVALID_ARGS", "bytes are required", null)
                        return@setMethodCallHandler
                    }
                    val uri = saveToDownloads(fileName, mimeType, bytes)
                    if (uri != null) {
                        result.success(uri.toString())
                    } else {
                        result.error("SAVE_FAILED", "Failed to save file to Downloads", null)
                    }
                }
                "saveToPictures" -> {
                    val fileName = call.argument<String>("fileName") ?: run {
                        result.error("INVALID_ARGS", "fileName is required", null)
                        return@setMethodCallHandler
                    }
                    val bytes = call.argument<ByteArray>("bytes") ?: run {
                        result.error("INVALID_ARGS", "bytes are required", null)
                        return@setMethodCallHandler
                    }
                    val uri = saveToPictures(fileName, bytes)
                    if (uri != null) {
                        result.success(uri.toString())
                    } else {
                        result.error("SAVE_FAILED", "Failed to save file to Pictures", null)
                    }
                }
                "saveMediaToAlbum" -> {
                    val fileName = call.argument<String>("fileName") ?: run {
                        result.error("INVALID_ARGS", "fileName is required", null)
                        return@setMethodCallHandler
                    }
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    val bytes = call.argument<ByteArray>("bytes") ?: run {
                        result.error("INVALID_ARGS", "bytes are required", null)
                        return@setMethodCallHandler
                    }
                    val uri = saveMediaToAlbum(fileName, mimeType, bytes)
                    if (uri != null) {
                        result.success(uri.toString())
                    } else {
                        result.error("SAVE_FAILED", "Failed to save media to album", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(fileName: String, mimeType: String, bytes: ByteArray): Uri? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Files.getContentUri("external"), contentValues)
            return writeToMediaStore(resolver, uri, bytes)
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val file = File(downloadsDir, File(fileName).name)
            try {
                FileOutputStream(file).use { it.write(bytes) }
                return Uri.fromFile(file)
            } catch (e: Exception) {
                e.printStackTrace()
                return null
            }
        }
    }

    private fun saveToPictures(fileName: String, bytes: ByteArray): Uri? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
            return writeToMediaStore(resolver, uri, bytes)
        } else {
            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val file = File(picturesDir, File(fileName).name)
            try {
                FileOutputStream(file).use { it.write(bytes) }
                return Uri.fromFile(file)
            } catch (e: Exception) {
                e.printStackTrace()
                return null
            }
        }
    }

    private fun saveMediaToAlbum(fileName: String, mimeType: String, bytes: ByteArray): Uri? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentUri: Uri
            val relativePath: String
            when {
                mimeType.startsWith("image/") -> {
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    relativePath = Environment.DIRECTORY_PICTURES
                }
                mimeType.startsWith("video/") -> {
                    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    relativePath = Environment.DIRECTORY_MOVIES
                }
                mimeType.startsWith("audio/") -> {
                    contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                    relativePath = Environment.DIRECTORY_MUSIC
                }
                else -> {
                    contentUri = MediaStore.Files.getContentUri("external")
                    relativePath = Environment.DIRECTORY_DOWNLOADS
                }
            }
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(contentUri, contentValues)
            return writeToMediaStore(resolver, uri, bytes)
        } else {
            val dir = when {
                mimeType.startsWith("image/") -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                mimeType.startsWith("video/") -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
                mimeType.startsWith("audio/") -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
                else -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            }
            val file = File(dir, File(fileName).name)
            try {
                FileOutputStream(file).use { it.write(bytes) }
                return Uri.fromFile(file)
            } catch (e: Exception) {
                e.printStackTrace()
                return null
            }
        }
    }

    /**
     * 向 MediaStore 中已插入（IS_PENDING=1）的条目写入数据并发布。
     *
     * - insert 失败（uri 为 null）时返回 null。
     * - openOutputStream 返回 null 时视为失败（此前会对空文件报告成功）。
     * - 任一步骤失败都会删除该条目，避免留下空的 pending 记录；
     *   否则 Dart 端随后执行回退保存，一次保存会产生两份文件。
     */
    private fun writeToMediaStore(resolver: ContentResolver, uri: Uri?, bytes: ByteArray): Uri? {
        if (uri == null) return null
        return try {
            val stream = resolver.openOutputStream(uri)
                ?: throw IOException("openOutputStream returned null for $uri")
            stream.use { it.write(bytes) }
            val published = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, published, null, null)
            uri
        } catch (e: Exception) {
            e.printStackTrace()
            try {
                resolver.delete(uri, null, null)
            } catch (ignored: Exception) {
                // 清理失败不影响返回结果
            }
            null
        }
    }
}
