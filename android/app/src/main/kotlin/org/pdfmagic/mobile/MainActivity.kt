package org.pdfmagic.mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import com.fluttercavalry.open_file_handler.OpenFileHandlerPlugin
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handlePdfIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handlePdfIntent(intent)
    }

    private fun handlePdfIntent(intent: Intent) {
        if (
            intent.action != Intent.ACTION_VIEW &&
            intent.action != Intent.ACTION_EDIT &&
            intent.action != Intent.ACTION_SEND
        ) {
            return
        }

        val uri = intent.data ?: streamUri(intent) ?: return
        OpenFileHandlerPlugin.handleOpenURIs(
            listOf(uri),
            true,
            intent.action != Intent.ACTION_SEND,
        )
    }

    private fun streamUri(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }
}
