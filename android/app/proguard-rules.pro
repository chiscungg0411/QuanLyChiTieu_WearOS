# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep SharedPreferences
-keep class androidx.datastore.** { *; }

# Prevent obfuscation of types which use @GeneratedValue for SharedPreferences
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Kotlin classes
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# General Android optimizations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
