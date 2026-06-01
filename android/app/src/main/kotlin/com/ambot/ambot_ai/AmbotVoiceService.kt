package com.ambot.ambot_ai

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * Native voice bridge that wraps Android's SpeechRecognizer (STT) and
 * TextToSpeech (TTS) APIs, exposing them to Flutter via MethodChannel.
 *
 * Speech-to-Text:
 *   - Uses SpeechRecognizer API
 *   - Android 12+ (API 31): fully on-device recognition available
 *   - Older versions: falls back to Google cloud (requires internet)
 *
 * Text-to-Speech:
 *   - Uses Android's built-in TTS engine
 *   - Supports offline voice data downloaded in system settings
 */
class AmbotVoiceService(
    private val context: Context,
    private val channel: MethodChannel
) {

    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    private var ttsInitialized = false
    private var isListening = false
    private var continuousMode = false

    private var currentLanguage = Locale.US
    private var speechRate = 1.0f
    private var pitch = 1.0f
    private var offlineOnly = false

    fun initialize() {
        initSpeechRecognizer()
        initTextToSpeech()
    }

    // --- Speech-to-Text ---

    private fun initSpeechRecognizer() {
        if (SpeechRecognizer.isRecognitionAvailable(context)) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    sendStateChange("listening")
                }

                override fun onBeginningOfSpeech() {
                    sendStateChange("recognizing")
                }

                override fun onRmsChanged(rmsdB: Float) {
                    // Could send RMS for waveform visualization
                }

                override fun onBufferReceived(buffer: ByteArray?) {}

                override fun onEndOfSpeech() {
                    // Waiting for results
                }

                override fun onError(error: Int) {
                    val message = when (error) {
                        SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                        SpeechRecognizer.ERROR_CLIENT -> "Client error"
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                        SpeechRecognizer.ERROR_NETWORK -> "Network error"
                        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                        SpeechRecognizer.ERROR_NO_MATCH -> "No speech match"
                        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
                        SpeechRecognizer.ERROR_SERVER -> "Server error"
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                        else -> "Unknown error ($error)"
                    }
                    sendSpeechError(message)
                    sendStateChange("error")
                    isListening = false
                }

                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val confidence = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)

                    if (!matches.isNullOrEmpty()) {
                        val text = matches[0]
                        val conf = confidence?.getOrNull(0) ?: 0.0f
                        sendSpeechResult(text, conf.toDouble(), isPartial = false)
                        sendStateChange("done")
                    }
                    isListening = false

                    // If continuous mode, restart listening
                    if (continuousMode) {
                        startListening(continuous = true)
                    }
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!matches.isNullOrEmpty()) {
                        sendSpeechResult(matches[0], 0.0, isPartial = true)
                    }
                }

                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
        }
    }

    fun startListening(continuous: Boolean = false, language: String? = null, offlineOnly: Boolean = false) {
        if (speechRecognizer == null) {
            sendSpeechError("Speech recognition not available")
            return
        }
        if (isListening) {
            speechRecognizer?.stopListening()
        }

        continuousMode = continuous
        if (language != null) {
            currentLanguage = parseLocale(language)
        }
        this.offlineOnly = offlineOnly

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, currentLanguage.toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)

            // Android 12+: prefer on-device recognition
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                putExtra(
                    RecognizerIntent.EXTRA_PREFER_OFFLINE,
                    offlineOnly || Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                )
            }
        }

        try {
            speechRecognizer?.startListening(intent)
            isListening = true
        } catch (e: Exception) {
            sendSpeechError("Failed to start listening: ${e.message}")
        }
    }

    fun stopListening() {
        speechRecognizer?.stopListening()
        isListening = false
        continuousMode = false
    }

    fun cancelListening() {
        speechRecognizer?.cancel()
        isListening = false
        continuousMode = false
    }

    fun isSpeechAvailable(): Boolean {
        return SpeechRecognizer.isRecognitionAvailable(context)
    }

    // --- Text-to-Speech ---

    private fun initTextToSpeech() {
        textToSpeech = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                textToSpeech?.language = currentLanguage
                textToSpeech?.setSpeechRate(speechRate)
                textToSpeech?.setPitch(pitch)
                ttsInitialized = true

                // Set utterance listener
                textToSpeech?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {}
                    override fun onDone(utteranceId: String?) {}
                    override fun onError(utteranceId: String?) {}
                })
            }
        }
    }

    fun speak(text: String, rate: Float? = null, pitch: Float? = null) {
        if (!ttsInitialized || textToSpeech == null) {
            sendSpeechError("TTS not initialized")
            return
        }

        rate?.let { speechRate = it }
        pitch?.let { this.pitch = it }

        textToSpeech?.setSpeechRate(speechRate)
        textToSpeech?.setPitch(this.pitch)

        val utteranceId = "ambot_${System.currentTimeMillis()}"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            textToSpeech?.speak(text, TextToSpeech.QUEUE_ADD, null, utteranceId)
        } else {
            @Suppress("DEPRECATION")
            textToSpeech?.speak(text, TextToSpeech.QUEUE_ADD, hashMapOf(
                TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID to utteranceId
            ))
        }
    }

    fun stopSpeaking() {
        textToSpeech?.stop()
    }

    fun isSpeaking(): Boolean {
        return textToSpeech?.isSpeaking ?: false
    }

    fun isTtsAvailable(): Boolean {
        return ttsInitialized
    }

    fun applySettings(language: String?, rate: Float?, pitch: Float?, offlineOnly: Boolean) {
        language?.let {
            currentLanguage = parseLocale(it)
            textToSpeech?.language = currentLanguage
        }
        rate?.let {
            speechRate = it
            textToSpeech?.setSpeechRate(it)
        }
        pitch?.let {
            this.pitch = it
            textToSpeech?.setPitch(it)
        }
        this.offlineOnly = offlineOnly
    }

    fun shutdown() {
        speechRecognizer?.destroy()
        textToSpeech?.shutdown()
        speechRecognizer = null
        textToSpeech = null
    }

    // --- Helpers ---

    private fun parseLocale(languageTag: String): Locale {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                Locale.forLanguageTag(languageTag)
            } else {
                val parts = languageTag.split("-")
                when (parts.size) {
                    1 -> Locale(parts[0])
                    2 -> Locale(parts[0], parts[1])
                    else -> Locale(parts[0], parts[1], parts[2])
                }
            }
        } catch (e: Exception) {
            Locale.US
        }
    }

    private fun sendSpeechResult(text: String, confidence: Double, isPartial: Boolean) {
        channel.invokeMethod("onSpeechResult", mapOf(
            "text" to text,
            "confidence" to confidence,
            "isPartial" to isPartial
        ))
    }

    private fun sendSpeechError(message: String) {
        channel.invokeMethod("onSpeechError", message)
    }

    private fun sendStateChange(state: String) {
        channel.invokeMethod("onStateChanged", state)
    }
}
