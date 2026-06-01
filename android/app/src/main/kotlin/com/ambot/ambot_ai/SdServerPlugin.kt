package com.ambot.ambot_ai

import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class SdServerPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "SdServerPlugin"
        private const val CHANNEL = "com.ambot.ambot_ai/sd_server"
        private const val HEALTH_TIMEOUT_MS = 120000L
        private const val HEALTH_POLL_MS = 500L
        private const val PORT_POLL_TIMEOUT_MS = 120000L
        private const val PORT_FILE = "sd_server_port.txt"
    }

    private val executor = Executors.newSingleThreadExecutor()
    private var serverUrl: String? = null
    private val isRunning = java.util.concurrent.atomic.AtomicBoolean(false)
    private var startResult: MethodChannel.Result? = null
    private var modelPath: String? = null

    fun register(channel: MethodChannel) {
        channel.setMethodCallHandler(this)
        Log.d(TAG, "SdServerPlugin registered on channel $CHANNEL")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> handleStart(call, result)
            "stop" -> handleStop(call, result)
            "isRunning" -> result.success(isRunning.get())
            else -> result.notImplemented()
        }
    }

    private fun handleStart(call: MethodCall, result: MethodChannel.Result) {
        if (isRunning.get()) {
            result.success(mapOf("success" to true, "url" to serverUrl))
            return
        }

        val modelPath = call.argument<String>("modelPath") ?: run {
            result.error("INVALID_ARGS", "modelPath is required", null)
            return
        }

        startResult = result

        // Clean stale port file
        File(context.filesDir, PORT_FILE).delete()

        // Start service in separate process
        val intent = Intent(context, SdServerService::class.java).apply {
            putExtra("modelPath", modelPath)
        }
        context.startService(intent)

        // Poll for port file in background
        executor.execute {
            val portFile = File(context.filesDir, PORT_FILE)
            val startTime = System.currentTimeMillis()
            var port: Int? = null

            while (System.currentTimeMillis() - startTime < PORT_POLL_TIMEOUT_MS) {
                if (portFile.exists()) {
                    try {
                        port = portFile.readText().trim().toIntOrNull()
                        if (port != null && port > 0) break
                    } catch (_: Exception) {}
                }
                Thread.sleep(HEALTH_POLL_MS)
            }

            if (port != null) {
                val url = "http://127.0.0.1:$port"
                serverUrl = url
                Log.i(TAG, "Service reported port $port, checking health at $url")
                if (waitForHealth(url)) {
                    isRunning.set(true)
                    val r = startResult
                    startResult = null
                    r?.success(mapOf("success" to true, "url" to url))
                    Log.i(TAG, "sd-server started at $url with model $modelPath")
                } else {
                    context.stopService(Intent(context, SdServerService::class.java))
                    val r = startResult
                    startResult = null
                    r?.error("HEALTH_FAILED", "Server failed health check", null)
                }
            } else {
                context.stopService(Intent(context, SdServerService::class.java))
                val r = startResult
                startResult = null
                r?.error("START_FAILED", "Server did not report port within timeout", null)
            }
        }
    }

    private fun waitForHealth(baseUrl: String): Boolean {
        val healthUrl = URL("$baseUrl/sdcpp/v1/capabilities")
        val startTime = System.currentTimeMillis()

        while (System.currentTimeMillis() - startTime < HEALTH_TIMEOUT_MS) {
            try {
                val conn = healthUrl.openConnection() as HttpURLConnection
                conn.connectTimeout = 1000
                conn.readTimeout = 1000
                conn.requestMethod = "GET"
                val responseCode = conn.responseCode
                conn.disconnect()

                if (responseCode == 200) {
                    return true
                }
            } catch (_: Exception) {
            }

            Thread.sleep(HEALTH_POLL_MS)
        }

        return false
    }

    private fun handleStop(call: MethodCall, result: MethodChannel.Result) {
        stop()
        result.success(mapOf("success" to true))
    }

    private fun stop() {
        try {
            context.stopService(Intent(context, SdServerService::class.java))
        } catch (_: Exception) {}
        serverUrl = null
        isRunning.set(false)
        Log.d(TAG, "sd-server stopped")
    }

    fun dispose() {
        stop()
        executor.shutdown()
    }
}
