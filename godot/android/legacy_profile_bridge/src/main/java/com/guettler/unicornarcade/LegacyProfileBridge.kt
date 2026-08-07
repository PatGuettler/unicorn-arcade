package com.guettler.unicornarcade

import android.annotation.SuppressLint
import android.util.Base64
import android.webkit.WebView
import android.webkit.WebViewClient
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/** Read-only migration bridge. Keep this source in the custom Android template. */
class LegacyProfileBridge(godot: Godot) : GodotPlugin(godot) {
    override fun getPluginName() = "LegacyProfileBridge"
    override fun getPluginSignals() = setOf(SignalInfo("legacy_json", String::class.java))

    @UsedByGodot
    @SuppressLint("SetJavaScriptEnabled")
    fun read_legacy_json() {
        val host = activity ?: run {
            emitSignal("legacy_json", "")
            return
        }
        host.runOnUiThread {
            val view = WebView(host)
            view.settings.javaScriptEnabled = true
            view.settings.domStorageEnabled = true
            view.webViewClient = object : WebViewClient() {
                override fun onPageFinished(webView: WebView, url: String) {
                    webView.evaluateJavascript("btoa(unescape(encodeURIComponent(localStorage.getItem('unicorn_arcade_v1') || '')))") { value ->
                        val encoded = value.removeSurrounding("\"")
                        val result = try {
                            String(Base64.decode(encoded, Base64.DEFAULT), Charsets.UTF_8)
                        } catch (_: IllegalArgumentException) { "" }
                        emitSignal("legacy_json", result)
                        webView.destroy()
                    }
                }
            }
            view.loadDataWithBaseURL("https://localhost/", "<html></html>", "text/html", "utf-8", null)
        }
    }
}
