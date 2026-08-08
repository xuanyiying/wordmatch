# Flutter 应用混淆规则
# 由 Flutter Gradle 插件动态合并 flutter_proguard_rules.pro，此处补充项目专属规则

# ---- sherpa_onnx / onnxruntime JNI 与模型 ----
# 保留 native 方法映射，避免 R8 移除 JNI 绑定
-keep class ai.kitt.sherpa.onnx.** { *; }
-keep class com.k2fsa.sherpa.onnx.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# ---- drift / sqlite3 ----
-keep class net.sqlcipher.** { *; }
-keep class org.sqlite.** { *; }
-keepclasseswithmembers class * {
    @androidx.annotation.Keep *;
}

# ---- in_app_purchase (Billing Library) ----
-keep class com.android.billingclient.** { *; }
-keep class com.google.android.play.core.** { *; }

# ---- Gson / json 序列化（如使用了反射的模型类）----
-keepattributes Signature, InnerClasses, EnclosingMethod, *Annotation*
-keep class com.wordmatch.wordmatch.** { *; }

# 保留测试与 Kotlin 元数据
-dontwarn org.jetbrains.annotations.**
