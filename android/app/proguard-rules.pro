# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# SQL Server access is handled by the mssql_connection package via Dart FFI +
# FreeTDS native libraries (no Java/Kotlin classes), so no keep rules are needed.

# Suppress warnings for Google Play Core (deferred components) - not used
-dontwarn com.google.android.play.core.**

# Keep shared_preferences
-keep class androidx.datastore.** { *; }
