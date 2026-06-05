package com.ambot.ambot_ai

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Path
import android.graphics.Rect
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.AlarmClock
import android.provider.CalendarContract
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.app.UiModeManager
import android.content.res.Configuration
import android.media.AudioManager
import android.os.UserHandle
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.app.NotificationManager

/**
 * Accessibility Service that enables Ambot AI to:
 * - Read the current screen's UI element tree and text
 * - Perform taps, swipes, and long-presses
 * - Type text into focused input fields
 * - Navigate the UI programmatically
 *
 * This service requires the user to explicitly enable it in Android Settings.
 */
class AmbotAccessibilityService : AccessibilityService() {

    companion object {
        var instance: AmbotAccessibilityService? = null
            private set

        const val CHANNEL = "ambot_ai/device_control"

        // Pending method call results
        private val pendingResults = mutableMapOf<String, MethodChannel.Result>()
        private var methodChannel: MethodChannel? = null

        fun setMethodChannel(channel: MethodChannel?) {
            methodChannel = channel
        }

        fun resolveResult(callId: String, success: Boolean, data: Any?) {
            pendingResults.remove(callId)?.success(data)
        }

        fun rejectResult(callId: String, code: String, message: String?) {
            pendingResults.remove(callId)?.error(code, message, null)
        }
    }

