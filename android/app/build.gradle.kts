import java.util.Properties
import java.io.FileInputStream
import java.net.URI

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

// mssql_connection (Dart FFI + FreeTDS) ships prebuilt native libraries in
// <package>/android/src/main/jniLibs, but it is a plain Dart package rather than
// a Flutter plugin, so the Flutter Gradle plugin does not package them. Resolve
// the package location from the Dart package config and add its jniLibs
// directory to this module so libsybdb.so / libct.so end up in the APK/AAB.
val mssqlConnectionJniLibs: File = run {
    val packageConfig = rootProject.file("../.dart_tool/package_config.json")
    if (!packageConfig.exists()) {
        throw GradleException(
            "mssql_connection: ${packageConfig.path} not found. Run `flutter pub get` first."
        )
    }
    @Suppress("UNCHECKED_CAST")
    val packages = (groovy.json.JsonSlurper().parseText(packageConfig.readText())
        as Map<String, Any?>)["packages"] as List<Map<String, Any?>>
    val pkg = packages.firstOrNull { it["name"] == "mssql_connection" }
        ?: throw GradleException(
            "mssql_connection: package not listed in ${packageConfig.path}. Run `flutter pub get`."
        )
    val rootUri = URI(pkg["rootUri"] as String)
    val rootDir = if (rootUri.isAbsolute) {
        File(rootUri)
    } else {
        File(packageConfig.parentFile, rootUri.path).canonicalFile
    }
    val jniLibs = File(rootDir, "android/src/main/jniLibs")
    if (!jniLibs.isDirectory) {
        throw GradleException("mssql_connection: native libraries not found at ${jniLibs.path}.")
    }
    jniLibs
}

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

    sourceSets {
        getByName("main") {
            // FreeTDS libraries used by the mssql_connection package (see above).
            jniLibs.srcDir(mssqlConnectionJniLibs)
        }
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
