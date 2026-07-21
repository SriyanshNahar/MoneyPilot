import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — see RELEASE_SIGNING.md for how key.properties /
// android/keystore/moneypilot-upload.jks were generated and how to rotate
// them. Falls back to debug signing only if key.properties is missing, so
// `flutter run` and CI checks that don't have the keystore still work.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "io.moneypilot.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (java.time APIs on API < 26).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "io.moneypilot.app"
        // local_auth (biometric App Lock) requires API 23+.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                // rootProject, not file() — storeFile in key.properties is
                // relative to android/ (where key.properties lives), not
                // android/app/ (where this build.gradle.kts lives).
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real upload-key signing when key.properties is present (see
            // RELEASE_SIGNING.md); otherwise falls back to the debug keystore
            // so unsigned local `flutter run --release` builds keep working.
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Firebase Cloud Messaging — only wired up once a real google-services.json
// (from your own Firebase console, see FIREBASE_SETUP.md) is dropped in
// here. Without it, this is a no-op and the app builds exactly as before —
// firebase_core/firebase_messaging's Dart code still compiles either way,
// it just fails gracefully at runtime (see main.dart) until this file exists.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
