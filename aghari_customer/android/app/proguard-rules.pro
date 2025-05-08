# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# قواعد دعم للاعتماديات
-dontwarn kotlinx.coroutines.flow.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.material.**
-dontwarn io.flutter.embedding.**

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Retrofit and networking
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# قواعد خاصة للكومباكت
-keep public class * extends androidx.multidex.MultiDexApplication
-keep class com.aghari.customer.AghariCustomerApplication { *; }

# قواعد عامة لتجنب الأخطاء
-keepattributes InnerClasses
-keepattributes Exceptions
-keep class ** { *; } 