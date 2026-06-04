package com.ambot.ambot_ai

import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "ambot_ai/device_control"
    private val CAPTURE_CHANNEL = "ambot_ai/screen_capture"
    private val VOICE_CHANNEL = "ambot_ai/voice"
    private val VOICE_GEN_CHANNEL = "com.ambot.ambot_ai/voice_gen"
    private val AUDIO_PLAYBACK_CHANNEL = "com.ambot.ambot_ai/audio_playback"
    private val CAPTURE_REQUEST_CODE = 1001

    private var methodChannel: MethodChannel? = null
    private var captureResultCallback: MethodChannel.Result? = null
    private var voiceService: AmbotVoiceService? = null
    private var voiceGenService: VoiceGenService? = null
    private var sdServerPlugin: SdServerPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Device control channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        AmbotAccessibilityService.setMethodChannel(methodChannel)

        methodChannel?.setMethodCallHandler { call, result ->
            val args = call.arguments as? Map<*, *>
            AmbotAccessibilityService.instance?.handleMethodCall(call.method, args, result)
                ?: handleFallbackMethodCall(call.method, args, result)
        }

        // Screen capture channel
        val captureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAPTURE_CHANNEL)
        captureChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startCapture" -> startScreenCapture(result)
                "captureScreenshot" -> captureScreenshot(result)
                "stopCapture" -> stopScreenCapture(result)
                else -> result.notImplemented()
            }
        }

        // Voice channel
        val voiceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_CHANNEL)
        voiceService = AmbotVoiceService(this, voiceChannel)
        voiceService?.initialize()

        voiceChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    voiceService?.initialize()
                    result.success(null)
                }
                "isSpeechAvailable" -> result.success(voiceService?.isSpeechAvailable() ?: false)
                "isTtsAvailable" -> result.success(voiceService?.isTtsAvailable() ?: false)
                "isSpeaking" -> result.success(voiceService?.isSpeaking() ?: false)
                "startListening" -> {
                    val args = call.arguments as? Map<*, *>
                    voiceService?.startListening(
                        continuous = args?.get("continuous") as? Boolean ?: false,
                        language = args?.get("language") as? String,
                        offlineOnly = args?.get("offlineOnly") as? Boolean ?: false
                    )
                    result.success(null)
                }
                "stopListening" -> {
                    voiceService?.stopListening()
                    result.success(null)
                }
                "cancelListening" -> {
                    voiceService?.cancelListening()
                    result.success(null)
                }
                "speak" -> {
                    val args = call.arguments as? Map<*, *>
                    voiceService?.speak(
                        text = args?.get("text") as? String ?: "",
                        rate = (args?.get("rate") as? Number)?.toFloat(),
                        pitch = (args?.get("pitch") as? Number)?.toFloat()
                    )
                    result.success(null)
                }
                "stopSpeaking" -> {
                    voiceService?.stopSpeaking()
                    result.success(null)
                }
                "applySettings" -> {
                    val args = call.arguments as? Map<*, *>
                    voiceService?.applySettings(
                        language = args?.get("language") as? String,
                        rate = (args?.get("speechRate") as? Number)?.toFloat(),
                        pitch = (args?.get("pitch") as? Number)?.toFloat(),
                        offlineOnly = args?.get("offlineOnly") as? Boolean ?: false
                    )
                    result.success(null)
                }
                "dispose" -> {
                    voiceService?.shutdown()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Local image generation — subprocess HTTP server
        sdServerPlugin = SdServerPlugin(this)
        val sdServerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ambot.ambot_ai/sd_server")
        sdServerPlugin?.register(sdServerChannel)

        // Voice generation channel (Piper TTS / Android TTS fallback)
        voiceGenService = VoiceGenService(this)
        val voiceGenChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_GEN_CHANNEL)
        voiceGenChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "synthesize" -> {
                    val args = call.arguments as? Map<*, *>
                    val text = args?.get("text") as? String ?: ""
                    val rate = (args?.get("rate") as? Number)?.toFloat() ?: 1.0f
                    val pitch = (args?.get("pitch") as? Number)?.toFloat() ?: 1.0f
                    val modelPath = args?.get("modelPath") as? String
                    val configPath = args?.get("configPath") as? String
                    val synthPath = voiceGenService?.synthesize(text, null, rate, pitch, modelPath, configPath)
                    if (synthPath != null) {
                        result.success(mapOf("success" to true, "path" to synthPath))
                    } else {
                        result.success(mapOf("success" to false, "error" to "Synthesis failed"))
                    }
                }
                "dispose" -> {
                    voiceGenService?.dispose()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Audio playback channel
        val audioPlaybackChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_PLAYBACK_CHANNEL)
        audioPlaybackChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val args = call.arguments as? Map<*, *>
                    val path = args?.get("path") as? String ?: ""
                    voiceGenService?.play(path)
                    result.success(null)
                }
                "stop" -> {
                    voiceGenService?.stop()
                    result.success(null)
                }
                "isPlaying" -> {
                    result.success(voiceGenService?.isPlaying() ?: false)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CAPTURE_REQUEST_CODE) {
            val intent = Intent(this, ScreenCaptureService::class.java).apply {
                putExtra("result_code", resultCode)
                putExtra("data", data)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            captureResultCallback?.success("Screen capture started")
            captureResultCallback = null
        }
    }

    private fun startScreenCapture(result: MethodChannel.Result) {
        val projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val intent = projectionManager.createScreenCaptureIntent()
        captureResultCallback = result
        startActivityForResult(intent, CAPTURE_REQUEST_CODE)
    }

    private fun captureScreenshot(result: MethodChannel.Result) {
        val bytes = ScreenCaptureService.captureScreenshot()
        if (bytes != null) {
            result.success(bytes)
        } else {
            result.error("CAPTURE_FAILED", "No screen capture available", null)
        }
    }

    private fun stopScreenCapture(result: MethodChannel.Result) {
        val intent = Intent(this, ScreenCaptureService::class.java)
        stopService(intent)
        result.success("Screen capture stopped")
    }

    // Fallback for when Accessibility Service is not running
    private fun handleFallbackMethodCall(method: String, args: Map<*, *>?, result: MethodChannel.Result) {
        when (method) {
            "checkPermission" -> result.success(false)
            "requestPermission" -> {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                startActivity(intent)
                result.success(null)
            }
            "initialize" -> result.success(null)
            "getInstalledApps" -> {
                val pm = packageManager
                val apps = pm.getInstalledPackages(0)
                    .filter { it.packageName != packageName }
                    .mapNotNull { pkg ->
                        val appInfo = pkg.applicationInfo ?: return@mapNotNull null
                        val label = pm.getApplicationLabel(appInfo).toString()
                        mapOf(
                            "packageName" to pkg.packageName,
                            "label" to label,
                            "activity" to (pkg.activities?.firstOrNull()?.name ?: "")
                        )
                    }
                    .sortedBy { it["label"] as String }
                result.success(apps)
            }
            "openUrl" -> {
                val url = args?.get("url") as? String ?: ""
                if (url.isNotEmpty()) {
                    val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success("Opened $url")
                } else {
                    result.error("MISSING_URL", "url is required", null)
                }
            }
            "launchApp" -> {
                val packageName = args?.get("packageName") as? String ?: ""
                @Suppress("UNCHECKED_CAST")
                val altPackages = (args?.get("altPackages") as? List<String>) ?: emptyList()
                val displayName = (args?.get("displayName") as? String) ?: packageName
                if (packageName.isNotEmpty()) {
                    val allPackages = listOf(packageName) + altPackages
                    var launched = false
                    var lastError: String? = null

                    for (pkg in allPackages) {
                        try {
                            val intent = packageManager.getLaunchIntentForPackage(pkg)
                            if (intent != null) {
                                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                                startActivity(intent)
                                result.success("Launched $displayName")
                                launched = true
                                break
                            }
                        } catch (e: Exception) {
                            lastError = e.message
                        }
                    }

                    if (!launched) {
                        // Try to find the app by searching installed apps
                        val foundPackage = findInstalledAppByKeyword(displayName)
                        if (foundPackage != null) {
                            try {
                                val intent = packageManager.getLaunchIntentForPackage(foundPackage)
                                if (intent != null) {
                                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                                    startActivity(intent)
                                    result.success("Launched $displayName (found: $foundPackage)")
                                    launched = true
                                }
                            } catch (e: Exception) {
                                lastError = e.message
                            }
                        }
                    }

                    if (!launched) {
                        // Final fallback: open app details in settings
                        try {
                            val settingsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(settingsIntent)
                            result.success("Opened app settings for $displayName (app not installed)")
                        } catch (e: Exception) {
                            result.error("LAUNCH_FAILED", lastError ?: "App not found: $displayName", null)
                        }
                    }
                } else {
                    result.error("MISSING_PACKAGE", "packageName is required", null)
                }
            }
            "scrollDown", "scrollUp", "goBack", "deepLinkApp", "clickText" -> {
                result.error("SERVICE_REQUIRED", "Enable Accessibility Service to use scroll, back, and tap features", null)
            }
            "emergencyStop" -> {
                result.success("Stopped (accessibility service not active)")
            }
            "dispose" -> result.success(null)
            else -> result.error("SERVICE_UNAVAILABLE", "Enable Accessibility Service for full device control", null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        AmbotAccessibilityService.setMethodChannel(null)
        voiceService?.shutdown()
        sdServerPlugin?.dispose()
    }

    /// Find an installed app by matching a keyword against app labels.
    private fun findInstalledAppByKeyword(keyword: String): String? {
        val lowerKeyword = keyword.lowercase()
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val apps = pm.queryIntentActivities(intent, 0)
        for (resolveInfo in apps) {
            val label = resolveInfo.loadLabel(pm).toString().lowercase()
            val pkg = resolveInfo.activityInfo.packageName.lowercase()
            if (label.contains(lowerKeyword) || pkg.contains(lowerKeyword)) {
                return resolveInfo.activityInfo.packageName
            }
        }
        return null
    }
}
