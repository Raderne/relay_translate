plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.relay.relay_translate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        resValues = true // per-flavor app_name
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.relay.relay_translate"
        // Android 8.0: needed for TYPE_APPLICATION_OVERLAY (Phase 7).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // beta = tester builds (feedback tools, Phase 10); prod = Play release.
    flavorDimensions += "channel"
    productFlavors {
        create("beta") {
            dimension = "channel"
            applicationIdSuffix = ".beta"
            versionNameSuffix = "-beta"
            resValue("string", "app_name", "Relay Translate β")
        }
        create("prod") {
            dimension = "channel"
            resValue("string", "app_name", "Relay Translate")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build (Phase 13).
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Phase 1: Translator.kt runs ML Kit calls off the main thread.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    // Phase 1: on-device translation + language detection. The ONLY translation path (CLAUDE.md rule 5).
    implementation("com.google.mlkit:translate:17.0.3")
    implementation("com.google.mlkit:language-id:17.0.6")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.11.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
