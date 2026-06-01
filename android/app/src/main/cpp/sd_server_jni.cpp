#include <jni.h>
#include <thread>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <unwind.h>
#include <dlfcn.h>
#include <android/log.h>

#define LOG_TAG "sd-server-jni"

// Declared in main.cpp
void sd_server_run(const char* model_path, const char* listen_ip, int port, bool verbose, const char* extra_args);
void sd_server_stop();

struct backtrace_state {
    void** buffer;
    size_t max;
    size_t count;
};

static _Unwind_Reason_Code unwind_callback(struct _Unwind_Context* ctx, void* arg) {
    backtrace_state* state = (backtrace_state*)arg;
    if (state->count >= state->max) return _URC_END_OF_STACK;
    state->buffer[state->count++] = (void*)_Unwind_GetIP(ctx);
    return _URC_NO_REASON;
}

static size_t unwind_backtrace(void** buffer, size_t max) {
    backtrace_state state = {buffer, max, 0};
    _Unwind_Backtrace(unwind_callback, &state);
    return state.count;
}

static void sigsegv_handler(int sig) {
    // Signal-safe: write to log using __android_log_print is NOT signal-safe,
    // but we do it anyway for debugging (best-effort)
    void* buffer[64];
    size_t count = unwind_backtrace(buffer, 64);
    __android_log_print(ANDROID_LOG_FATAL, LOG_TAG, "SIGSEGV caught! Backtrace (%zu frames):", count);
    for (size_t i = 0; i < count; i++) {
        Dl_info info;
        if (dladdr(buffer[i], &info) && info.dli_sname) {
            __android_log_print(ANDROID_LOG_FATAL, LOG_TAG, "  #%02zu: %p %s (%s)", i, buffer[i], info.dli_sname, info.dli_fname ? info.dli_fname : "?");
        } else {
            __android_log_print(ANDROID_LOG_FATAL, LOG_TAG, "  #%02zu: %p", i, buffer[i]);
        }
    }
    // Re-raise with default handler for crash dump
    signal(sig, SIG_DFL);
    raise(sig);
}

// Package: com.ambot.ambot_ai (underscore in "ambot_ai" mangled as "_1")
// Class: SdServerNative (static methods in companion object)

extern "C" JNIEXPORT void JNICALL
Java_com_ambot_ambot_1ai_SdServerNative_nativeStartServer(
    JNIEnv* env, jclass clazz, jstring model_path, jstring listen_ip, jint port, jboolean verbose, jstring extra_args) {

    // Install SIGSEGV handler for crash diagnostics
    signal(SIGSEGV, sigsegv_handler);

    const char* model_path_cstr = env->GetStringUTFChars(model_path, nullptr);
    const char* listen_ip_cstr = env->GetStringUTFChars(listen_ip, nullptr);

    std::string* model_path_copy = new std::string(model_path_cstr);
    std::string* listen_ip_copy = new std::string(listen_ip_cstr);

    env->ReleaseStringUTFChars(model_path, model_path_cstr);
    env->ReleaseStringUTFChars(listen_ip, listen_ip_cstr);

    std::string extra_args_str;
    if (extra_args) {
        const char* ea = env->GetStringUTFChars(extra_args, nullptr);
        extra_args_str = ea;
        env->ReleaseStringUTFChars(extra_args, ea);
    }
    std::string* extra_args_copy = new std::string(extra_args_str);

    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Starting server thread (model=%s, ip=%s, port=%d, verbose=%d, extra=%s)",
                        model_path_copy->c_str(), listen_ip_copy->c_str(), port, verbose, extra_args_copy->c_str());

    std::thread server_thread([=]() {
        // Change to app's writable directory to avoid filesystem permission errors
        if (chdir("/data/user/0/com.ambot.ambot_ai/files") == 0) {
            __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Changed cwd to app files dir");
        }

        __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Server thread started, calling sd_server_run()");
        sd_server_run(model_path_copy->c_str(), listen_ip_copy->c_str(), port, verbose == JNI_TRUE, extra_args_copy->c_str());
        __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Server thread finished");
        delete model_path_copy;
        delete listen_ip_copy;
        delete extra_args_copy;
    });
    server_thread.detach();
}

extern "C" JNIEXPORT void JNICALL
Java_com_ambot_ambot_1ai_SdServerNative_nativeStopServer(
    JNIEnv* env, jclass clazz) {
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Stopping server");
    sd_server_stop();
}
