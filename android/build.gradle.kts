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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Isar 3.1.0+1 predates mandatory Android Gradle Plugin namespaces.
// Its library plugin is not yet applied when root subprojects are first
// configured. Register a plugin callback instead of checking too early.
// This does NOT modify Isar's pub-cache sources or any application schema.
subprojects {
    if (project.name == "isar_flutter_libs") {
        project.pluginManager.withPlugin("com.android.library") {
            val androidExtension = project.extensions.findByName("android")
                ?: error("Isar Android plugin missing its android extension")
            val getter = androidExtension.javaClass.getMethod("getNamespace")
            val setter = androidExtension.javaClass.getMethod(
                "setNamespace", String::class.java)
            if (getter.invoke(androidExtension) == null) {
                setter.invoke(androidExtension, "io.isar.isar_flutter_libs")
            }
        }
    }
}
