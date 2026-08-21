package com.lateinlabs.swediscover

import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {
    private var logWriter: FileWriter? = null
    private val logFile: File by lazy {
        File(filesDir, "logcat.log")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        startLogcatStreaming()
    }

    override fun onDestroy() {
        stopLogcatStreaming()
        super.onDestroy()
    }

    private fun startLogcatStreaming() {
        try {
            logWriter = FileWriter(logFile, true) // Append mode
            logWriter?.append("=== Logcat streaming started at ${getCurrentTimestamp()} ===\n")
            
            // Start logcat process in background thread
            Thread {
                try {
                    // Filter for our app and important system tags
                    val processBuilder = ProcessBuilder(
                        "logcat", 
                        "-v", "time",
                        "*:V" // All logs with verbose level
                    )
                    val logcatProcess = processBuilder.start()
                    
                    val bufferedReader = logcatProcess.inputStream.bufferedReader()
                    var line: String?
                    val writer = logWriter

                    while (bufferedReader.readLine().also { line = it } != null) {
                        if (writer != null) {
                            writer.append(line)
                            writer.append("\n")
                            writer.flush()
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading logcat stream", e)
                    logWriter?.append("Error: ${e.message}\n")
                }
            }.apply {
                isDaemon = true
                start()
            }
            
            Log.i(TAG, "Logcat streaming started to ${logFile.absolutePath}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start logcat streaming", e)
        }
    }

    private fun stopLogcatStreaming() {
        try {
            logWriter?.append("=== Logcat streaming stopped at ${getCurrentTimestamp()} ===\n\n")
            logWriter?.close()
            logWriter = null
            Log.i(TAG, "Logcat streaming stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping logcat streaming", e)
        }
    }

    private fun getCurrentTimestamp(): String {
        return SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
    }

    companion object {
        private const val TAG = "MainActivity"
        
        // Method to copy log file to external storage for easy access
        fun copyLogFileToExternalStorage(activity: MainActivity) {
            try {
                val externalLog = File(activity.getExternalFilesDir(null), "swediscover_logcat.log")
                activity.logFile.copyTo(externalLog, overwrite = true)
                Log.i(TAG, "Log file copied to ${externalLog.absolutePath}")
            } catch (e: Exception) {
                Log.e(TAG, "Error copying log file", e)
            }
        }
    }
}
