package com.example.pcm_wayanad

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.pcm_wayanad/deeplink"
    private var pendingAction: String? = null
    private var pendingProjectId: String? = null
    private var channel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data = intent?.data
        if (Intent.ACTION_VIEW == action && data != null) {
            val scheme = data.scheme
            val host = data.host
            val path = data.path

            if (scheme == "app") {
                if (host == "calculator") {
                    pendingAction = "calculator"
                    sendPendingDataToFlutter()
                } else if (host == "pdf") {
                    pendingAction = "pdf"
                    val projectId = data.getQueryParameter("projectId")
                    if (projectId != null && projectId.isNotEmpty()) {
                        pendingProjectId = projectId
                    }
                    sendPendingDataToFlutter()
                }
            } else if (path != null) {
                if (path.startsWith("/project/")) {
                    val projectId = path.substring("/project/".length)
                    if (projectId.isNotEmpty()) {
                        pendingAction = "project"
                        pendingProjectId = projectId
                        sendPendingDataToFlutter()
                    }
                } else if (path.startsWith("/calculator")) {
                    pendingAction = "calculator"
                    sendPendingDataToFlutter()
                } else if (path.startsWith("/pdf")) {
                    pendingAction = "pdf"
                    val projectId = data.getQueryParameter("projectId")
                    if (projectId != null && projectId.isNotEmpty()) {
                        pendingProjectId = projectId
                    }
                    sendPendingDataToFlutter()
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "getPendingAction") {
                val resultMap = mapOf(
                    "action" to pendingAction,
                    "projectId" to pendingProjectId
                )
                result.success(resultMap)
                pendingAction = null
                pendingProjectId = null
            } else {
                result.notImplemented()
            }
        }
        sendPendingDataToFlutter()
    }

    private fun sendPendingDataToFlutter() {
        if (pendingAction != null && channel != null) {
            val dataMap = mapOf(
                "action" to pendingAction,
                "projectId" to pendingProjectId
            )
            channel?.invokeMethod("onDeepLinkReceived", dataMap)
        }
    }
}
