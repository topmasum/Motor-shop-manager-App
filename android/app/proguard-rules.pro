# Protect Flutter Plugins and Channels from being deleted
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.plugin.common.MethodChannel$* { *; }
-keep class io.flutter.plugins.** { *; }

# Protect Firebase and Pigeon interfaces
-keep class com.google.firebase.** { *; }
-keep class dev.flutter.pigeon.** { *; }