import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Lit google-services.json (projet Firebase « notifquizz »).
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de publication décrite dans android/key.properties (hors dépôt, voir
// docs/developpement.md). Sans ce fichier, la release reste signée avec la
// clé de debug : installable en local, mais refusée par le Play Store.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

val releaseSigningProperties =
    listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val hasReleaseSigning = keystorePropertiesFile.exists() &&
    releaseSigningProperties.all { !keystoreProperties.getProperty(it).isNullOrBlank() }

// Refuse toute tache release sans cle de publication. Cela evite de produire
// accidentellement un artefact non signe ou signe avec la cle de debug.
gradle.taskGraph.whenReady {
    val requestsRelease = allTasks.any { task ->
        task.path.contains("Release", ignoreCase = true)
    }
    if (requestsRelease && !hasReleaseSigning) {
        throw GradleException(
            "Build release refuse : android/key.properties est absent ou incomplet. " +
                "Proprietes requises : ${releaseSigningProperties.joinToString()}.",
        )
    }
}

android {
    namespace = "net.studiobeyam.ivoirequiz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Exigé par flutter_local_notifications (notifications au premier plan).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Identifiant définitif sur le Play Store : ne plus jamais le changer.
        applicationId = "net.studiobeyam.ivoirequiz"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
