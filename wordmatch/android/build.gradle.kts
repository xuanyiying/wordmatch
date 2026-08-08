val flutterSdkPath =
    run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        properties.getProperty("flutter.sdk") ?: ""
    }

buildscript {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
    }
}

allprojects {
    repositories {
        // Flutter 引擎组件镜像（清华）
        maven { url = uri("https://mirrors.tuna.tsinghua.edu.cn/flutter/download.flutter.io") }
        maven { url = uri("https://storage.flutter-io.cn/download.flutter.io") }
        // Flutter Tools maven_repo
        maven { url = uri("$flutterSdkPath/packages/flutter_tools/gradle/maven_repo") }
        // 阿里云镜像
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.application") {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            ndkVersion = "28.0.12916984"
        }
    }
    plugins.withId("com.android.library") {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            ndkVersion = "28.0.12916984"
        }
    }
}

// 强制所有 library 子项目在脚本求值后使用 compileSdk 36。
// sherpa_onnx 等插件在自身 build.gradle 中显式设置 compileSdk = 34，
// 必须用 gradle.afterProject 在其之后覆盖（afterEvaluate 因 evaluationDependsOn
// 会在项目已求值时注册而报错，afterProject 是全局钩子不受此限制）。
gradle.afterProject {
    if (plugins.hasPlugin("com.android.library")) {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
            compileSdk = 36
        }
    }
}

// Force all subprojects to use local NDK.
gradle.beforeProject {
    extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.ndkVersion = "28.0.12916984"
}

// Force Kotlin version to 2.2.20 globally (flutter_tts requires it, Flutter SDK defaults to 2.0.0)
subprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.2.20")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}