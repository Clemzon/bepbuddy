package com.madlabz.bepbuddy

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class InvoiceCreationActivity : FlutterActivity() {

  override fun onCreate(savedInstanceState: Bundle?) {
    // ——— Convert "Open with / VIEW" into "Share with / SEND" so share_handler sees EXTRA_STREAM ———
    if (intent?.action == Intent.ACTION_VIEW) {
      intent.data?.let { uri ->
        intent.action = Intent.ACTION_SEND
        intent.putExtra(Intent.EXTRA_STREAM, uri)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
      }
    }
    super.onCreate(savedInstanceState)
  }

  override fun onNewIntent(newIntent: Intent) {
    // ——— Also handle VIEW→SEND if the activity is already alive ———
    if (newIntent.action == Intent.ACTION_VIEW) {
      newIntent.data?.let { uri ->
        newIntent.action = Intent.ACTION_SEND
        newIntent.putExtra(Intent.EXTRA_STREAM, uri)
        newIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
      }
    }
    super.onNewIntent(newIntent)
    setIntent(newIntent)
  }

  override fun getInitialRoute(): String {
    // Force Flutter to start at your invoice_creation screen
    return "/invoice_creation"
  }
}