package com.relay.relay_translate.ui

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface

/** Mirror of `app/lib/theme/tokens.dart` for native overlay views. Keep the values identical. */
object RelayColors {
    val bg = Color.parseColor("#F2F2F3")
    val surface = Color.parseColor("#E9E9EA")
    val text = Color.parseColor("#1D1F20")
    val accent = Color.parseColor("#5980A6")
    val accent300 = Color.parseColor("#B5D9FD")
    val accent700 = Color.parseColor("#416180")
    val divider = Color.parseColor("#291D1F20") // text @ 16%
    val mark = Color.parseColor("#8C1D1F20") // text @ 55%, Blueprint corner marks
    val neutral100 = Color.parseColor("#F5F5F8")
    val neutral600 = Color.parseColor("#7A7A7D")
    val neutral700 = Color.parseColor("#5D5D60")
    val neutral900 = Color.parseColor("#2B2B2D")
    val scrim = Color.parseColor("#732B2B2D")
    val shadowMd = Color.parseColor("#292B2B2D") // RelayShadows.md
}

/** Mirror of `RelayFonts` in tokens.dart. Loads the Barlow files Flutter already bundles. */
object RelayFonts {
    private val cache = mutableMapOf<String, Typeface>()

    fun body(context: Context): Typeface = load(context, "Barlow-Regular.ttf")
    fun headingSemiBold(context: Context): Typeface = load(context, "BarlowCondensed-SemiBold.ttf")

    private fun load(context: Context, file: String): Typeface = cache.getOrPut(file) {
        try {
            Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/$file")
        } catch (_: RuntimeException) {
            Typeface.DEFAULT
        }
    }
}
