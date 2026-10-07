import java.util.Properties

// Signature de release : lue dans android/key.properties (NON commité, voir docs/PLAY_STORE_RELEASE.md).
val keystoreProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val hasReleaseKey = keystoreProps.getProperty("storeFile") != null

// Un AAB destiné au Play Store ne doit JAMAIS être signé avec la clé de debug : on refuse de le construire
// tant que key.properties (storeFile, storePassword, keyAlias, keyPassword) n'est pas complet.
gradle.taskGraph.whenReady {
    if (hasTask(":app:bundleRelease")) {
        val missing = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
            .filter { keystoreProps.getProperty(it).isNullOrBlank() }
        if (missing.isNotEmpty()) {
            throw GradleException(
                "AAB release refusé : android/key.properties incomplet (manquant : ${missing.joinToString()}). " +
                    "Voir docs/PLAY_STORE_RELEASE.md."
            )
        }
    }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nalvium.nalvium"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nalvium.nalvium"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        // ID d'application AdMob : TEST pour debug/profile, PRODUCTION uniquement pour release.
        debug {
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        }
        getByName("profile") {
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        }
        release {
            manifestPlaceholders["admobAppId"] = "ca-app-pub-9787163762873138~8283818658"
            // Sans key.properties : signature de DEBUG (test local uniquement, REFUSÉE par le Play Store).
            signingConfig = if (hasReleaseKey) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
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