    private var currentRoot: AccessibilityNodeInfo? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.source?.let { source ->
            if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
                event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
                currentRoot = rootInActiveWindow
            }
        }
    }

    override fun onInterrupt() {
        // No-op
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    // --- Public API called from MethodChannel ---

    fun handleMethodCall(method: String, args: Map<*, *>?, result: MethodChannel.Result) {
        when (method) {
            "checkPermission" -> result.success(instance != null && isServiceEnabled)
            "requestPermission" -> openAccessibilitySettings()
            "initialize" -> result.success(null)
            "readScreen" -> handleReadScreen(result)
            "captureScreen" -> handleCaptureScreen(result)
            "launchApp" -> handleLaunchApp(args, result)
            "openUrl" -> handleOpenUrl(args, result)
            "webSearch" -> handleWebSearch(args, result)
            "setAlarm" -> handleSetAlarm(args, result)
            "setTimer" -> handleSetTimer(args, result)
            "toggleSetting" -> handleToggleSetting(args, result)
            "setVolume" -> handleSetVolume(args, result)
            "setBrightness" -> handleSetBrightness(args, result)
            "copyToClipboard" -> handleCopyToClipboard(args, result)
            "createCalendarEvent" -> handleCreateCalendarEvent(args, result)
            "sendSms" -> handleSendSms(args, result)
            "sendEmail" -> handleSendEmail(args, result)
            "tapElement" -> handleTapElement(args, result)
            "typeText" -> handleTypeText(args, result)
            "navigateInApp" -> handleNavigateInApp(args, result)
            "scrollDown" -> handleScrollDown(args, result)
            "scrollUp" -> handleScrollUp(args, result)
            "goBack" -> handleGoBack(result)
            "deepLinkApp" -> handleDeepLinkApp(args, result)
            "clickText" -> handleClickText(args, result)
            "getInstalledApps" -> handleGetInstalledApps(result)
            "emergencyStop" -> handleEmergencyStop(result)
            "dispose" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    private val isServiceEnabled: Boolean
        get() {
            val accessibilityEnabled = try {
                Settings.Secure.getInt(
                    applicationContext.contentResolver,
                    Settings.Secure.ACCESSIBILITY_ENABLED
                )
            } catch (e: Exception) {
                0
            }
            if (accessibilityEnabled == 1) {
                val enabledServices = Settings.Secure.getString(
                    applicationContext.contentResolver,
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                ) ?: return false
                val packageName = packageName
                val serviceName = "$packageName/${AmbotAccessibilityService::class.java.name}"
                return enabledServices.contains(serviceName)
            }
            return false
        }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        applicationContext.startActivity(intent)
    }

    // --- Screen Reading ---

    private fun handleReadScreen(result: MethodChannel.Result) {
        val root = rootInActiveWindow ?: run {
            result.success(mapOf("text" to "No active window", "nodes" to emptyList<Map<String, Any>>()))
            return
        }
        val text = buildString { appendNodeText(root, this) }
        val nodes = buildNodeList(root)
        result.success(mapOf(
            "text" to text,
            "nodes" to nodes,
            "screenshot" to null
        ))
    }

    private fun handleCaptureScreen(result: MethodChannel.Result) {
        // Try Accessibility first for text + nodes
        val root = rootInActiveWindow
        val text = root?.let { buildString { appendNodeText(it, this) } } ?: "No active window"
        val nodes = root?.let { buildNodeList(it) } ?: emptyList()

        // Screenshot requires MediaProjection - return null for now,
        // the ScreenCaptureService handles that separately.
        result.success(mapOf(
            "text" to text,
            "nodes" to nodes,
            "screenshot" to null
        ))
    }

    private fun appendNodeText(node: AccessibilityNodeInfo, sb: StringBuilder, indent: Int = 0) {
        val prefix = "  ".repeat(indent)
        node.text?.let {
            if (it.isNotEmpty()) {
                sb.append("$prefix$it\n")
            }
        }
        node.contentDescription?.let {
            if (it.isNotEmpty()) {
                sb.append("$prefix[desc: $it]\n")
            }
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                appendNodeText(child, sb, indent + 1)
            }
        }
    }

    private fun buildNodeList(node: AccessibilityNodeInfo): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        val item = mutableMapOf<String, Any>()
        node.viewIdResourceName?.let { item["viewId"] = it }
        node.text?.let { if (it.isNotEmpty()) item["text"] = it.toString() }
        node.contentDescription?.let { if (it.isNotEmpty()) item["contentDesc"] = it.toString() }
        node.className?.let { item["className"] = it.toString() }
        item["clickable"] = node.isClickable
        item["enabled"] = node.isEnabled
        item["editable"] = node.isEditable
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        item["bounds"] = listOf(bounds.left, bounds.top, bounds.right, bounds.bottom)
        val children = mutableListOf<Map<String, Any>>()
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                children.addAll(buildNodeList(child))
            }
        }
        item["children"] = children
        list.add(item)
        return list
    }

    // --- App & Navigation ---

    private fun handleLaunchApp(args: Map<*, *>?, result: MethodChannel.Result) {
        val packageName = args?.get("packageName") as? String ?: ""
        val activity = args?.get("activity") as? String
        if (packageName.isEmpty()) {
            result.error("MISSING_PACKAGE", "packageName is required", null)
            return
        }
        try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                if (activity != null) {
                    intent.setClassName(packageName, "$packageName.$activity")
                }
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                applicationContext.startActivity(intent)
                result.success("Launched $packageName")
            } else {
                // Fallback: open app details in settings
                val settingsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                applicationContext.startActivity(settingsIntent)
                result.success("Opened app settings for $packageName (no launch intent)")
            }
        } catch (e: Exception) {
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    private fun handleOpenUrl(args: Map<*, *>?, result: MethodChannel.Result) {
        val url = args?.get("url") as? String ?: ""
        if (url.isEmpty()) {
            result.error("MISSING_URL", "url is required", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            applicationContext.startActivity(intent)
            result.success("Opened $url")
        } catch (e: Exception) {
            result.error("OPEN_FAILED", e.message, null)
        }
    }

    private fun handleWebSearch(args: Map<*, *>?, result: MethodChannel.Result) {
        val query = args?.get("query") as? String ?: ""
        if (query.isEmpty()) {
            result.error("MISSING_QUERY", "query is required", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_WEB_SEARCH)
            intent.putExtra("query", query)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            applicationContext.startActivity(intent)
            result.success("Searching for: $query")
        } catch (e: Exception) {
            result.error("SEARCH_FAILED", e.message, null)
        }
    }

    // --- System Actions ---

    private fun handleSetAlarm(args: Map<*, *>?, result: MethodChannel.Result) {
        val hour = (args?.get("hour") as? Number)?.toInt() ?: 0
        val minute = (args?.get("minute") as? Number)?.toInt() ?: 0
        val label = args?.get("label") as? String ?: ""
        try {
            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(AlarmClock.EXTRA_HOUR, hour)
                putExtra(AlarmClock.EXTRA_MINUTES, minute)
                putExtra(AlarmClock.EXTRA_MESSAGE, label)
                putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            applicationContext.startActivity(intent)
            result.success("Alarm set for $hour:$minute")
        } catch (e: Exception) {
            result.error("ALARM_FAILED", e.message, null)
        }
    }

    private fun handleSetTimer(args: Map<*, *>?, result: MethodChannel.Result) {
        val seconds = (args?.get("seconds") as? Number)?.toLong() ?: 0L
        try {
            val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                putExtra(AlarmClock.EXTRA_LENGTH, seconds)
                putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            applicationContext.startActivity(intent)
            result.success("Timer set for $seconds seconds")
        } catch (e: Exception) {
            result.error("TIMER_FAILED", e.message, null)
        }
    }

    private fun handleToggleSetting(args: Map<*, *>?, result: MethodChannel.Result) {
        val setting = args?.get("setting") as? String ?: ""
        val value = args?.get("value") as? Boolean ?: true
        when (setting) {
            "wifi" -> toggleWifi(value, result)
            "bluetooth" -> toggleBluetooth(value, result)
            "flashlight" -> toggleFlashlight(value, result)
            "dnd" -> toggleDnd(value, result)
            else -> result.error("UNKNOWN_SETTING", "Unknown setting: $setting", null)
        }
    }

    private fun toggleWifi(on: Boolean, result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            applicationContext.startActivity(intent)
            result.success("WiFi settings opened (toggle manually)")
        } catch (e: Exception) {
            result.error("WIFI_FAILED", e.message, null)
        }
    }

    private fun toggleBluetooth(on: Boolean, result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            applicationContext.startActivity(intent)
            result.success("Bluetooth settings opened (toggle manually)")
        } catch (e: Exception) {
            result.error("BLUETOOTH_FAILED", e.message, null)
        }
    }

    private fun toggleFlashlight(on: Boolean, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.error("UNSUPPORTED", "Flashlight requires Android 6.0+", null)
            return
        }
        try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id).get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
            if (cameraId != null) {
                cameraManager.setTorchMode(cameraId, on)
                result.success("Flashlight ${if (on) "on" else "off"}")
            } else {
                result.error("NO_FLASH", "No flash available on this device", null)
            }
        } catch (e: SecurityException) {
            result.error("CAMERA_PERMISSION", "Camera permission required to toggle flashlight", null)
        } catch (e: Exception) {
            result.error("FLASHLIGHT_FAILED", e.message, null)
        }
    }

    private fun toggleDnd(on: Boolean, result: MethodChannel.Result) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (notificationManager.isNotificationPolicyAccessGranted) {
                val filter = if (on) NotificationManager.INTERRUPTION_FILTER_PRIORITY
                    else NotificationManager.INTERRUPTION_FILTER_ALL
                notificationManager.setInterruptionFilter(filter)
                result.success("DND ${if (on) "enabled" else "disabled"}")
            } else {
                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                applicationContext.startActivity(intent)
                result.success("DND permission screen opened (grant to toggle)")
            }
        } catch (e: Exception) {
            result.error("DND_FAILED", e.message, null)
        }
    }

    private fun handleSetVolume(args: Map<*, *>?, result: MethodChannel.Result) {
        val stream = args?.get("stream") as? String ?: "media"
        val level = (args?.get("level") as? Number)?.toInt() ?: 50
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val streamType = when (stream) {
                "media" -> AudioManager.STREAM_MUSIC
                "ring" -> AudioManager.STREAM_RING
                "alarm" -> AudioManager.STREAM_ALARM
                "call" -> AudioManager.STREAM_VOICE_CALL
                else -> AudioManager.STREAM_MUSIC
            }
            val max = audioManager.getStreamMaxVolume(streamType)
            val targetLevel = (level * max / 100).coerceIn(0, max)
            audioManager.setStreamVolume(streamType, targetLevel, 0)
            result.success("Volume set to $level%")
        } catch (e: Exception) {
            result.error("VOLUME_FAILED", e.message, null)
        }
    }

    private fun handleSetBrightness(args: Map<*, *>?, result: MethodChannel.Result) {
        val level = (args?.get("level") as? Number)?.toInt() ?: 50
        try {
            // Requires WRITE_SETTINGS permission
            if (Settings.System.canWrite(applicationContext)) {
                val brightness = (level * 255 / 100).coerceIn(0, 255)
                Settings.System.putInt(
                    applicationContext.contentResolver,
                    Settings.System.SCREEN_BRIGHTNESS,
                    brightness
                )
                result.success("Brightness set to $level%")
            } else {
                val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                applicationContext.startActivity(intent)
                result.success("Permission screen opened (grant to adjust brightness)")
            }
        } catch (e: Exception) {
            result.error("BRIGHTNESS_FAILED", e.message, null)
        }
    }

    // --- Clipboard ---

    private fun handleCopyToClipboard(args: Map<*, *>?, result: MethodChannel.Result) {
        val text = args?.get("text") as? String ?: ""
        if (text.isEmpty()) {
            result.error("MISSING_TEXT", "text is required", null)
            return
        }
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("Ambot AI", text))
        result.success("Text copied to clipboard")
    }

    // --- Calendar ---

    private fun handleCreateCalendarEvent(args: Map<*, *>?, result: MethodChannel.Result) {
        val title = args?.get("title") as? String ?: ""
        val description = args?.get("description") as? String ?: ""
        if (title.isEmpty()) {
            result.error("MISSING_TITLE", "title is required", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_INSERT).apply {
                data = CalendarContract.Events.CONTENT_URI
                putExtra(CalendarContract.Events.TITLE, title)
                putExtra(CalendarContract.Events.DESCRIPTION, description)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            applicationContext.startActivity(intent)
            result.success("Calendar event creation opened")
        } catch (e: Exception) {
            result.error("CALENDAR_FAILED", e.message, null)
        }
    }

    // --- Communication ---

    private fun handleSendSms(args: Map<*, *>?, result: MethodChannel.Result) {
        val recipient = args?.get("recipient") as? String ?: ""
        val message = args?.get("message") as? String ?: ""
        if (recipient.isEmpty()) {
            result.error("MISSING_RECIPIENT", "recipient is required", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_SENDTO).apply {
                data = Uri.parse("smsto:$recipient")
                putExtra("sms_body", message)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            applicationContext.startActivity(intent)
            result.success("SMS compose opened for $recipient")
        } catch (e: Exception) {
            result.error("SMS_FAILED", e.message, null)
        }
    }

    private fun handleSendEmail(args: Map<*, *>?, result: MethodChannel.Result) {
        val to = args?.get("to") as? String ?: ""
        val subject = args?.get("subject") as? String ?: ""
        val body = args?.get("body") as? String ?: ""
        if (to.isEmpty()) {
            result.error("MISSING_TO", "to is required", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_SENDTO).apply {
                data = Uri.parse("mailto:$to")
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, body)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            applicationContext.startActivity(intent)
            result.success("Email compose opened for $to")
        } catch (e: Exception) {
            result.error("EMAIL_FAILED", e.message, null)
        }
    }

    // --- UI Interaction ---

    private fun handleTapElement(args: Map<*, *>?, result: MethodChannel.Result) {
        val text = args?.get("text") as? String ?: ""
        val x = (args?.get("x") as? Number)?.toFloat() ?: 0f
        val y = (args?.get("y") as? Number)?.toFloat() ?: 0f

        if (x > 0 && y > 0) {
            // Tap by coordinates
            performTap(x, y, result)
        } else if (text.isNotEmpty()) {
            // Tap by finding element with matching text
            findAndTapByText(text, result)
        } else {
            result.error("MISSING_TARGET", "Provide text or x/y coordinates", null)
        }
    }

    private fun performTap(x: Float, y: Float, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val path = Path()
            path.moveTo(x, y)
            val gesture = GestureDescription.Builder()
                .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
                .build()
            dispatchGesture(gesture, object : GestureResultCallback() {
                override fun onCompleted(gesture: GestureDescription?) {
                    result.success("Tapped at ($x, $y)")
                }
                override fun onCancelled(gesture: GestureDescription?) {
                    result.error("TAP_CANCELLED", "Tap gesture was cancelled", null)
                }
            }, null)
        } else {
            result.error("UNSUPPORTED", "Tap requires Android 7.0+", null)
        }
    }

    private fun findAndTapByText(text: String, result: MethodChannel.Result) {
        val root = rootInActiveWindow ?: run {
            result.error("NO_WINDOW", "No active window", null)
            return
        }
        val node = findNodeByText(root, text)
        if (node != null) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            val x = bounds.centerX().toFloat()
            val y = bounds.centerY().toFloat()
            performTap(x, y, result)
        } else {
            result.error("NOT_FOUND", "Element with text '$text' not found", null)
        }
    }

    private fun findNodeByText(node: AccessibilityNodeInfo, text: String): AccessibilityNodeInfo? {
        if (node.text?.toString()?.contains(text, ignoreCase = true) == true) return node
        if (node.contentDescription?.toString()?.contains(text, ignoreCase = true) == true) return node
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                findNodeByText(child, text)?.let { return it }
            }
        }
        return null
    }

    private fun handleTypeText(args: Map<*, *>?, result: MethodChannel.Result) {
        val text = args?.get("text") as? String ?: ""
        if (text.isEmpty()) {
            result.error("MISSING_TEXT", "text is required", null)
            return
        }
        // Find the focused editable node
        val root = rootInActiveWindow
        val focusedNode = findFocusedEditable(root)
        if (focusedNode != null) {
            // Use clipboard paste approach for reliability
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("Ambot AI", text))

            // Simulate Ctrl+V via key events (works on devices with keyboards)
            // For touch-only devices, we rely on the user to paste or use the accessibility input method
            val bundle = Bundle()
            bundle.putCharSequence(
                AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                text
            )
            focusedNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, bundle)
            result.success("Typed: $text")
        } else {
            result.error("NO_INPUT", "No text input field is focused", null)
        }
    }

    private fun findFocusedEditable(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        if (node == null) return null
        if (node.isEditable && node.isFocused) return node
        for (i in 0 until node.childCount) {
            findFocusedEditable(node.getChild(i))?.let { return it }
        }
        return null
    }

    private fun handleNavigateInApp(args: Map<*, *>?, result: MethodChannel.Result) {
        val target = args?.get("target") as? String ?: ""
        if (target.isEmpty()) {
            result.error("MISSING_TARGET", "target is required", null)
            return
        }
        // Try to find and tap the target element
        findAndTapByText(target, result)
    }

    // --- Scroll & Navigation ---

    private fun handleScrollDown(args: Map<*, *>?, result: MethodChannel.Result) {
        val distance = (args?.get("distance") as? Number)?.toFloat() ?: 0.5f
        val root = rootInActiveWindow
        if (root == null) {
            result.error("NO_WINDOW", "No active window", null)
            return
        }
        // Find scrollable node
        val scrollable = findScrollableNode(root, true)
        if (scrollable != null) {
            scrollable.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)
            result.success("Scrolled down")
        } else {
            // Fallback: perform swipe gesture
            performSwipe(distance, forward = true, result)
        }
    }

    private fun handleScrollUp(args: Map<*, *>?, result: MethodChannel.Result) {
        val distance = (args?.get("distance") as? Number)?.toFloat() ?: 0.5f
        val root = rootInActiveWindow
        if (root == null) {
            result.error("NO_WINDOW", "No active window", null)
            return
        }
        val scrollable = findScrollableNode(root, false)
        if (scrollable != null) {
            scrollable.performAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD)
            result.success("Scrolled up")
        } else {
            performSwipe(distance, forward = false, result)
        }
    }

    private fun findScrollableNode(node: AccessibilityNodeInfo?, scrollDown: Boolean): AccessibilityNodeInfo? {
        if (node == null) return null
        if (node.isScrollable) {
            return node
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                findScrollableNode(child, scrollDown)?.let { return it }
            }
        }
        return null
    }

    private fun performSwipe(distanceFraction: Float, forward: Boolean, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            result.error("UNSUPPORTED", "Scroll gestures require Android 7.0+", null)
            return
        }
        val display = applicationContext.resources.displayMetrics
        val width = display.widthPixels.toFloat()
        val height = display.heightPixels.toFloat()

        val startX = width / 2
        val startY = if (forward) height * 0.7f else height * 0.3f
        val endY = if (forward) height * 0.3f else height * 0.7f

        val path = Path()
        path.moveTo(startX, startY)
        path.lineTo(startX, endY)
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0L, 300L))
            .build()
        dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gesture: GestureDescription?) {
                result.success("Swiped")
            }
            override fun onCancelled(gesture: GestureDescription?) {
                result.error("SWIPE_CANCELLED", "Swipe gesture cancelled", null)
            }
        }, null)
    }

    private fun handleGoBack(result: MethodChannel.Result) {
        val performed = performGlobalAction(GLOBAL_ACTION_BACK)
        if (performed) {
            result.success("Back navigation performed")
        } else {
            result.error("BACK_FAILED", "Could not perform back action", null)
        }
    }

    private fun handleDeepLinkApp(args: Map<*, *>?, result: MethodChannel.Result) {
        val packageName = args?.get("packageName") as? String ?: ""
        val uri = args?.get("uri") as? String ?: ""
        if (uri.isEmpty()) {
            result.error("MISSING_URI", "uri is required", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
                if (packageName.isNotEmpty()) {
                    setPackage(packageName)
                }
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            applicationContext.startActivity(intent)
            result.success("Deep link opened: $uri")
        } catch (e: Exception) {
            result.error("DEEPLINK_FAILED", e.message, null)
        }
    }

    private fun handleClickText(args: Map<*, *>?, result: MethodChannel.Result) {
        val text = args?.get("text") as? String ?: ""
        if (text.isEmpty()) {
            result.error("MISSING_TEXT", "text is required", null)
            return
        }
        findAndTapByText(text, result)
    }

    // --- App List ---

    private fun handleGetInstalledApps(result: MethodChannel.Result) {
        val pm = applicationContext.packageManager
        val apps = pm.getInstalledPackages(PackageManager.GET_ACTIVITIES)
            .filter { it.packageName != packageName } // Exclude self
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

    // --- Emergency Stop ---

    private fun handleEmergencyStop(result: MethodChannel.Result) {
        // Perform a global back action to exit any automation flow
        performGlobalAction(GLOBAL_ACTION_BACK)
        result.success("Emergency stop: back action performed")
    }
}
