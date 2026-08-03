plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.knovik.edgetal"
    // Some plugins (file_picker → flutter_plugin_android_lifecycle) require 36.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.knovik.edgetal"
        // MediaPipe LLM Inference (Gemma) requires API 26+.
        minSdk = maxOf(26, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // The on-device ML model assets must not be zip-compressed in the APK,
    // otherwise MediaPipe can't memory-map them.
    androidResources {
        noCompress += listOf("tflite", "bin")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // On-device ML — mirrors the original EdgeTal Kotlin app (MediaPipe 0.10.18).
    implementation("com.google.mediapipe:tasks-text:0.10.18")
    // 0.10.21+ adds LlmInferenceOptions.Builder.setPreferredBackend(Backend),
    // needed for the CPU/GPU delegate toggle in LlmChannel.kt. tasks-text
    // stays pinned since the embedder remains CPU-only (see plan notes).
    implementation("com.google.mediapipe:tasks-genai:0.10.21")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
