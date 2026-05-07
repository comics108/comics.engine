package net.nativemind.comics.flutter_comics

import android.content.Context
import android.view.View
import android.view.GestureDetector
import android.view.MotionEvent
import android.widget.FrameLayout
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import net.nativemind.comics.flutter_comics.controls.ZoomFrameLayout
import net.nativemind.comics.flutter_comics.controls.LayersView
import net.nativemind.comics.flutter_comics.model.visual.Comics
import org.json.JSONObject
import java.io.File
import java.util.zip.ZipFile

class ComicsPlatformView(
    private val context: Context,
    private val viewId: Int,
    messenger: BinaryMessenger,
    private val creationParams: Map<String, Any?>
) : PlatformView, MethodChannel.MethodCallHandler {

    private val channel: MethodChannel = MethodChannel(messenger, "flutter_comics_$viewId")
    private val zoomLayout: ZoomFrameLayout
    private var layersView: LayersView? = null
    private var comics: Comics? = null
    private var archivePath: String? = null

    init {
        channel.setMethodCallHandler(this)

        zoomLayout = ZoomFrameLayout(context)
        zoomLayout.setZoomEnabled(creationParams["zoomEnabled"] as? Boolean ?: false)

        // Set scroll listener
        zoomLayout.setScrollListener(object : ZoomFrameLayout.OnScrollListener {
            override fun onScroll(
                contentWidth: Int,
                contentHeight: Int,
                scrollX: Int,
                scrollY: Int,
                extendedX: Int,
                extendedY: Int
            ) {
                comics?.process(scrollY)
                channel.invokeMethod("onScrollChanged", mapOf(
                    "offset" to scrollY,
                    "maxOffset" to (contentHeight - extendedY).coerceAtLeast(0)
                ))
            }
        })

        // Set gesture listener for tap/long-press
        zoomLayout.setGestureListener(object : GestureDetector.SimpleOnGestureListener() {
            override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                handleTap(e.x, e.y, false)
                return true
            }

            override fun onLongPress(e: MotionEvent) {
                handleTap(e.x, e.y, true)
            }
        })

        // Load scene if archivePath is provided
        val path = creationParams["archivePath"] as? String
        if (!path.isNullOrEmpty()) {
            loadScene(
                path,
                creationParams["languageIndex"] as? Int ?: 0,
                creationParams["soundEnabled"] as? Boolean ?: true
            )
        }
    }

    override fun getView(): View = zoomLayout

    override fun dispose() {
        channel.setMethodCallHandler(null)
        comics?.release()
        comics = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setScrollOffset" -> {
                val offset = call.argument<Int>("offset") ?: 0
                // TODO: Implement programmatic scroll
                result.success(null)
            }
            "getScrollOffset" -> {
                result.success(zoomLayout.getCurrentScrollY())
            }
            "setLanguageIndex" -> {
                val index = call.argument<Int>("index") ?: 0
                comics?.setLanguageIndex(index)
                result.success(null)
            }
            "setSoundEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                comics?.setSoundOn(enabled)
                result.success(null)
            }
            "pauseSounds" -> {
                comics?.pauseSounds()
                result.success(null)
            }
            "resumeSounds" -> {
                comics?.resumeSounds()
                result.success(null)
            }
            "hitTest" -> {
                val x = (call.argument<Double>("x") ?: 0.0).toFloat()
                val y = (call.argument<Double>("y") ?: 0.0).toFloat()
                val hitResult = performHitTest(x, y)
                result.success(hitResult)
            }
            else -> result.notImplemented()
        }
    }

    private fun loadScene(path: String, languageIndex: Int, soundEnabled: Boolean) {
        archivePath = path

        try {
            // Parse data.json from archive
            val file = File(path)
            if (!file.exists()) {
                channel.invokeMethod("onError", "Archive not found: $path")
                return
            }

            val zipFile = ZipFile(file)
            val dataEntry = zipFile.getEntry("data.json")
            if (dataEntry == null) {
                channel.invokeMethod("onError", "data.json not found in archive")
                zipFile.close()
                return
            }

            val jsonString = zipFile.getInputStream(dataEntry).bufferedReader().use { it.readText() }
            zipFile.close()

            // Parse JSON to Comics
            comics = parseComics(jsonString)
            comics?.prepare(context, path, languageIndex)
            comics?.setSoundOn(soundEnabled)

            // Setup view
            comics?.let { c ->
                zoomLayout.setContentSize(c.width, c.height)

                layersView = LayersView(context, c)
                zoomLayout.addView(layersView, FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                ))

                // Notify Flutter
                channel.invokeMethod("onSceneLoaded", mapOf(
                    "width" to c.width,
                    "height" to c.height,
                    "layerCount" to c.layers.size,
                    "hasSound" to (c.sounds?.isNotEmpty() ?: false)
                ))
            }
        } catch (e: Exception) {
            channel.invokeMethod("onError", e.message ?: "Unknown error")
        }
    }

    private fun parseComics(jsonString: String): Comics {
        // TODO: Implement proper JSON parsing with Gson or manual parsing
        // For now, create a minimal Comics object
        val json = JSONObject(jsonString)
        val comics = Comics()

        // Use reflection or manual parsing to populate Comics
        // This is a simplified placeholder
        try {
            val widthField = Comics::class.java.getDeclaredField("width")
            widthField.isAccessible = true
            widthField.setInt(comics, json.optInt("width", 1080))

            val heightField = Comics::class.java.getDeclaredField("height")
            heightField.isAccessible = true
            heightField.setInt(comics, json.optInt("height", 1920))

            // TODO: Parse layers and sounds arrays
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return comics
    }

    private fun handleTap(x: Float, y: Float, isLongPress: Boolean) {
        val hitResult = performHitTest(x, y)
        if (hitResult != null && hitResult["isHit"] == true) {
            val eventName = if (isLongPress) "onLayerLongPress" else "onLayerTap"
            channel.invokeMethod(eventName, hitResult)
        }
    }

    private fun performHitTest(x: Float, y: Float): Map<String, Any?>? {
        // TODO: Implement proper hit testing through LayersView
        layersView?.let { lv ->
            val comics = this.comics ?: return null
            for ((index, layer) in comics.layers.withIndex().reversed()) {
                // Check if point hits this layer
                // This requires implementing hit test in LayersView/TileImageView
            }
        }
        return null
    }
}
