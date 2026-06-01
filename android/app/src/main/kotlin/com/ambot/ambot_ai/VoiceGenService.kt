package com.ambot.ambot_ai

import android.content.Context
import android.media.MediaPlayer
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import java.io.File
import java.util.Locale
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit

class VoiceGenService(private val context: Context) {
    companion object {
        private const val TAG = "VoiceGenService"
        private const val DEFAULT_RATE = 1.0f
        private const val DEFAULT_PITCH = 1.0f
    }

    private var tts: TextToSpeech? = null
    private var mediaPlayer: MediaPlayer? = null
    private var isInitialized = false
    private var isPlaying = false

    // ONNX model paths passed from Dart (for future Piper native inference)
    private var piperModelPath: String? = null
    private var piperConfigPath: String? = null

    fun initialize(): Boolean {
        if (isInitialized) return true
        try {
            val latch = java.util.concurrent.CountDownLatch(1)
            tts = TextToSpeech(context) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    isInitialized = true
                    tts?.language = Locale.US
                    tts?.setSpeechRate(DEFAULT_RATE)
                    tts?.setPitch(DEFAULT_PITCH)
                    tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                        override fun onDone(utteranceId: String?) {}
                        override fun onError(utteranceId: String?) {}
                        override fun onStart(utteranceId: String?) {}
                    })
                }
                latch.countDown()
            }
            latch.await(5, TimeUnit.SECONDS)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize TTS", e)
        }
        return isInitialized
    }

    fun synthesize(
        text: String,
        outputPath: String?,
        rate: Float = DEFAULT_RATE,
        pitch: Float = DEFAULT_PITCH,
        modelPath: String? = null,
        configPath: String? = null,
    ): String? {
        if (!isInitialized && !initialize()) {
            Log.e(TAG, "TTS not initialized")
            return null
        }

        // Store ONNX paths for future Piper native inference
        if (modelPath != null) piperModelPath = modelPath
        if (configPath != null) piperConfigPath = configPath

        if (modelPath != null) {
            Log.d(TAG, "Using Android TTS (Piper ONNX available at $modelPath)")
        }

        try {
            val outFile = if (outputPath != null) File(outputPath) else createOutputFile()
            if (outFile.exists()) outFile.delete()
            outFile.parentFile?.mkdirs()

            val future = CompletableFuture<Boolean>()
            val utteranceId = "synth_${System.currentTimeMillis()}"

            tts?.setSpeechRate(rate)
            tts?.setPitch(pitch)

            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onDone(id: String?) {
                    if (id == utteranceId) {
                        future.complete(outFile.exists() && outFile.length() > 0)
                    }
                }
                override fun onError(id: String?) {
                    if (id == utteranceId) {
                        future.complete(false)
                    }
                }
                override fun onStart(id: String?) {}
            })

            val params = Bundle()
            val result = tts?.synthesizeToFile(text, params, outFile, utteranceId)
            if (result != TextToSpeech.SUCCESS) {
                Log.e(TAG, "synthesizeToFile failed with result=$result")
                return null
            }

            return if (future.get(30, TimeUnit.SECONDS)) outFile.absolutePath else null
        } catch (e: Exception) {
            Log.e(TAG, "Synthesis failed", e)
            return null
        }
    }

    fun getEngineName(): String = "Android TTS"

    fun getPiperModelPath(): String? = piperModelPath

    private fun createOutputFile(): File {
        val outputDir = File(context.getExternalFilesDir(null), "ambot_output/voice")
        outputDir.mkdirs()
        return File(outputDir, "voice_${System.currentTimeMillis()}.wav")
    }

    fun play(path: String) {
        stop()
        try {
            val file = File(path)
            if (!file.exists()) {
                Log.e(TAG, "Audio file not found: $path")
                return
            }
            mediaPlayer = MediaPlayer().apply {
                setDataSource(path)
                setOnPreparedListener { start(); this@VoiceGenService.isPlaying = true }
                setOnCompletionListener { this@VoiceGenService.isPlaying = false }
                setOnErrorListener { _, _, _ -> this@VoiceGenService.isPlaying = false; true }
                prepareAsync()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Playback failed", e)
            isPlaying = false
        }
    }

    fun stop() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
            mediaPlayer = null
        } catch (_: Exception) {}
        isPlaying = false
    }

    fun isPlaying(): Boolean = isPlaying

    fun dispose() {
        stop()
        try {
            tts?.stop()
            tts?.shutdown()
        } catch (_: Exception) {}
        tts = null
        isInitialized = false
    }
}
