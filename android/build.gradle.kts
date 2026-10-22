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

subprojects {
    // Mantemos a lógica para agir na configuração
    val androidExtension = project.extensions.findByName("android")
    if (androidExtension != null) {
        try {
            val namespaceMethod = androidExtension.javaClass.getMethod("getNamespace")
            val setNamespaceMethod = androidExtension.javaClass.getMethod("setNamespace", String::class.java)

            val currentNamespace = namespaceMethod.invoke(androidExtension)
            
            if (currentNamespace == null) {
                // Caso específico para o Isar que costuma travar
                val namespaceToSet = if (project.name.contains("isar")) {
                    "io.isar.isar_flutter_libs" 
                } else {
                    project.group.toString()
                }
                
                setNamespaceMethod.invoke(androidExtension, namespaceToSet)
            }
        } catch (e: Exception) {
            // Silencia erros de reflection
        }
    }
}
