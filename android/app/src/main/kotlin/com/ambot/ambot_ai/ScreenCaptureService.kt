package com.ambot.ambot_ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

/**
 * Foreground service that captures the device screen using MediaProjection API.
 *
 * Requires:
 * - User granting MediaProjection permission via Intent from MainActivity
 * - FOREGROUND_SERVICE_MEDIA_PROJECTION permission (Android 14+)
 *
 * The service runs a persistent notification so the user knows the screen is being captured.
 */
class ScreenCaptureService : Service() {

    companion object {
        const val CHANNEL_ID = "ambot_screen_capture"
        const val NOTIFICATION_ID = 1001

        var instance: ScreenCaptureService? = null
            private set

        var mediaProjection: MediaProjection? = null
            private set

        private var virtualDisplay: VirtualDisplay? = null
        private var imageReader: ImageReader? = null

        fun setMediaProjection(projection: MediaProjection?) {
            mediaProjection = projection
        }

        fun captureScreenshot(): ByteArray? {
            val ir = imageReader ?: return null
            val image: Image = ir.acquireLatestImage() ?: return null
            try {
                val planes = image.planes
                val buffer: ByteBuffer = planes[0].buffer
                val pixelStride = planes[0].pixelStride
                val rowStride = planes[0].rowStride
                val rowPadding = rowStride - pixelStride * ir.width

                val bitmap = Bitmap.createBitmap(
                    ir.width + rowPadding / pixelStride,
                    ir.height,
                    Bitmap.Config.ARGB_8888
                )
                bitmap.copyPixelsFromBuffer(buffer)

                // Crop to actual width
                val cropped = Bitmap.createBitmap(bitmap, 0, 0, ir.width, ir.height)
                bitmap.recycle()

                val stream = ByteArrayOutputStream()
                cropped.compress(Bitmap.CompressFormat.PNG, 90, stream)
                cropped.recycle()
                return stream.toByteArray()
            } finally {
                image.close()
            }
        }
    }

    private var displayWidth = 0
    private var displayHeight = 0

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)

        val resultCode = intent?.getIntExtra("result_code", 0) ?: 0
        val data = intent?.getParcelableExtra<Intent>("data")

        if (resultCode != 0 && data != null) {
            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = projectionManager.getMediaProjection(resultCode, data)
            mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    stopSelf()
                }
            }, null)
            startCapture()
        }

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        instance = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.screen_capture_notification_title),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.screen_capture_notification_text)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle(getString(R.string.screen_capture_notification_title))
                .setContentText(getString(R.string.screen_capture_notification_text))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle(getString(R.string.screen_capture_notification_title))
                .setContentText(getString(R.string.screen_capture_notification_text))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build()
        }
    }

    private fun startCapture() {
        val projection = mediaProjection ?: return
        val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

        // Get display metrics
        val display = displayManager.getDisplay(0)
        displayWidth = display.width
        displayHeight = display.height

        imageReader = ImageReader.newInstance(displayWidth, displayHeight, PixelFormat.RGBA_8888, 2)

        virtualDisplay = projection.createVirtualDisplay(
            "AmbotScreenCapture",
            displayWidth,
            displayHeight,
            1, // density
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader!!.surface,
            null,
            null
        )
    }
}
