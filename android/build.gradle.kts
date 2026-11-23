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

rootProject.extra["compileSdkVersion"] = 36
rootProject.extra["targetSdkVersion"] = 36

subprojects {
    if (project.name != "app") {
        val configureCompileSdk: (Project) -> Unit = { p ->
            p.extensions.findByName("android")?.let { ext ->
                val method = ext.javaClass.methods.firstOrNull { 
                    (it.name == "compileSdkVersion" || it.name == "setCompileSdk") && 
                    it.parameterCount == 1 && 
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == java.lang.Integer::class.java)
                }
                method?.invoke(ext, 36)
            }
        }
        if (state.executed) {
            configureCompileSdk(project)
        } else {
            afterEvaluate {
                configureCompileSdk(project)
            }
        }
    }
}

subprojects {
    tasks.configureEach {
        if (name.contains("verify") && name.contains("Resources")) {
            enabled = false
        }
        if (name.contains("AarMetadata")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
