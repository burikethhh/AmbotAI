package com.ambot.ambot_ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import java.io.File
import java.net.ServerSocket
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * Runs the SD server in a separate process (:sdserver) to avoid
 * GPU driver conflicts with the Mali renderer in the main process.
 */
class SdServerService : Service() {

    companion object {
        private const val TAG = "SdServerService"
        private const val NOTIFICATION_CHANNEL = "sd-server"
        private const val NOTIFICATION_ID = 1
        private val started = AtomicBoolean(false)
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!started.compareAndSet(false, true)) {
            Log.i(TAG, "Server already started, ignoring duplicate onStartCommand")
            return START_STICKY
        }

        val modelPath = intent?.getStringExtra("modelPath") ?: run {
            Log.w(TAG, "No modelPath provided, stopping service")
            stopSelf()
            return START_NOT_STICKY
        }

        val extraArgs = intent?.getStringExtra("extraArgs") ?: ""

        Log.i(TAG, "Starting sd-server with model: $modelPath extraArgs: $extraArgs")

        // Foreground service to prevent idle kill during long generation
        val notification = buildNotification("Loading model\u2026")
        try {
            startForeground(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed (app backgrounded?)", e)
        }

        thread(name = "sd-server-init") {
            try {
                val port = findFreePort()
                Log.d(TAG, "Starting server on port $port")

                SdServerNative.nativeStartServer(modelPath, "127.0.0.1", port, true, extraArgs)

                // Write port to file for main process to discover
                val portFile = File(filesDir, "sd_server_port.txt")
                portFile.writeText(port.toString())
                Log.i(TAG, "Server started on port $port")

                // Update notification to show server is running
                val runningNotification = buildNotification("Running on port $port")
                (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
                    .notify(NOTIFICATION_ID, runningNotification)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start server", e)
                started.set(false)
                stopSelf()
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.i(TAG, "Shutting down sd-server")
        started.set(false)
        try {
            SdServerNative.nativeStopServer()
        } catch (_: Exception) {}
        try {
            File(filesDir, "sd_server_port.txt").delete()
        } catch (_: Exception) {}
        super.onDestroy()
    }

    private fun findFreePort(): Int {
        val socket = ServerSocket(0)
        val port = socket.localPort
        socket.close()
        return port
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL,
                "SD Server",
                NotificationManager.IMPORTANCE_LOW
            )
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    @Suppress("DEPRECATION")
    private fun buildNotification(text: String): Notification {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL)
                .setContentTitle("SD Server")
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_menu_gallery)
                .setOngoing(true)
                .build()
        } else {
            Notification.Builder(this)
                .setContentTitle("SD Server")
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_menu_gallery)
                .setOngoing(true)
                .build()
        }
    }
}
