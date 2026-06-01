package com.ambot.ambot_ai

/**
 * Shared native interface for the SD server.
 * Loads libsd-server.so and provides JNI entry points.
 * Used by both SdServerPlugin (main process) and SdServerService (separate process).
 */
class SdServerNative {
    companion object {
        init {
            System.loadLibrary("sd-server")
        }

        @JvmStatic
        external fun nativeStartServer(modelPath: String, listenIp: String, port: Int, verbose: Boolean, extraArgs: String)

        @JvmStatic
        external fun nativeStopServer()
    }
}
