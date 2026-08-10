import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("keystore.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// keystore.properties 被 .gitignore 排除，新环境克隆后不存在。
// 缺失时以环境变量兜底（推荐 CI secrets 注入），并给出清晰错误提示。
fun resolveSecret(key: String): String? {
    val fromFile = keystoreProperties[key] as String?
    if (!fromFile.isNullOrEmpty()) return fromFile
    return System.getenv("WORLDMATCH_" + key.uppercase())
}

android {
    namespace = "com.wordmatch.wordmatch"
    compileSdk = 36
    ndkVersion = "28.0.12916984"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications 的 zonedSchedule 依赖 java.time，
        // 需启用 core library desugaring（含时间 API 的向后兼容）。
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.wordmatch.wordmatch"
        minSdk = 24
        targetSdk = 34
        // versionCode / versionName 由 Flutter Gradle 插件从 pubspec.yaml 自动注入，
        // 无需在此硬编码。如需修改版本，请编辑 ../pubspec.yaml。
    }

    // 仅保留 arm64-v8a 架构的 native 库。
    // sherpa_onnx 为每个 ABI 各打包一份 onnxruntime.so（arm64 21MB + armeabi 14MB + x86_64 24MB），
    // ndk.abiFilters 对 Flutter 插件 .so 不生效，必须用 packaging.jniLibs.excludes 直接排除。
    // 现代手机（含目标小米）均为 arm64，可安全排除旧架构。
    packaging {
        jniLibs {
            excludes += setOf(
                "lib/armeabi-v7a/**",
                "lib/x86/**",
                "lib/x86_64/**",
            )
        }
    }

    signingConfigs {
        create("release") {
            val storeFileProp = resolveSecret("storeFile")
            val storePasswordProp = resolveSecret("storePassword")
            val keyAliasProp = resolveSecret("keyAlias")
            val keyPasswordProp = resolveSecret("keyPassword")
            if (storeFileProp == null || storePasswordProp == null ||
                keyAliasProp == null || keyPasswordProp == null
            ) {
                throw GradleException(
                    "缺失 release 签名配置：请在 android/keystore.properties 中配置 " +
                        "storeFile/storePassword/keyAlias/keyPassword，或通过环境变量 " +
                        "WORLDMATCH_STOREFILE/WORLDMATCH_STOREPASSWORD/WORLDMATCH_KEYALIAS/WORLDMATCH_KEYPASSWORD 注入。"
                )
            }
            storeFile = file(storeFileProp)
            storePassword = storePasswordProp
            keyAlias = keyAliasProp
            keyPassword = keyPasswordProp
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // 开启 R8 混淆与资源收缩，降低反编译风险
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // core library desugaring：支持 java.time 等 API 在低版本 Android 运行
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
