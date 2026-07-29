package com.vikrantruhela.datunes

import io.flutter.app.FlutterApplication
import android.content.ComponentName
import android.content.Context
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.support.v4.media.MediaMetadataCompat
import android.util.Log

class DAApplication : FlutterApplication() {
    companion object {
        var instance: DAApplication? = null
            private set
    }

    private var mediaBrowser: MediaBrowserCompat? = null
    private var mediaController: MediaControllerCompat? = null

    fun getMediaController(): MediaControllerCompat? {
        Log.d("DAApplication", "getMediaController requested. Current controller is null? = ${mediaController == null}")
        return mediaController
    }

    fun connectMediaBrowser() {
        Log.d("DAApplication", "connectMediaBrowser called. Current browser is null? = ${mediaBrowser == null}")
        try {
            if (mediaBrowser == null) {
                Log.d("DAApplication", "Creating MediaBrowserCompat instance...")
                mediaBrowser = MediaBrowserCompat(
                    this,
                    ComponentName(this, "com.ryanheise.audioservice.AudioService"),
                    connectionCallback,
                    null
                )
            }
            val isConnected = mediaBrowser?.isConnected ?: false
            Log.d("DAApplication", "MediaBrowserCompat connection state: isConnected = $isConnected")
            if (!isConnected) {
                Log.d("DAApplication", "Calling mediaBrowser.connect()...")
                mediaBrowser?.connect()
            }
        } catch (e: Exception) {
            Log.e("DAApplication", "Error in connectMediaBrowser: ${e.message}", e)
        }
    }

    private val connectionCallback = object : MediaBrowserCompat.ConnectionCallback() {
        override fun onConnected() {
            Log.d("DAApplication", "connectionCallback.onConnected() triggered!")
            try {
                val token = mediaBrowser!!.sessionToken
                Log.d("DAApplication", "Session token retrieved: $token")
                val controller = MediaControllerCompat(this@DAApplication, token)
                mediaController = controller
                Log.d("DAApplication", "MediaControllerCompat created and registered.")
                controller.registerCallback(controllerCallback)
                
                // Initial update
                Log.d("DAApplication", "Performing initial widget update from onConnected...")
                WidgetUpdater.updateWidget(
                    this@DAApplication,
                    controller.metadata,
                    controller.playbackState,
                    controller.shuffleMode,
                    controller.repeatMode
                )
            } catch (e: Exception) {
                Log.e("DAApplication", "Error in onConnected setup: ${e.message}", e)
            }
        }

        override fun onConnectionSuspended() {
            Log.w("DAApplication", "connectionCallback.onConnectionSuspended() triggered!")
            mediaController = null
            // Retry connecting in 5 seconds
            android.os.Handler(mainLooper).postDelayed({
                Log.d("DAApplication", "Retrying connection after suspension...")
                connectMediaBrowser()
            }, 5000)
        }

        override fun onConnectionFailed() {
            Log.e("DAApplication", "connectionCallback.onConnectionFailed() triggered!")
            mediaController = null
            // Retry connecting in 5 seconds
            android.os.Handler(mainLooper).postDelayed({
                Log.d("DAApplication", "Retrying connection after failure...")
                connectMediaBrowser()
            }, 5000)
        }
    }

    private val controllerCallback = object : MediaControllerCompat.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadataCompat?) {
            Log.d("DAApplication", "controllerCallback.onMetadataChanged() triggered!")
            if (metadata != null) {
                Log.d("DAApplication", "Metadata details:")
                Log.d("DAApplication", "  Title: ${metadata.getString(MediaMetadataCompat.METADATA_KEY_TITLE)}")
                Log.d("DAApplication", "  Artist: ${metadata.getString(MediaMetadataCompat.METADATA_KEY_ARTIST)}")
                Log.d("DAApplication", "  Album: ${metadata.getString(MediaMetadataCompat.METADATA_KEY_ALBUM)}")
                
                // Log all available keys and types in the bundle
                metadata.bundle?.keySet()?.forEach { key ->
                    val value = metadata.bundle.get(key)
                    val valueType = value?.javaClass?.name ?: "null"
                    Log.d("DAApplication", "    Key: $key, Type: $valueType, Value: $value")
                }
            } else {
                Log.d("DAApplication", "  Metadata is null")
            }

            WidgetUpdater.updateWidget(
                this@DAApplication,
                metadata,
                mediaController?.playbackState,
                mediaController?.shuffleMode ?: PlaybackStateCompat.SHUFFLE_MODE_NONE,
                mediaController?.repeatMode ?: PlaybackStateCompat.REPEAT_MODE_NONE
            )
        }

        override fun onPlaybackStateChanged(state: PlaybackStateCompat?) {
            Log.d("DAApplication", "controllerCallback.onPlaybackStateChanged() triggered! state = ${state?.state}, position = ${state?.position}")
            WidgetUpdater.updateWidget(
                this@DAApplication,
                mediaController?.metadata,
                state,
                mediaController?.shuffleMode ?: PlaybackStateCompat.SHUFFLE_MODE_NONE,
                mediaController?.repeatMode ?: PlaybackStateCompat.REPEAT_MODE_NONE
            )
        }

        override fun onShuffleModeChanged(shuffleMode: Int) {
            Log.d("DAApplication", "controllerCallback.onShuffleModeChanged() triggered! mode = $shuffleMode")
            WidgetUpdater.updateWidget(
                this@DAApplication,
                mediaController?.metadata,
                mediaController?.playbackState,
                shuffleMode,
                mediaController?.repeatMode ?: PlaybackStateCompat.REPEAT_MODE_NONE
            )
        }

        override fun onRepeatModeChanged(repeatMode: Int) {
            Log.d("DAApplication", "controllerCallback.onRepeatModeChanged() triggered! mode = $repeatMode")
            WidgetUpdater.updateWidget(
                this@DAApplication,
                mediaController?.metadata,
                mediaController?.playbackState,
                mediaController?.shuffleMode ?: PlaybackStateCompat.SHUFFLE_MODE_NONE,
                repeatMode
            )
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d("DAApplication", "DAApplication onCreate executed. App process spawned.")
        connectMediaBrowser()
    }
}
