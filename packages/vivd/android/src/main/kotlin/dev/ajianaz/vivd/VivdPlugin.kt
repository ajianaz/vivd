package dev.ajianaz.vivd

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin

/** VivdPlugin */
class VivdPlugin : FlutterPlugin {
    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // Plugin attached — pure Dart for now, no native channel needed yet.
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // Plugin detached.
    }
}
