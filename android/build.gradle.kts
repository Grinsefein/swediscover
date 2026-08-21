allprojects {
    repositories {
        google()
        mavenCentral()
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

// Workaround für Plugins, die Kotlin nur anhand der AGP-Hauptversion anwenden
// (z. B. maplibre_gl 0.27): Mit AGP 9 + `android.builtInKotlin=false` (Flutter-3.44-Default)
// wird dort weder KGP angewendet noch die `kotlin`-Extension registriert →
// `Could not find method kotlin()`. Wir wenden KGP für alle Library-Module an,
// die es nicht selbst tun, solange built-in Kotlin aus ist.
subprojects {
    plugins.withId("com.android.library") {
        if (!plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            val builtInKotlin = findProperty("android.builtInKotlin")?.toString() == "true"
            if (!builtInKotlin) {
                apply(plugin = "org.jetbrains.kotlin.android")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
