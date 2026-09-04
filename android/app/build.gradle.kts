import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // Kotlin is applied by the Flutter Gradle plugin; applying it here too is
    // deprecated (see the Flutter built-in Kotlin migration guide).
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// SQL Server access uses the mssql_connection package (Dart FFI + FreeTDS).
// It is a plain Dart package, not a Flutter plugin, so its native libraries are
// not packaged automatically, and the copies it ships are only 4 KB aligned.
// The app therefore carries its own 16 KB-aligned builds of libsybdb.so and
// libct.so in src/main/jniLibs/<abi>/, produced by tool/build_freetds_android.sh.

android {
    namespace = "com.eratech.blocks_price_check"
    // permission_handler_android 14.x compiles against SDK 37 (installed as
    // platform "android-37.0", which needs AGP 9+ to resolve).
    compileSdk = 37
    // Flutter's default (28.2.13676358), which the upgraded plugins expect.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.eratech.blocks_price_check"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
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
