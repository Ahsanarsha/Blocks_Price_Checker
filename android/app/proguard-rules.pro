# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep mssql_connection plugin
-keep class com.example.mssql_connection.** { *; }

# Keep jTDS JDBC driver classes
-keep class net.sourceforge.jtds.** { *; }

# Suppress warnings for jcifs (SMB/CIFS) - not used on Android
-dontwarn jcifs.**

# Suppress warnings for JGSS (Kerberos authentication) - not used on Android
-dontwarn org.ietf.jgss.**

# Suppress warnings for javax.naming (JNDI) - not used on Android
-dontwarn javax.naming.**

# Suppress warnings for javax.sql.XA (XA transactions) - not used on Android
-dontwarn javax.sql.XAConnection
-dontwarn javax.sql.XADataSource

# Suppress warnings for javax.transaction.xa (XA transactions) - not used on Android
-dontwarn javax.transaction.xa.**

# Suppress warnings for Google Play Core (deferred components) - not used
-dontwarn com.google.android.play.core.**

# Keep JDBC classes
-keep class java.sql.** { *; }
-keep class javax.sql.** { *; }

# Keep shared_preferences
-keep class androidx.datastore.** { *; }
