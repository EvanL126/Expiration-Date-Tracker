package com.example.ubeer

import android.annotation.SuppressLint
import android.Manifest
import android.content.pm.PackageManager
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanOptions
import org.json.JSONObject
import android.os.Bundle
import android.content.Intent
import android.provider.Settings
import android.print.PrintAttributes
import android.print.PrintManager
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebChromeClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.example.ubeer.ui.theme.UBeerTheme

class MainActivity : ComponentActivity() {
    private var printerView: WebView? = null
    private var posView: WebView? = null
    private var scanTarget = "cart"
    private var scanning = false
    private var pageReady = false
    private var pendingBarcode: String? = null
    private val barcodeLauncher = registerForActivityResult(ScanContract()) { result ->
        scanning = false
        result.contents?.let { barcode ->
            pendingBarcode = barcode
            deliverBarcode()
        }
    }

    private fun deliverBarcode() {
        if (!pageReady) return
        val barcode = pendingBarcode ?: return
        pendingBarcode = null
        posView?.evaluateJavascript(
            "window.onCameraBarcode(${JSONObject.quote(barcode)}, ${JSONObject.quote(scanTarget)});", null
        )
    }
    private val cameraPermission = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) launchScanner() else {
            scanning = false
            Toast.makeText(this, "Camera access was denied. You can type a barcode or enable Camera in Android app permissions.", Toast.LENGTH_LONG).show()
        }
    }

    private fun launchScanner() {
        try {
            barcodeLauncher.launch(ScanOptions().apply {
                setPrompt("Point your camera at a product barcode")
                setBeepEnabled(false)
                setBarcodeImageEnabled(false)
                setCaptureActivity(BarcodeScanActivity::class.java)
                setOrientationLocked(true)
            })
        } catch (e: Exception) {
            scanning = false
            Toast.makeText(this, "Camera scanner could not open. Please type the barcode instead.", Toast.LENGTH_LONG).show()
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        scanTarget = savedInstanceState?.getString("scanTarget") ?: "cart"
        setContent {
            UBeerTheme {
                Scaffold { padding ->
                    AndroidView(modifier = Modifier.fillMaxSize().padding(padding), factory = { context ->
                        WebView(context).apply {
                            posView = this
                            settings.javaScriptEnabled = true
                            settings.domStorageEnabled = true
                            settings.useWideViewPort = true
                            settings.loadWithOverviewMode = true
                            settings.textZoom = 100
                            settings.allowFileAccess = false
                            settings.allowContentAccess = false
                            webChromeClient = WebChromeClient()
                            webViewClient = object : WebViewClient() {
                                override fun onPageFinished(view: WebView, url: String) {
                                    pageReady = true
                                    deliverBarcode()
                                }
                                override fun shouldOverrideUrlLoading(view: WebView, request: android.webkit.WebResourceRequest): Boolean = true
                            }
                            addJavascriptInterface(PosBridge(), "NativePOS")
                            addJavascriptInterface(CloudBackup(this@MainActivity) { result ->
                                runOnUiThread {
                                    posView?.evaluateJavascript("window.CloudPOS?.receive(${result});", null)
                                }
                            }, "FirebasePOS")
                            loadUrl("file:///android_asset/pos/index.html")
                        }
                    })
                }
            }
        }
    }

    inner class PosBridge {
        @JavascriptInterface fun scanBarcode(target: String) {
            runOnUiThread {
                if (scanning) return@runOnUiThread
                scanTarget = if (target == "product") "product" else "cart"
                if (!packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)) {
                    Toast.makeText(this@MainActivity, "No camera available. Please type the barcode instead.", Toast.LENGTH_LONG).show()
                    return@runOnUiThread
                }
                scanning = true
                if (ContextCompat.checkSelfPermission(this@MainActivity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                    launchScanner()
                } else {
                    cameraPermission.launch(Manifest.permission.CAMERA)
                }
            }
        }
        @JavascriptInterface fun load(): String = getSharedPreferences("pos", MODE_PRIVATE).getString("data", "") ?: ""
        @JavascriptInterface fun save(json: String): Boolean = getSharedPreferences("pos", MODE_PRIVATE).edit().putString("data", json).commit()
        @JavascriptInterface fun saveRecovery(json: String): Boolean = getSharedPreferences("pos", MODE_PRIVATE).edit().putString("before_cloud_restore", json).commit()
        @JavascriptInterface fun loadRecovery(): String = getSharedPreferences("pos", MODE_PRIVATE).getString("before_cloud_restore", "") ?: ""
        @JavascriptInterface fun devices() { runOnUiThread { startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS)) } }
        @JavascriptInterface fun printers() { runOnUiThread { startActivity(Intent(Settings.ACTION_PRINT_SETTINGS)) } }
        @JavascriptInterface fun printInvoice(html: String, name: String) {
            runOnUiThread {
                printerView?.destroy()
                printerView = WebView(this@MainActivity).apply {
                    webViewClient = object : WebViewClient() {
                        override fun onPageFinished(view: WebView, url: String) {
                            val manager = getSystemService(PRINT_SERVICE) as PrintManager
                            manager.print(name, view.createPrintDocumentAdapter(name), PrintAttributes.Builder().build())
                        }
                    }
                    loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
                }
            }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putString("scanTarget", scanTarget)
        super.onSaveInstanceState(outState)
    }

    override fun onDestroy() {
        posView?.removeJavascriptInterface("NativePOS")
        posView?.removeJavascriptInterface("FirebasePOS")
        posView?.destroy()
        printerView?.destroy()
        super.onDestroy()
    }
}
