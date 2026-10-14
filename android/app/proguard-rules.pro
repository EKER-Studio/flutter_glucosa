# R8 Full Mode Optimizations & Class Repackaging for Google Play
-repackageclasses ''
-allowaccessmodification

# App widget providers declared in AndroidManifest — R8 must not rename or remove them
-keep class com.ekerstudio.glucosa.GlucosaAppWidgetProvider { *; }
-keep class com.ekerstudio.glucosa.GlucosaFullAppWidgetProvider { *; }

# Flutter Local Notifications Plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Flutter engine / platform channels (minimal rules)
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepclassmembers class * implements android.os.IInterface {
    public static ** DEFAULT;
}

# Play Store Split Install (optional, used by Flutter for deferred components)
-dontwarn com.google.android.play.core.**

# Stack trace preservation for on-device diagnostics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Isar Community Database (JNI and generated bindings)
-keep class dev.isar.** { *; }
-dontwarn dev.isar.**
-keep class io.isar.** { *; }
-dontwarn io.isar.**
